import MySQL

// MARK: - FriendMySQLDataAccessorProtocol

public protocol FriendMySQLDataAccessorProtocol {
    func getFriends(withID id: String) throws -> [Friend]?
    func getFriends() throws -> [Friend]?
}

// MARK: - FriendMySQLDataAccessor: FriendMySQLDataAccessorProtocol

public class FriendMySQLDataAccessor: FriendMySQLDataAccessorProtocol {

    // MARK: Properties

    let pool: MySQLConnectionPoolProtocol

    let selectFriends = MySQLQueryBuilder()
            .select(fields: ["id", "user_id_1", "user_id_2",
            "accepted", "created_at", "updated_at"], table: "friends")

    // MARK: Initializer

    public init(pool: MySQLConnectionPoolProtocol) {
        self.pool = pool
    }

    // MARK: Queries

    public func getFriends(withID id: String) throws -> [Friend]? {
        let query = "SELECT * " +
                    "FROM friends " +
                    "WHERE id=\(id)"
        let result = try execute(query: query)
        let friends = result.toFriends()
        return (friends.count == 0) ? nil : friends
    }

    public func getFriends() throws -> [Friend]? {
        let result = try execute(builder: selectFriends)
        let friends = result.toFriends()
        return (friends.count == 0) ? nil : friends
    }

    // MARK: Utility

    func execute(builder: MySQLQueryBuilder) throws -> MySQLResultProtocol {
        let connection = try pool.getConnection()
        defer { pool.releaseConnection(connection!) }

        return try connection!.execute(builder: builder)
    }

    func execute(query: String) throws -> MySQLResultProtocol {
        let connection = try pool.getConnection()
        defer { pool.releaseConnection(connection!) }

        return try connection!.execute(query: query)
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
