import Foundation
import SwiftyJSON
import LoggerAPI

// MARK: - Friend

public struct Friend {
    public var id: Int?
    public var userID1: Int?
    public var userID2: Int?
    public var accepted: Int?
    public var createdAt: Date?
    public var updatedAt: Date?
}

// MARK: - Friend: JSONAble

extension Friend: JSONAble {
    public func toJSON() -> JSON {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"

        var dict = [String: Any]()
        let nilValue: Any? = nil

        dict["id"] = id != nil ? id : nilValue
        dict["user_id_1"] = userID1 != nil ? userID1 : nilValue
        dict["user_id_2"] = userID2 != nil ? userID2 : nilValue
        dict["accepted"] = accepted != nil ? accepted : nilValue

        dict["created_at"] = createdAt != nil ? dateFormatter.string(from: createdAt!) : nilValue
        dict["updated_at"] = updatedAt != nil ? dateFormatter.string(from: updatedAt!) : nilValue

        return JSON(dict)
    }
}
