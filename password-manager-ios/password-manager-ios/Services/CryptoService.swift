import Foundation
import CryptoKit
import Argon2Swift

class CryptoService {
    
    enum CryptoError: Error {
        case keyDerivationFailed
        case encryptionFailed
        case decryptionFailed
        case invalidData
    }

    // 1. Wyprowadzanie Klucza Głównego (Argon2id)
    static func deriveKey(masterPassword: String, salt: Data) throws -> SymmetricKey {
        do {
            let result = try Argon2Swift.hashPasswordString(
                password: masterPassword,
                salt: Salt(bytes: salt),
                iterations: 3,
                memory: 65536,
                parallelism: 4,
                length: 32,
                type: .id
            )
            
            let derivedKeyData = result.hashData()
            print("[CryptoService] 🔐 Klucz wygenerowany przez Argon2id.")
            return SymmetricKey(data: derivedKeyData)
            
        } catch {
            print("[CryptoService] ❌ Błąd Argon2: \(error)")
            throw CryptoError.keyDerivationFailed
        }
    }

    // 2. Szyfrowanie Hasła (AES-GCM)
    static func encrypt(plaintext: String, using key: SymmetricKey) throws -> (ciphertext: String, nonce: String) {
        guard let plaintextData = plaintext.data(using: .utf8) else {
            throw CryptoError.invalidData
        }
        
        // Szyfrujemy dane przy użyciu klucza symetrycznego
        let sealedBox = try AES.GCM.seal(plaintextData, using: key)
        
        let ciphertextBase64 = sealedBox.ciphertext.base64EncodedString()
        let nonceBase64 = sealedBox.nonce.withUnsafeBytes { Data($0).base64EncodedString() }
        let tagBase64 = sealedBox.tag.base64EncodedString()
        
        // Łączymy szyfrogram z tagiem autentykacji (rozwiązanie AEAD)
        let combinedCiphertext = "\(ciphertextBase64):\(tagBase64)"
        
        return (ciphertext: combinedCiphertext, nonce: nonceBase64)
    }

    // 3. Deszyfrowanie Hasła (AES-GCM)
    static func decrypt(combinedCiphertext: String, nonceBase64: String, using key: SymmetricKey) throws -> String {
        let parts = combinedCiphertext.split(separator: ":")
        guard parts.count == 2,
              let ciphertextData = Data(base64Encoded: String(parts[0])),
              let tagData = Data(base64Encoded: String(parts[1])),
              let nonceData = Data(base64Encoded: nonceBase64) else {
            throw CryptoError.invalidData
        }
        
        let nonce = try AES.GCM.Nonce(data: nonceData)
        let sealedBox = try AES.GCM.SealedBox(nonce: nonce, ciphertext: ciphertextData, tag: tagData)
        
        // Otwieramy sejf za pomocą klucza
        let decryptedData = try AES.GCM.open(sealedBox, using: key)
        
        guard let plaintext = String(data: decryptedData, encoding: .utf8) else {
            throw CryptoError.decryptionFailed
        }
        
        return plaintext
    }
}
