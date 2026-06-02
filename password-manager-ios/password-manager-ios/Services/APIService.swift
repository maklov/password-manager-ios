import Foundation
import CryptoKit

enum NetworkError: Error {
    case offline
    case unauthorized
    case serverError(String)
    case decodingError
    case invalidURL
}

class APIService {
    static let shared = APIService()
    private init() {}

    private var baseURLString: String {
        guard let host = Bundle.main.object(forInfoDictionaryKey: "ApiHostUrl") as? String, !host.isEmpty else {
            fatalError("Brak ApiHostUrl w konfiguracji!")
        }
        return "https://\(host)/api"
    }

    // MARK: - Salt
    private func getSalt(email: String) async throws -> Data {
        guard let url = URL(string: "\(baseURLString)/\(email.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed)!)/salt") else {
            throw NetworkError.invalidURL
        }
        let (data, _) = try await URLSession.shared.data(from: url)
        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let saltString = json["salt"] as? String {
            return Data(base64Encoded: saltString) ?? Data()
        }
        throw NetworkError.decodingError
    }

    // MARK: - Register
    func register(email: String, password: String) async -> Result<Bool, NetworkError> {
        do {
            let salt = Data((0..<16).map { _ in UInt8.random(in: 0...255) })
            let key = try CryptoService.deriveKey(masterPassword: password, salt: salt)
            let authHash = key.withUnsafeBytes { Data($0) }.base64EncodedString()

            guard let url = URL(string: "\(baseURLString)/register") else { return .failure(.invalidURL) }
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try JSONEncoder().encode([
                "email": email,
                "server_auth_hash": authHash,
                "salt": salt.base64EncodedString()
            ])
            let (_, response) = try await URLSession.shared.data(for: request)
            return (response as? HTTPURLResponse)?.statusCode == 200 ? .success(true) : .failure(.serverError("Rejestracja nie powiodła się"))
        } catch { return .failure(.serverError(error.localizedDescription)) }
    }

    // MARK: - Login
    func login(email: String, password: String) async -> Result<String, NetworkError> {
        do {
            let salt = try await getSalt(email: email)
            let key = try CryptoService.deriveKey(masterPassword: password, salt: salt)
            let authHash = key.withUnsafeBytes { Data($0) }.base64EncodedString()

            guard let url = URL(string: "\(baseURLString)/login") else { return .failure(.invalidURL) }
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try JSONEncoder().encode([
                "email": email,
                "server_auth_hash": authHash
            ])
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse else { return .failure(.serverError("Brak odpowiedzi")) }
            if http.statusCode == 401 { return .failure(.unauthorized) }
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let token = json["access_token"] as? String {
                return .success(token)
            }
            return .failure(.unauthorized)
        } catch { return .failure(.serverError(error.localizedDescription)) }
    }

    private func handleURLError(_ error: URLError) -> NetworkError {
        switch error.code {
        case .notConnectedToInternet, .timedOut, .cannotFindHost, .cannotConnectToHost:
            return .offline
        default:
            return .serverError(error.localizedDescription)
        }
    }

    // MARK: - Fetch Vault
    func fetchVault(token: String) async -> Result<[VaultEntry], NetworkError> {
        guard let url = URL(string: "\(baseURLString)/entries") else { return .failure(.invalidURL) }
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse else { return .failure(.serverError("Brak odpowiedzi")) }
            if http.statusCode == 401 { return .failure(.unauthorized) }
            guard http.statusCode == 200 else { return .failure(.serverError("Kod: \(http.statusCode)")) }
            let entries = try JSONDecoder().decode([VaultEntry].self, from: data)
            return .success(entries)
        } catch let error as URLError {
            return .failure(handleURLError(error))
        } catch {
            return .failure(.decodingError)
        }
    }

    // MARK: - Sync (POST)
    func syncVaultToServer(entry: VaultEntry, token: String) async -> Result<Int, NetworkError> {
        guard let url = URL(string: "\(baseURLString)/entries") else { return .failure(.invalidURL) }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        do {
            var payload: [String: String?] = [
                "ciphertext": entry.ciphertext,
                "iv": entry.nonce,
                "notes_ciphertext": entry.notesCiphertext,
                "notes_iv": entry.notesNonce
            ]
            request.httpBody = try JSONEncoder().encode(payload)
            let (data, response) = try await URLSession.shared.data(for: request)

            if let http = response as? HTTPURLResponse, http.statusCode == 200,
               let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let serverId = json["id"] as? Int {
                print("[APIService] ✅ Wpis dodany, serverId: \(serverId)")
                return .success(serverId)
            }
            return .failure(.serverError("Błąd serwera"))
        } catch {
            return .failure(.offline)
        }
    }

    // MARK: - Update (PUT)
    func updateEntryOnServer(entry: VaultEntry, token: String) async -> Result<Void, NetworkError> {
        guard let serverId = entry.serverId else {
            _ = await syncVaultToServer(entry: entry, token: token)
            return .success(())
        }
        guard let url = URL(string: "\(baseURLString)/entries/\(serverId)/") else { return .failure(.invalidURL) }
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        do {
            let payload: [String: String?] = [
                "ciphertext": entry.ciphertext,
                "iv": entry.nonce,
                "notes_ciphertext": entry.notesCiphertext,
                "notes_iv": entry.notesNonce
            ]
            request.httpBody = try JSONEncoder().encode(payload)
            let (_, response) = try await URLSession.shared.data(for: request)
            if let http = response as? HTTPURLResponse, http.statusCode == 200 {
                return .success(())
            }
            return .failure(.serverError("Błąd serwera"))
        } catch {
            return .failure(.offline)
        }
    }

    // MARK: - Delete
    func deleteEntryFromServer(entry: VaultEntry, token: String) async -> Result<Void, NetworkError> {
        guard let serverId = entry.serverId else { return .success(()) }
        guard let url = URL(string: "\(baseURLString)/entries/\(serverId)") else { return .failure(.invalidURL) }
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            if let http = response as? HTTPURLResponse, http.statusCode == 200 { return .success(()) }
            return .failure(.serverError("Błąd serwera"))
        } catch {
            return .failure(.offline)
        }
    }
}
