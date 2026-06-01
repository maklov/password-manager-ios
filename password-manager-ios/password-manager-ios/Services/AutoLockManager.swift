import Foundation
import Combine

enum AutoLockTimeout: Int, CaseIterable, Identifiable {
    case immediately = 0
    case thirtySeconds = 30
    case oneMinute = 60
    case threeMinutes = 180

    var id: Int { rawValue }

    var label: String {
        switch self {
        case .immediately: return "Immediately"
        case .thirtySeconds: return "30 seconds"
        case .oneMinute: return "1 minute"
        case .threeMinutes: return "3 minutes"
        }
    }
}

@MainActor
class AutoLockManager: ObservableObject {
    @Published var isLocked: Bool = false

    // Zapisywany wybór użytkownika
    var selectedTimeout: AutoLockTimeout {
        get {
            let raw = UserDefaults.standard.integer(forKey: "auto_lock_timeout")
            return AutoLockTimeout(rawValue: raw) ?? .oneMinute
        }
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: "auto_lock_timeout")
        }
    }

    private var lockTimer: Task<Void, Never>? = nil
    private var lastActivityDate: Date = Date()
    private var isAuthenticated: Bool = false

    func onAppAuthenticated() {
        isAuthenticated = true
        isLocked = false
        resetActivityTimer()
    }

    func onAppLogout() {
        isAuthenticated = false
        isLocked = false
        cancelTimer()
    }

    // Wywołaj przy każdym dotyku ekranu
    func registerActivity() {
        guard isAuthenticated else { return }
        lastActivityDate = Date()
    }

    // Wywołaj gdy app wchodzi w tło
    func onAppBackground() {
        guard isAuthenticated else { return }

        if selectedTimeout == .immediately {
            triggerLock()
            return
        }
        // Dla innych timeoutów — zapisz czas wejścia w tło
        // timer inactivity już działa, nie robimy nic extra
    }

    // Wywołaj gdy app wraca na pierwszy plan
    func onAppForeground() {
        guard isAuthenticated, !isLocked else { return }

        if selectedTimeout == .immediately {
            // Już zablokowane przez onAppBackground
            return
        }

        // Sprawdź czy minął timeout od momentu wejścia w tło
        let elapsed = Date().timeIntervalSince(lastActivityDate)
        if elapsed >= Double(selectedTimeout.rawValue) {
            triggerLock()
        }
    }

    // Startuje pętlę sprawdzającą bezczynność co sekundę
    func resetActivityTimer() {
        cancelTimer()
        guard selectedTimeout != .immediately else { return }

        lockTimer = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 1_000_000_000) // co 1 sekundę
                await MainActor.run {
                    guard let self = self,
                          self.isAuthenticated,
                          !self.isLocked else { return }

                    let elapsed = Date().timeIntervalSince(self.lastActivityDate)
                    if elapsed >= Double(self.selectedTimeout.rawValue) {
                        self.triggerLock()
                    }
                }
            }
        }
    }

    func triggerLock() {
        isLocked = true
        cancelTimer()
    }

    func unlock() {
        isLocked = false
        lastActivityDate = Date()
        resetActivityTimer()
    }

    private func cancelTimer() {
        lockTimer?.cancel()
        lockTimer = nil
    }
}
