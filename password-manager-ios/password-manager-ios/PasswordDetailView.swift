import SwiftUI

struct PasswordDetailView: View {
    let entry: VaultEntry
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack {
            Color(red: 0.07, green: 0.07, blue: 0.08).ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    // Header z ikoną
                    VStack(spacing: 12) {
                        Image(systemName: entry.iconName)
                            .font(.system(size: 40))
                            .frame(width: 80, height: 80)
                            .background(Color.green.opacity(0.2))
                            .cornerRadius(20)
                        
                        Text(entry.title)
                            .font(.title).bold()
                        Text("LAST MODIFIED \(entry.lastModified)")
                            .font(.caption).foregroundColor(.gray)
                    }
                    .padding(.top, 20)
                    
                    // Pola danych
                    VStack(spacing: 16) {
                        DetailField(label: "USERNAME", value: entry.subtitle, isSecure: false)
                        DetailField(label: "PASSWORD", value: "••••••••••••", isSecure: true)
                        DetailField(label: "WEBSITE", value: "github.com", isSecure: false)
                    }
                    
                    // Przycisk usuwania (z image_1db442)
                    Button(action: { dismiss() }) {
                        Label("Delete Entry", systemImage: "trash")
                            .foregroundColor(.red)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.red.opacity(0.1))
                            .cornerRadius(12)
                    }
                    .padding(.top, 40)
                }
                .padding(24)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct DetailField: View {
    let label: String; let value: String; let isSecure: Bool
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label).font(.caption2).bold().foregroundColor(.gray)
            HStack {
                Text(value).font(.system(.body, design: .monospaced))
                Spacer()
                Image(systemName: isSecure ? "eye.slash" : "doc.on.doc")
                    .foregroundColor(.gray)
            }
            .padding()
            .background(Color.white.opacity(0.05))
            .cornerRadius(12)
        }
    }
}
