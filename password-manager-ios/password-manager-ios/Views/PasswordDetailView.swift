import SwiftUI

struct PasswordDetailView: View {
    @State var entry: VaultEntry // Używamy @State, aby móc edytować obiekt
    @Environment(\.dismiss) var dismiss
    
    var onDelete: () -> Void
    
    // Stany dla edycji i generatora
    @State private var isPasswordVisible: Bool = false
    @State private var showGenerator: Bool = true // Zgodnie z designem panel jest otwarty
    @State private var passwordLength: Double = 24
    @State private var useSymbols: Bool = true
    @State private var useNumbers: Bool = true
    
    var body: some View {
        ZStack {
            Color(red: 0.07, green: 0.07, blue: 0.08).ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    
                    // --- NAGŁÓWEK ---
                    VStack(spacing: 12) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.green.opacity(0.15))
                                .frame(width: 72, height: 72)
                            
                            Image(systemName: entry.iconName)
                                .foregroundColor(.green)
                                .font(.system(size: 32))
                        }
                        
                        VStack(spacing: 4) {
                            Text(entry.title)
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.white)
                            Text("LAST MODIFIED \(entry.lastModified)")
                                .font(.system(size: 11, weight: .bold))
                                .tracking(1.0)
                                .foregroundColor(.gray)
                        }
                    }
                    .padding(.top, 16)
                    
                    // --- SECURITY HEALTH ---
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Security Health")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                        
                        HStack(alignment: .bottom) {
                            Text("Your password is exceptionally\nstrong.")
                                .font(.system(size: 12))
                                .foregroundColor(.gray)
                            Spacer()
                            Text("98%")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(.white)
                        }
                        
                        // Pasek postępu (Gradient)
                        Capsule()
                            .fill(LinearGradient(colors: [Color(red: 1.0, green: 0.85, blue: 0.76), Color(red: 0.51, green: 0.51, blue: 1)], startPoint: .leading, endPoint: .trailing))
                            .frame(height: 4)
                    }
                    .padding()
                    .background(Color(red: 0.12, green: 0.12, blue: 0.13))
                    .cornerRadius(16)
                    
                    // --- POLA DANYCH ---
                    VStack(spacing: 16) {
                        DetailRow(label: "USERNAME", value: entry.username, isCopyable: true)
                        DetailRow(label: "PASSWORD", value: "••••••••••••••••••••••••", isCopyable: true, isSecure: true)
                        DetailRow(label: "WEBSITE", value: "github.com", isCopyable: false, actionIcon: "arrow.up.right.square")
                    }
                    
                    // --- GENERATOR HASEŁ (EDYCJA) ---
                    VStack(spacing: 0) {
                        // Przycisk rozwijający
                        Button(action: {
                            withAnimation { showGenerator.toggle() }
                        }) {
                            HStack {
                                Image(systemName: "wand.and.stars")
                                Text("Generate Strong Password")
                                Spacer()
                                Image(systemName: showGenerator ? "chevron.down" : "chevron.right")
                            }
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                            .padding()
                            .background(Color(red: 0.16, green: 0.16, blue: 0.17))
                        }
                        
                        if showGenerator {
                            VStack(spacing: 20) {
                                HStack {
                                    Image(systemName: "shield.fill")
                                    Text("Generator Settings")
                                        .font(.system(size: 14, weight: .bold))
                                    Spacer()
                                }
                                .foregroundColor(.white)
                                
                                // Suwak długości
                                VStack(spacing: 12) {
                                    HStack {
                                        Text("Length")
                                            .foregroundColor(.white)
                                        Spacer()
                                        Text("\(Int(passwordLength))")
                                            .font(.caption).bold()
                                            .padding(.horizontal, 8).padding(.vertical, 4)
                                            .background(Color(red: 0.51, green: 0.51, blue: 1).opacity(0.2))
                                            .foregroundColor(Color(red: 0.51, green: 0.51, blue: 1))
                                            .cornerRadius(8)
                                    }
                                    Slider(value: $passwordLength, in: 8...32, step: 1)
                                        .tint(Color(red: 0.51, green: 0.51, blue: 1))
                                }
                                
                                // Przełączniki
                                HStack(spacing: 16) {
                                    Toggle("Symbols", isOn: $useSymbols)
                                        .toggleStyle(.button)
                                        .tint(Color(red: 0.51, green: 0.51, blue: 1))
                                    
                                    Toggle("Numbers", isOn: $useNumbers)
                                        .toggleStyle(.button)
                                        .tint(Color(red: 0.51, green: 0.51, blue: 1))
                                }
                                
                                // Przycisk Update
                                Button(action: {
                                    print("Aktualizowanie hasła dla \(entry.title)")
                                    // Tutaj wejdzie AES-GCM żeby zaszyfrować nowe hasło
                                }) {
                                    Text("Update Password")
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundColor(Color(red: 0.08, green: 0.08, blue: 0.4))
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                        .background(Color(red: 0.51, green: 0.51, blue: 1))
                                        .cornerRadius(12)
                                }
                            }
                            .padding()
                            .background(Color(red: 0.12, green: 0.12, blue: 0.13))
                        }
                    }
                    .cornerRadius(16)
                    
                    // --- USUWANIE ---
                    Button(action: {
                        print("Usuwanie wpisu: \(entry.title)")
                        dismiss() // Powrót do listy
                    }) {
                        Label("Delete Entry", systemImage: "trash.fill")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(Color.red.opacity(0.8))
                            .padding(.vertical, 24)
                    }
                }
                .padding(24)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        // Podmiana koloru strzałki "Wstecz" na fioletowy
        .tint(Color(red: 0.51, green: 0.51, blue: 1))
    }
}

// Komponent wiersza dla danych (Username, Password, itp.)
struct DetailRow: View {
    let label: String
    let value: String
    var isCopyable: Bool = false
    var isSecure: Bool = false
    var actionIcon: String? = nil
    
    @State private var showPlaintext = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(.gray)
            
            HStack {
                if isSecure && !showPlaintext {
                    Text(value)
                        .font(.system(size: 18, weight: .black, design: .monospaced))
                        .foregroundColor(.white)
                } else {
                    Text(value)
                        .font(.system(size: 14, design: .monospaced))
                        .foregroundColor(Color(red: 0.76, green: 0.78, blue: 0.84))
                }
                
                Spacer()
                
                HStack(spacing: 16) {
                    if isSecure {
                        Button(action: { showPlaintext.toggle() }) {
                            Image(systemName: showPlaintext ? "eye.slash.fill" : "eye.fill")
                                .foregroundColor(.gray)
                        }
                    }
                    
                    if isCopyable {
                        Button(action: {
                            // Kopiowanie do schowka
                            UIPasteboard.general.string = value
                        }) {
                            Image(systemName: "doc.on.doc.fill")
                                .foregroundColor(Color(red: 0.51, green: 0.51, blue: 1).opacity(0.8))
                                .padding(8)
                                .background(Color.white.opacity(0.05))
                                .cornerRadius(8)
                        }
                    }
                    
                    if let icon = actionIcon {
                        Button(action: { /* Otwórz URL */ }) {
                            Image(systemName: icon)
                                .foregroundColor(.gray)
                                .padding(8)
                                .background(Color.white.opacity(0.05))
                                .cornerRadius(8)
                        }
                    }
                }
            }
            .padding()
            .background(Color(red: 0.16, green: 0.16, blue: 0.17))
            .cornerRadius(12)
        }
    }
}

// KRYTYCZNE DLA PODGLĄDU: Wstrzykujemy mockowane dane, żeby Canvas wiedział, co narysować!
struct PasswordDetailView_Previews: PreviewProvider {
    static var previews: some View {
        // Tworzymy fejkowe dane specjalnie dla podglądu
        let mockEntry = VaultEntry(
            title: "GitHub",
            username: "alex.dev_sanctuary",
            website: "www.github.com",
            ciphertext: "SZYFROGRAM_TUTAJ",
            iv: "IV_TUTAJ",
            category: "Work",
            lastModified: "2 DAYS AGO",
            iconName: "network"
        )
        
        // Zamykamy w NavigationStack, żeby było widać stylizację paska nawigacji
        NavigationStack {
            PasswordDetailView(entry: mockEntry, onDelete: {})
        }
    }
}
