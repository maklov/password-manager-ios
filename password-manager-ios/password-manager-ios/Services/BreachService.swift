import Foundation
import CryptoKit

class BreachService {
    static let shared = BreachService()
    private init() {}

    // HIBP używa k-anonymity: wysyłamy tylko pierwsze 5 znaków SHA-1
    // Serwer zwraca listę sufixów — nigdy nie wysyłamy pełnego hasła
    func isPasswordBreached(_ password: String) async -> Result<Int, Error> {
        guard let passwordData = password.data(using: .utf8) else {
            return .failure(BreachError.invalidInput)
        }

        // SHA-1 hasła
        let sha1 = Insecure.SHA1.hash(data: passwordData)
        let sha1Hex = sha1.map { String(format: "%02X", $0) }.joined()

        let prefix = String(sha1Hex.prefix(5))
        let suffix = String(sha1Hex.dropFirst(5))

        guard let url = URL(string: "https://api.pwnedpasswords.com/range/\(prefix)") else {
            return .failure(BreachError.invalidURL)
        }

        do {
            var request = URLRequest(url: url)
            // Wymagany nagłówek przez HIBP API
            request.setValue("vault66-password-manager", forHTTPHeaderField: "User-Agent")
            // Add-Padding zapobiega analizie ruchu sieciowego
            request.setValue("true", forHTTPHeaderField: "Add-Padding")

            let (data, response) = try await URLSession.shared.data(for: request)

            guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
                return .failure(BreachError.apiError)
            }

            guard let responseString = String(data: data, encoding: .utf8) else {
                return .failure(BreachError.decodingError)
            }

            // Parsuj odpowiedź: "SUFIKS:LICZBA_WYSTĄPIEŃ\r\n"
            let lines = responseString.components(separatedBy: "\r\n")
            for line in lines {
                let parts = line.components(separatedBy: ":")
                guard parts.count == 2 else { continue }
                if parts[0].uppercased() == suffix.uppercased() {
                    let count = Int(parts[1]) ?? 1
                    return .success(count)  // znalezione — zwróć liczbę wycieków
                }
            }

            return .success(0)  // nie znalezione
        } catch {
            return .failure(error)
        }
    }

    enum BreachError: Error {
        case invalidInput
        case invalidURL
        case apiError
        case decodingError
    }
}
