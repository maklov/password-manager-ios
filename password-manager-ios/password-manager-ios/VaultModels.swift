//
//  VaultModels.swift
//  password-manager-ios
//
//  Created by DevMac on 24/03/2026.
//
import Foundation

  

// 1. Model pojedynczego wpisu (to, co zapiszemy lokalnie i wyślemy do API)

struct VaultEntry: Identifiable, Codable {

    var id: UUID = UUID()

    let title: String          // np. "Google"

    let subtitle: String       // np. "alex.designer@gmail.com"

    let ciphertext: String     // Nasze zaszyfrowane hasło

    let iv: String             // Wektor inicjalizujący

    let category: String       // np. "Social", "Finance"

    let lastModified: String   // np. "2 DAYS AGO"

    let iconName: String       // Nazwa ikony z SF Symbols

}

  

// 2. Prosty i bezpieczny Menedżer Offline

class LocalVaultManager: ObservableObject {

    @Published var entries: [VaultEntry] = []

     

    private let fileName = "encrypted_vault.json"

     

    private var fileURL: URL {

        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]

            .appendingPathComponent(fileName)

    }

     

    // Zapis do trybu offline

    func saveToOfflineCache() {

        do {

            let data = try JSONEncoder().encode(entries)

            try data.write(to: fileURL)

            print("Zapisano skarbiec lokalnie na wypadek braku Tailscale.")

        } catch {

            print("Błąd zapisu offline: \(error)")

        }

    }

     

    // Odczyt w trybie offline

    func loadFromOfflineCache() {

        do {

            let data = try Data(contentsOf: fileURL)

            entries = try JSONDecoder().decode([VaultEntry].self, from: data)

        } catch {

            print("Brak lokalnego pliku lub błąd odczytu: \(error)")

        }

    }

}
