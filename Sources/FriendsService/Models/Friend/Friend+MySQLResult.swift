import MySQL
import LoggerAPI
import Foundation

// MARK: - MySQLResultProtocol (Friend)

public extension MySQLResultProtocol {

    public func toFriends() -> [Friend] {

        var friends = [Friend]()

        while case let row? = self.nextResult() {

            var friend = Friend()

            friend.id = row["id"] as? Int
            friend.userID1 = row["user_id_1"] as? Int
            friend.userID2 = row["user_id_2"] as? Int
            friend.accepted = row["accepted"] as? Int

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
        }

        return friends
    }
}
