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

        // FIXME: Use userID from JWT
        guard let body = request.body, case let .json(json) = body, let userID = json["user_id"].string else {
            Log.error("Cannot initialize request body. This endpoint expects the request body to be a valid JSON object.")
            try response.send(json: JSON(["message": "Cannot initialize request body. This endpoint expects the request body to be a valid JSON object."]))
                        .status(.badRequest).end()
            return
        }

        guard let pageSize = Int(request.queryParameters["page_size"] ?? "10"), let pageNumber = Int(request.queryParameters["page_number"] ?? "1"),
            pageSize > 0, pageSize <= 50 else {
            Log.error("Cannot initialize query parameters: page_size, page_number. page_size must be (0, 50].")
            try response.send(json: JSON(["message": "Cannot initialize query parameters: page_size, page_number. page_size must be (0, 50]."]))
                        .status(.badRequest).end()
            return
        }

        guard let filterType = request.queryParameters["type"], let type = InviteType(rawValue: filterType) else {
            Log.error("Cannot initialize query parameter: type. type must be upcoming, past, or all.")
            try response.send(json: JSON(["message": "Cannot initialize query parameter: type. type must be upcoming, past, or all."]))
                        .status(.badRequest).end()
            return
        }

        let invites = try dataAccessor.getInvites(forUserID: userID, pageSize: pageSize, pageNumber: pageNumber, type: type)

        if invites == nil {
            try response.status(.notFound).end()
            return
        }

        try response.send(json: invites!.toJSON()).status(.OK).end()
    }

    public func getInvites(request: RouterRequest, response: RouterResponse, next: @escaping () -> Void) throws {

        // FIXME: Use userID from JWT
        guard let body = request.body, case let .json(json) = body, let userID = json["user_id"].string else {
            Log.error("Cannot initialize request body. This endpoint expects the request body to be a valid JSON object.")
            try response.send(json: JSON(["message": "Cannot initialize request body. This endpoint expects the request body to be a valid JSON object."]))
                        .status(.badRequest).end()
            return
        }

        guard let pageSize = Int(request.queryParameters["page_size"] ?? "10"), let pageNumber = Int(request.queryParameters["page_number"] ?? "1"),
            pageSize > 0, pageSize <= 50 else {
            Log.error("Cannot initialize query parameters: page_size, page_number. page_size must be (0, 50].")
            try response.send(json: JSON(["message": "Cannot initialize query parameters: page_size, page_number. page_size must be (0, 50]."]))
                        .status(.badRequest).end()
            return
        }

        let invites = try dataAccessor.getInvites(forUserID: userID, pageSize: pageSize, pageNumber: pageNumber, type: .all)

        if invites == nil {
            try response.status(.notFound).end()
            return
        }

        try response.send(json: invites!.toJSON()).status(.OK).end()
    }

    // MARK: POST

    public func postInvites(request: RouterRequest, response: RouterResponse, next: @escaping () -> Void) throws {

        // FIXME: Post invites from user in JWT
        guard let body = request.body, case let .json(json) = body, let userID = json["user_id"].string else {
            Log.error("Cannot initialize request body. This endpoint expects the request body to be a valid JSON object.")
            try response.send(json: JSON(["message": "Cannot initialize request body. This endpoint expects the request body to be a valid JSON object."]))
                        .status(.badRequest).end()
            return
        }

        guard let userIDsJSON = json["user_ids"].array else {
            Log.error("Cannot initialize body parameters: user_ids. user_ids is a JSON array of strings (used ids) for sending friend requests.")
            try response.send(json: JSON(["message": "Cannot initialize body parameters: user_ids. user_ids is a JSON array of strings (used ids) for sending friend requests."]))
                        .status(.badRequest).end()
            return
        }

        var inviteeIDs: [String] = []
        for userIDJSON in userIDsJSON {
            if let userID = userIDJSON.string {
                inviteeIDs.append(userID)
            }
        }
        guard inviteeIDs.count > 0 else {
            Log.error("Cannot initialize body parameters: user_ids. user_ids is a JSON array of strings (used ids) for sending friend requests.")
            try response.send(json: JSON(["message": "Cannot initialize body parameters: user_ids. user_ids is a JSON array of strings (used ids) for sending friend requests."]))
                        .status(.badRequest).end()
            return
        }

        let success = try dataAccessor.createInvites(forUserID: userID, inviteUserIDs: inviteeIDs)

        if success {
            try response.send(json: JSON(["message": "Friend invites sent."])).status(.created).end()
            return
        }

        try response.status(.notModified).end()
    }

    // MARK: PUT

    public func updateInvite(request: RouterRequest, response: RouterResponse, next: @escaping () -> Void) throws {
        // FIXME: Only allow for updating an invite if JWT user matches the invitee.
        guard let id = request.parameters["id"] else {
            Log.error("Cannot initialize path parameter: id.")
            try response.send(json: JSON(["message": "Cannot initialize path parameter: id."]))
                        .status(.badRequest).end()
            return
        }

        guard let body = request.body, case let .json(json) = body else {
            Log.error("Cannot initialize request body. This endpoint expects the request body to be a valid JSON object.")
            try response.send(json: JSON(["message": "Cannot initialize request body. This endpoint expects the request body to be a valid JSON object."]))
                        .status(.badRequest).end()
            return
        }

        guard let accepted = json["accepted"].bool else {
            Log.error("Cannot initialize body parameters: accepted. accepted is a boolean value.")
            try response.send(json: JSON(["message": "Cannot initialize body parameters: accepted. accepted is a boolean value."]))
                        .status(.badRequest).end()
            return
        }

        let success = try dataAccessor.updateInvite(id: id, accepted: accepted)

        if success {
            try response.send(json: JSON(["message": "Invite successfully \(accepted ? "accepted" : "declined")."])).status(.OK).end()
            return
        }

        try response.status(.notModified).end()
    }

    // MARK: DELETE

    public func deleteFriends(request: RouterRequest, response: RouterResponse, next: @escaping () -> Void) throws {

        guard let body = request.body, case let .json(json) = body else {
            Log.error("Cannot initialize request body. This endpoint expects the request body to be a valid JSON object.")
            try response.send(json: JSON(["message": "Cannot initialize request body. This endpoint expects the request body to be a valid JSON object."]))
                        .status(.badRequest).end()
            return
        }

        guard let removeFriendIDsJSON = json["friend_ids"].array else {
            Log.error("Cannot initialize body parameters: friend_ids. friend_ids is a JSON array of strings (friend ids) to remove.")
            try response.send(json: JSON(["message": "Cannot initialize body parameters: friend_ids. friend_ids is a JSON array of strings (friend ids) to remove."]))
                        .status(.badRequest).end()
            return
        }

        var friendIDs: [String] = []
        for removeFriendIDJSON in removeFriendIDsJSON {
            if let friendID = removeFriendIDJSON.string {
                friendIDs.append(friendID)
            }
        }
        guard friendIDs.count > 0 else {
            Log.error("Cannot initialize body parameters: friend_ids. friend_ids is a JSON array of strings (friend ids) to remove.")
            try response.send(json: JSON(["message": "Cannot initialize body parameters: friend_ids. friend_ids is a JSON array of strings (friend ids) to remove."]))
                        .status(.badRequest).end()
            return
        }

        let success = try dataAccessor.deleteFriends(friendIDs: friendIDs)

        if success {
            try response.send(json: JSON(["message": "Friends deleted."])).status(.noContent).end()
            return
        }

        try response.status(.notModified).end()
    }
}
