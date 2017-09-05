import MySQL
import LoggerAPI
import Foundation

// MARK: - MySQLResultProtocol (Invite)

public extension MySQLResultProtocol {

    public func toInvites(pageSize: Int = 10) -> [Invite] {

        var invites = [Invite]()

        while case let row? = self.nextResult() {

            var invite = Invite()

            invite.id = row["invite_id"] as? Int
            invite.inviterID = row["inviter_id"] as? String
            invite.inviteeID = row["invitee_id"] as? String

            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"

            if let createdAtString = row["created_at"] as? String,
               let createdAt = dateFormatter.date(from: createdAtString) {
                   invite.createdAt = createdAt
            }

            if let updatedAtString = row["updated_at"] as? String,
               let updatedAt = dateFormatter.date(from: updatedAtString) {
                   invite.updatedAt = updatedAt
            }

            invites.append(invite)

            // Return collection limited by page size if specified
            if pageSize > 0 && invites.count == Int(pageSize) {
                break
            }
        }

        return invites
    }
}
