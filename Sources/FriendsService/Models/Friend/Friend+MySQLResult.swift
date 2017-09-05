import MySQL
import LoggerAPI
import Foundation

// MARK: - MySQLResultProtocol (Friend)

public extension MySQLResultProtocol {

    public func toFriends(pageSize: Int = 10) -> [Friend] {

        var friends = [Friend]()

        while case let row? = self.nextResult() {

            var friend = Friend()

            friend.id = row["friend_id"] as? Int
            friend.userID = row["current_user_id"] as? Int
            friend.friendID = row["friend_user_id"] as? Int

            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"

            if let createdAtString = row["created_at"] as? String,
               let createdAt = dateFormatter.date(from: createdAtString) {
                   friend.createdAt = createdAt
            }

            if let updatedAtString = row["updated_at"] as? String,
               let updatedAt = dateFormatter.date(from: updatedAtString) {
                   friend.updatedAt = updatedAt
            }

            friends.append(friend)

            // Return collection limited by page size if specified
            if pageSize > 0 && friends.count == Int(pageSize) {
                break
            }
        }

        return friends
    }
}
