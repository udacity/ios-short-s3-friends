import MySQL
import LoggerAPI

// MARK: - FriendMySQLDataAccessorProtocol

public protocol FriendMySQLDataAccessorProtocol {
    func getFriends(withUserID id: String, pageSize: Int, pageNumber: Int) throws -> [Friend]?
}

// MARK: - FriendMySQLDataAccessor: FriendMySQLDataAccessorProtocol

public class FriendMySQLDataAccessor: FriendMySQLDataAccessorProtocol {

    // MARK: Properties

    let pool: MySQLConnectionPoolProtocol

    // MARK: Initializer

    public init(pool: MySQLConnectionPoolProtocol) {
        self.pool = pool
    }

    // MARK: Queries

    public func getFriends(withUserID id: String, pageSize: Int = 10, pageNumber: Int = 1) throws -> [Friend]? {
        let selectQuery = MySQLQueryBuilder()
            .select(fields: ["friend_id", "current_user_id", "friend_user_id"], table: "friends")
            .wheres(statement: "current_user_id=?", parameters: id)
        
        let result = try execute(builder: selectQuery)
        result.seek(offset: cacluateOffset(pageSize: pageSize, pageNumber: pageNumber))

        let friends = result.toFriends(pageSize: pageSize)
        return (friends.count == 0) ? nil : friends
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
