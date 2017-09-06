import MySQL
import LoggerAPI

// MARK: - FriendMySQLDataAccessorProtocol

public protocol FriendMySQLDataAccessorProtocol {
    func getFriends(withUserID id: String, pageSize: Int, pageNumber: Int) throws -> [Friend]?
    func getInvites(forUserID id: String, pageSize: Int, pageNumber: Int, type: InviteType) throws -> [Invite]?
    func createInvites(forUserID userID: String, inviteUserIDs: [String]) throws -> Bool
    func deleteFriends(friendIDs: [String]) throws -> Bool
}

// MARK: - FriendMySQLDataAccessor: FriendMySQLDataAccessorProtocol

public class FriendMySQLDataAccessor: FriendMySQLDataAccessorProtocol {

    // MARK: Properties

    let pool: MySQLConnectionPoolProtocol

    // MARK: Initializer

    public init(pool: MySQLConnectionPoolProtocol) {
        self.pool = pool
    }

    // MARK: READ

    public func getFriends(withUserID id: String, pageSize: Int = 10, pageNumber: Int = 1) throws -> [Friend]? {
        let selectQuery = MySQLQueryBuilder()
            .select(fields: ["friend_id", "user_id_1", "user_id_2"], table: "friends")
            .wheres(statement: "user_id_1=? OR user_id_2=?", parameters: id, id)

        let result = try execute(builder: selectQuery)
        result.seek(offset: cacluateOffset(pageSize: pageSize, pageNumber: pageNumber))

        let friends = result.toFriends(pageSize: pageSize)
        return (friends.count == 0) ? nil : friends
    }

    public func getInvites(forUserID id: String, pageSize: Int = 10, pageNumber: Int = 1, type: InviteType) throws -> [Invite]? {
        // Use schedule type to create proper query
        var selectInvites = MySQLQueryBuilder()
            .select(fields: ["invite_id", "inviter_id", "invitee_id"], table: "friend_invites")
        switch type {
        case .inviter:
            selectInvites = selectInvites.wheres(statement: "inviter_id=?", parameters: id)
        case .invitee:
            selectInvites = selectInvites.wheres(statement: "invitee_id=?", parameters: id)
        case .all:
            selectInvites = selectInvites.wheres(statement: "invitee_id=? OR inviter_id=?", parameters: id, id)
        }

        let result = try execute(builder: selectInvites)
        result.seek(offset: cacluateOffset(pageSize: pageSize, pageNumber: pageNumber))

        let invites = result.toInvites(pageSize: pageSize)
        return (invites.count == 0) ? nil : invites
    }

    // MARK: CREATE

    public func createInvites(forUserID userID: String, inviteUserIDs: [String]) throws -> Bool {
        var result: MySQLResultProtocol
        var totalAffectedRows = 0

        guard let connection = try pool.getConnection() else {
            Log.error("Could not get a connection")
            return false
        }
        defer { pool.releaseConnection(connection) }

        func rollbackEventTransaction(withConnection: MySQLConnectionProtocol, message: String) -> Bool {
            Log.error("Could not create friend invites: \(message)")
            try! connection.rollbackTransaction()
            return false
        }

        connection.startTransaction()

        do {
            for inviteUserID in inviteUserIDs {

                // Check if friend already exists
                let checkFriendQuery = MySQLQueryBuilder()
                    .select(fields: ["friend_id"], table: "friends")
                    .wheres(statement: "(user_id_1=? AND user_id_2=?) OR (user_id_1=? AND user_id_2=?)", parameters: userID, inviteUserID, inviteUserID, userID)
                result = try connection.execute(builder: checkFriendQuery)
                guard result.nextResult() == nil else {
                    return rollbackEventTransaction(withConnection: connection, message: "User \(userID) is already a friend with user \(inviteUserID).")
                }

                // Check if invite already exists
                let checkInviteQuery = MySQLQueryBuilder()
                    .select(fields: ["inviter_id"], table: "friend_invites")
                    .wheres(statement: "inviter_id=? AND invitee_id=?", parameters: userID, inviteUserID)
                result = try connection.execute(builder: checkInviteQuery)
                guard result.nextResult() == nil else {
                    return rollbackEventTransaction(withConnection: connection, message: "User \(userID) has already invited user \(inviteUserID) to become friends.")
                }

                // Insert (create) invite
                let insertInviteQuery = MySQLQueryBuilder()
                    .insert(data: ["inviter_id": userID, "invitee_id": inviteUserID], table: "friend_invites")
                result = try connection.execute(builder: insertInviteQuery)                
                if result.affectedRows < 1 {
                    return rollbackEventTransaction(withConnection: connection, message: "Failed to invite user \(inviteUserID) to become a friend of \(userID)")
                }
            }

            try connection.commitTransaction()

        } catch {
            return rollbackEventTransaction(withConnection: connection, message: "createInvites failed")
        }

        return true
    }

    // MARK: DELETE

    public func deleteFriends(friendIDs: [String]) throws -> Bool {
        var result: MySQLResultProtocol
        var totalAffectedRows = 0

        guard let connection = try pool.getConnection() else {
            Log.error("Could not get a connection")
            return false
        }
        defer { pool.releaseConnection(connection) }

        func rollbackEventTransaction(withConnection: MySQLConnectionProtocol, message: String) -> Bool {
            Log.error("Could not delete friends: \(message)")
            try! connection.rollbackTransaction()
            return false
        }

        connection.startTransaction()

        do {
            for friendID in friendIDs {
                // FIXME: Only delete friends where a user matches JWT user
                let deleteFriendQuery = MySQLQueryBuilder()
                    .delete(fromTable: "friends")
                    .wheres(statement: "friend_id=?", parameters: "\(friendID)")
                result = try connection.execute(builder: deleteFriendQuery)

                if result.affectedRows > 0 {
                    totalAffectedRows += 1
                }
            }

            try connection.commitTransaction()

        } catch {
            return rollbackEventTransaction(withConnection: connection, message: "deleteFriendsForUserID failed")
        }

        return totalAffectedRows > 0
    }

    // MARK: Utility

    func execute(builder: MySQLQueryBuilder) throws -> MySQLResultProtocol {
        let connection = try pool.getConnection()
        defer { pool.releaseConnection(connection!) }

        return try connection!.execute(builder: builder)
    }

    func cacluateOffset(pageSize: Int, pageNumber: Int) -> Int64 {
        return Int64(pageNumber > 1 ? pageSize * (pageNumber - 1) : 0)
    }

    public func isConnected() -> Bool {
        do {
            let connection = try pool.getConnection()
            defer { pool.releaseConnection(connection!) }
        } catch {
            return false
        }
        return true
    }
}
