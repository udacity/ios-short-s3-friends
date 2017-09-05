import Foundation
import SwiftyJSON
import LoggerAPI

// MARK: - InviteType

public enum InviteType: String {
    case inviter, invitee, all
}

// MARK: - Invite

public struct Invite {
    public var id: Int?
    public var inviterID: String?
    public var inviteeID: String?
    public var createdAt: Date?
    public var updatedAt: Date?
}

// MARK: - Invite: JSONAble

extension Invite: JSONAble {
    public func toJSON() -> JSON {
        var dict = [String: Any]()
        let nilValue: Any? = nil

        dict["id"] = id != nil ? id : nilValue
        dict["inviter_id"] = inviterID != nil ? inviterID : nilValue
        dict["invitee_id"] = inviteeID != nil ? inviteeID : nilValue

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"

        dict["created_at"] = createdAt != nil ? dateFormatter.string(from: createdAt!) : nilValue
        dict["updated_at"] = updatedAt != nil ? dateFormatter.string(from: updatedAt!) : nilValue

        return JSON(dict)
    }
}
