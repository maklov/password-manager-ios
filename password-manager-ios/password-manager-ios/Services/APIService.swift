import Foundation

enum NetworkError: Error {
    case offline
    case unauthorized
    case serverError(String)
    case decodingError
    case invalidURL
}

import Foundation
import CryptoKit

class APIService {
    static let shared = APIService()
    private init() {}
    
    private var baseURLString: String {
        guard let host = Bundle.main.object(forInfoDictionaryKey: "ApiHostUrl") as? String, !host.isEmpty else {
            fatalError("Brak ApiHostUrl w konfiguracji!")
        }
        return "http://\(host)/api"
    }

    // MARK: - 1. Pobranie soli
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

        // MARK: - 2. Rejestracja
        func register(email: String, password: String) async -> Result<Bool, NetworkError> {
            do {
                let salt = Data((0..<16).map { _ in UInt8.random(in: 0...255) })
                
                // Poprawna obsługa: deriveKey rzuca błąd, więc musi być try
                let key = try CryptoService.deriveKey(masterPassword: password, salt: salt)
                
                // Wydobycie bajtów z klucza CryptoKit w bezpieczny sposób
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

        // MARK: - 3. Logowanie
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
                
                let (data, _) = try await URLSession.shared.data(for: request)
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

    // MARK: - 4. Synchronizacja (Entries)
    func fetchVault(token: String) async -> Result<[VaultEntry], NetworkError> {
        guard let url = URL(string: "\(baseURLString)/entries") else {
            return .failure(.invalidURL)
        }
        
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        do {
            // Obsługa błędów sieciowych
            let (data, response) = try await URLSession.shared.data(for: request)
            
            // Sprawdzenie czy serwer odpowiedział poprawnym kodem
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                return .failure(.serverError("Błędny kod odpowiedzi serwera"))
            }
            
            // Obsługa błędów dekodowania
            let entries = try JSONDecoder().decode([VaultEntry].self, from: data)
            return .success(entries)
            
        } catch let error as URLError {
            return .failure(handleURLError(error))
        } catch {
            return .failure(.decodingError)
        }
    }

    func syncVaultToServer(entry: VaultEntry, token: String) async -> Result<Int, NetworkError> {
        guard let url = URL(string: "\(baseURLString)/entries") else { return .failure(.invalidURL) }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            let payload: [String: String] = [
                "ciphertext": entry.ciphertext,
                "iv": entry.nonce
            ]
            request.httpBody = try JSONEncoder().encode(payload)
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let serverId = json["id"] as? Int {
                    print("[APIService] ✅ Serwer przyjął wpis, serverId: \(serverId)")
                    return .success(serverId)
                }
                return .failure(.decodingError)
            } else {
                return .failure(.serverError("Błąd serwera"))
            }
        } catch {
            return .failure(.offline)
        }
    }
    func deleteEntryFromServer(entry: VaultEntry, token: String) async -> Result<Void, NetworkError> {
        guard let serverId = entry.serverId else {
            print("[APIService] ⚠️ Brak serverId, wpis tylko lokalny — pomijam delete na serwerze")
            return .success(())
        }
        
        guard let url = URL(string: "\(baseURLString)/entries/\(serverId)") else {
            return .failure(.invalidURL)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                return .success(())
            } else {
                let code = (response as? HTTPURLResponse)?.statusCode ?? 0
                return .failure(.serverError("Błąd serwera (kod: \(code))"))
            }
        } catch {
            return .failure(.offline)
        }
    }
    func updateEntryOnServer(entry: VaultEntry, token: String) async -> Result<Void, NetworkError> {
        guard let serverId = entry.serverId else {
            // Brak serverId = wpis nigdy nie był na serwerze, użyj POST
            _ = await syncVaultToServer(entry: entry, token: token)
            return .success(())
        }
        
        guard let url = URL(string: "\(baseURLString)/entries/\(serverId)/") else {
            return .failure(.invalidURL)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            let payload: [String: String] = [
                "ciphertext": entry.ciphertext,
                "iv": entry.nonce
            ]
            request.httpBody = try JSONEncoder().encode(payload)
            
            let (_, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                print("[APIService] ✅ Wpis zaktualizowany na serwerze (serverId: \(serverId))")
                return .success(())
            } else {
                let code = (response as? HTTPURLResponse)?.statusCode ?? 0
                return .failure(.serverError("Błąd serwera (kod: \(code))"))
            }
        } catch {
            return .failure(.offline)
        }
    }
}
