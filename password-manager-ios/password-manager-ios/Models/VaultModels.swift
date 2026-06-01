import Foundation

struct VaultEntry: Codable, Identifiable {
    var id: String
    var serverId: Int?
    var title: String
    var username: String
    var website: String
    var ciphertext: String
    var nonce: String
    var notesCiphertext: String?   // szyfrowane notes
    var notesNonce: String?        // nonce dla notes
    var category: String
    var customCategory: String?    // własna kategoria użytkownika
    var lastModified: String
    var iconName: String

    // Efektywna kategoria — custom ma priorytet
    var effectiveCategory: String {
        if category == "Custom", let custom = customCategory, !custom.isEmpty {
            return custom
        }
        return category
    }
}
