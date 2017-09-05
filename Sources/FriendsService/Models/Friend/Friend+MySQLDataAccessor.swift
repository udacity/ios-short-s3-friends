import MySQL
import LoggerAPI

// MARK: - FriendMySQLDataAccessorProtocol

public protocol FriendMySQLDataAccessorProtocol {
    func getFriends(withUserID id: String, pageSize: Int, pageNumber: Int) throws -> [Friend]?
    func getInvites(forUserID id: String, pageSize: Int, pageNumber: Int, type: InviteType) throws -> [Invite]?
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
