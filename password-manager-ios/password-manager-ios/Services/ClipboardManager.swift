import UIKit
import Combine

class ClipboardManager {
    static let shared = ClipboardManager()
    private init() {}

    private var clearTask: Task<Void, Never>? = nil
    private let clearDelay: TimeInterval = 30

    // Kopiuje wartość i planuje wyczyszczenie po 30 sekundach
    func copy(_ value: String) {
        UIPasteboard.general.string = value

        // Anuluj poprzedni task jeśli był
        clearTask?.cancel()

        clearTask = Task {
            try? await Task.sleep(nanoseconds: UInt64(clearDelay) * 1_000_000_000)
            guard !Task.isCancelled else { return }

            await MainActor.run {
                // Wyczyść tylko jeśli to nadal nasza wartość
                if UIPasteboard.general.string == value {
                    UIPasteboard.general.string = ""
                    print("[ClipboardManager] 🧹 Schowek wyczyszczony po \(Int(self.clearDelay))s")
                }
            }
        }
    }

    func cancelClear() {
        clearTask?.cancel()
        clearTask = nil
    }
}
