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

        guard let pageSize = Int(request.queryParameters["page_size"] ?? "10"), let pageNumber = Int(request.queryParameters["page_number"] ?? "1"),
            pageSize > 0, pageSize <= 50 else {
            Log.error("Cannot initialize query parameters: page_size, page_number. page_size must be (0, 50].")
            try response.send(json: JSON(["message": "Cannot initialize query parameters: page_size, page_number. page_size must be (0, 50]."]))
                        .status(.badRequest).end()
            return
        }

        guard let id = request.parameters["id"] else {
            Log.error("Cannot initialize path parameter: id.")
            try response.send(json: JSON(["message": "Cannot initialize path parameter: id."]))
                        .status(.badRequest).end()
            return
        }

        let friends = try dataAccessor.getFriends(withUserID: id, pageSize: pageSize, pageNumber: pageNumber)

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
