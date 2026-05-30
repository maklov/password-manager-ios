import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var navState: AppNavigationState
    @EnvironmentObject var authManager: AuthManager
    
    // @AppStorage automatycznie zapisuje te dane na stałe w pamięci urządzenia
    @AppStorage("profile_first_name") private var firstName: String = "John"
    @AppStorage("profile_last_name") private var lastName: String = "Doe"
    @AppStorage("profile_email") private var email: String = "john.doe@example.com"
    
    // Stany do obsługi trybu edycji
    @State private var isEditing: Bool = false
    @State private var editFirstName: String = ""
    @State private var editLastName: String = ""
    @State private var editEmail: String = ""
    
    // Dynamicznie generowane inicjały do awatara
    private var initials: String {
        let first = firstName.prefix(1)
        let last = lastName.prefix(1)
        return "\(first)\(last)".uppercased()
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.07, green: 0.07, blue: 0.08).ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 32) {
                        
                        // --- HEADER / AVATAR ---
                        VStack(spacing: 16) {
                            ZStack {
                                Circle()
                                    .fill(Color(red: 0.51, green: 0.51, blue: 1).opacity(0.15))
                                    .frame(width: 96, height: 96)
                                
                                Text(initials)
                                    .font(.system(size: 36, weight: .black, design: .rounded))
                                    .foregroundColor(Color(red: 0.51, green: 0.51, blue: 1))
                            }
                            
                            VStack(spacing: 6) {
                                Text("\(firstName) \(lastName)")
                                    .font(.system(size: 24, weight: .bold))
                                    .foregroundColor(.white)
                                
                                Text(email)
                                    .font(.system(size: 14))
                                    .foregroundColor(.gray)
                            }
                        }
                        .padding(.top, 24)
                        
                        // --- PERSONAL INFORMATION ---
                        VStack(alignment: .leading, spacing: 12) {
                            Text("PERSONAL INFORMATION")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(.gray)
                                .padding(.leading, 16)
                            
                            VStack(spacing: 0) {
                                ProfileRow(label: "First Name", value: $editFirstName, isEditing: isEditing)
                                Divider().background(Color.white.opacity(0.05)).padding(.leading, 16)
                                
                                ProfileRow(label: "Last Name", value: $editLastName, isEditing: isEditing)
                                Divider().background(Color.white.opacity(0.05)).padding(.leading, 16)
                                
                                ProfileRow(label: "Email", value: $editEmail, isEditing: isEditing, isEmail: true)
                            }
                            .background(Color(red: 0.12, green: 0.12, blue: 0.13))
                            .cornerRadius(16)
                        }
                        
                        // --- LOG OUT BUTTON ---
                        Button(action: {
                            performLogout()
                        }) {
                            HStack {
                                Image(systemName: "rectangle.portrait.and.arrow.right")
                                Text("Log Out")
                            }
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.red)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color(red: 0.12, green: 0.12, blue: 0.13))
                            .cornerRadius(16)
                        }
                        .padding(.top, 16)
                    }
                    .padding(24)
                }
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(isEditing ? "Save" : "Edit") {
                        if isEditing {
                            saveChanges()
                        } else {
                            prepareForEditing()
                        }
                    }
                    .foregroundColor(Color(red: 0.51, green: 0.51, blue: 1))
                    .font(.system(size: 16, weight: .bold))
                }
            }
            // Automatyczne załadowanie danych do pól tymczasowych, gdyby użytkownik chciał edytować
            .onAppear {
                prepareForEditing()
            }
        }
    }
    
    // MARK: - Logic Helpers
    
    private func prepareForEditing() {
        editFirstName = firstName
        editLastName = lastName
        editEmail = email
        withAnimation { isEditing = true }
    }
    
    private func saveChanges() {
        // Zapis z powrotem do @AppStorage
        firstName = editFirstName
        lastName = editLastName
        email = editEmail
        withAnimation { isEditing = false }
    }
    
    private func performLogout() {
        authManager.logout()
        navState.currentRoute = .welcome
    }
}

struct ProfileRow: View {
    let label: String
    @Binding var value: String
    let isEditing: Bool
    var isEmail: Bool = false
    
    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 14))
                .foregroundColor(.gray)
                .frame(width: 90, alignment: .leading)
            
            if isEditing {
                TextField(label, text: $value)
                    .font(.system(size: 16))
                    .foregroundColor(.white)
                    .autocapitalization(isEmail ? .none : .words)
                    .keyboardType(isEmail ? .emailAddress : .default)
                    .disableAutocorrection(isEmail)
            } else {
                Text(value)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
            }
            
            Spacer()
        }
        .padding()
        .frame(height: 56)
    }
}
