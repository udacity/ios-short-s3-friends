import MySQL
import Kitura
import LoggerAPI
import Foundation
import SwiftyJSON

// MARK: - Handlers

public class Handlers {

    // MARK: Properties

    let dataAccessor: FriendMySQLDataAccessorProtocol

    // MARK: Initializer

    public init(dataAccessor: FriendMySQLDataAccessorProtocol) {
        self.dataAccessor = dataAccessor
    }

    // MARK: OPTIONS

    public func getOptions(request: RouterRequest, response: RouterResponse, next: () -> Void) throws {
        response.headers["Access-Control-Allow-Headers"] = "accept, content-type"
        response.headers["Access-Control-Allow-Methods"] = "GET,POST,DELETE,OPTIONS,PUT"
        try response.status(.OK).end()
    }

    // MARK: GET

    public func getFriends(request: RouterRequest, response: RouterResponse, next: @escaping () -> Void) throws {

        let id = request.parameters["id"]

        var friends: [Friend]?

        if let id = id {
            friends = try dataAccessor.getFriends(withID: id)
        } else {
            friends = try dataAccessor.getFriends()
        }

        if friends == nil {
            try response.status(.notFound).end()
            return
        }

        try response.send(json: friends!.toJSON()).status(.OK).end()
    }

    public func searchInvites(request: RouterRequest, response: RouterResponse, next: @escaping () -> Void) throws {
    }

    public func getInvites(request: RouterRequest, response: RouterResponse, next: @escaping () -> Void) throws {
    }

    // MARK: POST

    public func postInvites(request: RouterRequest, response: RouterResponse, next: @escaping () -> Void) throws {
    }

    // MARK: PUT

    public func updateInvite(request: RouterRequest, response: RouterResponse, next: @escaping () -> Void) throws {
    }

    // MARK: DELETE

    public func deleteFriend(request: RouterRequest, response: RouterResponse, next: @escaping () -> Void) throws {
    }
}
