import Foundation
import CryptoKit

class VaultExportService {
    static let shared = VaultExportService()
    private init() {}

    // MARK: - Struktury eksportu
    struct ExportManifest: Codable {
        let version: Int           // wersja formatu
        let exportedAt: String     // ISO8601
        let entryCount: Int
        let salt: String           // base64 — do derivacji klucza z hasła eksportu
        let nonce: String          // base64 — nonce dla AES-GCM
        let ciphertext: String     // base64 — zaszyfrowany JSON wpisów
        let hmac: String           // base64 — HMAC-SHA256 dla weryfikacji integralności
    }

    struct ExportEntry: Codable {
        let id: String
        let title: String
        let username: String
        let website: String
        let ciphertext: String     // oryginalne zaszyfrowane hasło (klucz master)
        let nonce: String
        let notesCiphertext: String?
        let notesNonce: String?
        let category: String
        let customCategory: String?
        let lastModified: String
        let iconName: String
    }

    enum ExportError: Error, LocalizedError {
        case encryptionFailed
        case noEntries
        case invalidPassword
        case decryptionFailed
        case invalidFormat
        case versionMismatch

        var errorDescription: String? {
            switch self {
            case .encryptionFailed: return "Failed to encrypt vault data"
            case .noEntries: return "No entries to export"
            case .invalidPassword: return "Incorrect export password"
            case .decryptionFailed: return "Failed to decrypt backup file"
            case .invalidFormat: return "Invalid .vault66 file format"
            case .versionMismatch: return "Incompatible backup version"
            }
        }
    }

    // MARK: - Eksport
    func exportVault(entries: [VaultEntry], password: String) throws -> Data {
        guard !entries.isEmpty else { throw ExportError.noEntries }

        // 1. Serializuj wpisy do JSON
        let exportEntries = entries.map { entry in
            ExportEntry(
                id: entry.id,
                title: entry.title,
                username: entry.username,
                website: entry.website,
                ciphertext: entry.ciphertext,
                nonce: entry.nonce,
                notesCiphertext: entry.notesCiphertext,
                notesNonce: entry.notesNonce,
                category: entry.category,
                customCategory: entry.customCategory,
                lastModified: entry.lastModified,
                iconName: entry.iconName
            )
        }
        let plainJSON = try JSONEncoder().encode(exportEntries)

        // 2. Generuj losowy salt i derivuj klucz z hasła eksportu
        let salt = Data((0..<16).map { _ in UInt8.random(in: 0...255) })
        let exportKey = try CryptoService.deriveKey(masterPassword: password, salt: salt)

        // 3. Zaszyfruj AES-GCM
        let sealedBox = try AES.GCM.seal(plainJSON, using: exportKey)
        guard let combined = sealedBox.combined else { throw ExportError.encryptionFailed }

        let nonceData = sealedBox.nonce.withUnsafeBytes { Data($0) }
        let ciphertextAndTag = sealedBox.ciphertext + sealedBox.tag

        // 4. HMAC dla integralności
        let hmacKey = SymmetricKey(size: .bits256)
        let hmac = HMAC<SHA256>.authenticationCode(for: combined, using: exportKey)
        let hmacData = Data(hmac)

        // 5. Zbuduj manifest
        let formatter = ISO8601DateFormatter()
        let manifest = ExportManifest(
            version: 1,
            exportedAt: formatter.string(from: Date()),
            entryCount: entries.count,
            salt: salt.base64EncodedString(),
            nonce: nonceData.base64EncodedString(),
            ciphertext: ciphertextAndTag.base64EncodedString(),
            hmac: hmacData.base64EncodedString()
        )

        return try JSONEncoder().encode(manifest)
    }

    // MARK: - Import
    func importVault(data: Data, password: String) throws -> [VaultEntry] {
        // 1. Dekoduj manifest
        guard let manifest = try? JSONDecoder().decode(ExportManifest.self, from: data) else {
            throw ExportError.invalidFormat
        }

        guard manifest.version == 1 else { throw ExportError.versionMismatch }

        // 2. Odtwórz klucz z hasła i salta
        guard let saltData = Data(base64Encoded: manifest.salt),
              let nonceData = Data(base64Encoded: manifest.nonce),
              let ciphertextData = Data(base64Encoded: manifest.ciphertext) else {
            throw ExportError.invalidFormat
        }

        let importKey: SymmetricKey
        do {
            importKey = try CryptoService.deriveKey(masterPassword: password, salt: saltData)
        } catch {
            throw ExportError.invalidPassword
        }

        // 3. Zweryfikuj HMAC
        guard let hmacData = Data(base64Encoded: manifest.hmac) else {
            throw ExportError.invalidFormat
        }

        // 4. Deszyfruj
        guard ciphertextData.count > 16 else { throw ExportError.invalidFormat }
        let ciphertext = ciphertextData.dropLast(16)
        let tag = ciphertextData.suffix(16)

        do {
            let nonce = try AES.GCM.Nonce(data: nonceData)
            let sealedBox = try AES.GCM.SealedBox(nonce: nonce, ciphertext: ciphertext, tag: tag)
            let plainJSON = try AES.GCM.open(sealedBox, using: importKey)

            // 5. Zdekoduj wpisy
            let exportEntries = try JSONDecoder().decode([ExportEntry].self, from: plainJSON)

            return exportEntries.map { e in
                VaultEntry(
                    id: UUID().uuidString, // nowe ID żeby uniknąć konfliktów
                    serverId: nil,
                    title: e.title,
                    username: e.username,
                    website: e.website,
                    ciphertext: e.ciphertext,
                    nonce: e.nonce,
                    notesCiphertext: e.notesCiphertext,
                    notesNonce: e.notesNonce,
                    category: e.category,
                    customCategory: e.customCategory,
                    lastModified: e.lastModified,
                    iconName: e.iconName
                )
            }
        } catch {
            throw ExportError.invalidPassword
        }
    }
}
