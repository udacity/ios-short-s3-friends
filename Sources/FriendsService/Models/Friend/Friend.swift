import Foundation
import SwiftyJSON
import LoggerAPI

// MARK: - Friend

public struct Friend {
    public var id: Int?
    public var userID: Int?
    public var friendID: Int?
    public var createdAt: Date?
    public var updatedAt: Date?
}

// MARK: - Friend: JSONAble

extension Friend: JSONAble {
    public func toJSON() -> JSON {
        var dict = [String: Any]()
        let nilValue: Any? = nil

        dict["friend_id"] = id != nil ? id : nilValue
        dict["user_id"] = userID != nil ? userID : nilValue
        dict["friend_user_id"] = friendID != nil ? friendID : nilValue

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"

        dict["created_at"] = createdAt != nil ? dateFormatter.string(from: createdAt!) : nilValue
        dict["updated_at"] = updatedAt != nil ? dateFormatter.string(from: updatedAt!) : nilValue

        return JSON(dict)
    }
}
