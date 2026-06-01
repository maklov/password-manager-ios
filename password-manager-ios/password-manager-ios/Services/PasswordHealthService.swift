import Foundation
import CryptoKit

struct PasswordHealthReport {
    let weakEntries: [VaultEntry]        // hasło < 8 znaków
    let duplicateEntries: [VaultEntry]   // to samo hasło w wielu wpisach
    let breachedEntries: [VaultEntry]    // znalezione w HIBP (opcjonalne, ładowane osobno)
    let totalEntries: Int

    var score: Int {
        guard totalEntries > 0 else { return 100 }
        let problems = Set(weakEntries.map { $0.id })
            .union(Set(duplicateEntries.map { $0.id }))
            .union(Set(breachedEntries.map { $0.id }))
        let problemCount = problems.count
        let ratio = Double(problemCount) / Double(totalEntries)
        return max(0, Int((1.0 - ratio) * 100))
    }

    var scoreLabel: String {
        switch score {
        case 90...100: return "Excellent"
        case 70..<90:  return "Good"
        case 50..<70:  return "Fair"
        default:       return "At Risk"
        }
    }

    var scoreColor: String {
        switch score {
        case 90...100: return "green"
        case 70..<90:  return "blue"
        case 50..<70:  return "orange"
        default:       return "red"
        }
    }
}

class PasswordHealthService {
    static let shared = PasswordHealthService()
    private init() {}

    func analyze(entries: [VaultEntry], masterKey: SymmetricKey?) -> PasswordHealthReport {
        guard let key = masterKey else {
            return PasswordHealthReport(weakEntries: [], duplicateEntries: [],
                                        breachedEntries: [], totalEntries: entries.count)
        }

        var decryptedPasswords: [String: String] = [:] // id -> plaintext
        for entry in entries {
            if let plain = try? CryptoService.decrypt(
                combinedCiphertext: entry.ciphertext,
                nonceBase64: entry.nonce,
                using: key
            ) {
                decryptedPasswords[entry.id] = plain
            }
        }

        // Słabe hasła — poniżej 8 znaków
        let weakEntries = entries.filter { entry in
            guard let plain = decryptedPasswords[entry.id] else { return false }
            return plain.count < 8
        }

        // Duplikaty — te same hasła w różnych wpisach
        var passwordCount: [String: [String]] = [:] // plaintext -> [id]
        for (id, plain) in decryptedPasswords {
            passwordCount[plain, default: []].append(id)
        }
        let duplicateIds = Set(
            passwordCount.filter { $0.value.count > 1 }.values.flatMap { $0 }
        )
        let duplicateEntries = entries.filter { duplicateIds.contains($0.id) }

        return PasswordHealthReport(
            weakEntries: weakEntries,
            duplicateEntries: duplicateEntries,
            breachedEntries: [],
            totalEntries: entries.count
        )
    }
}
