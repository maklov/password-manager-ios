import SwiftUI

struct WelcomeView: View {
    var onLogin: () -> Void
    var onRegister: () -> Void
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            // Ikona kłódki z poświatą
            ZStack {
                Circle()
                    .fill(Color(red: 0.51, green: 0.51, blue: 1).opacity(0.1))
                    .frame(width: 200, height: 200)
                    .blur(radius: 20)
                
                RoundedRectangle(cornerRadius: 40)
                    .fill(Color(red: 0.12, green: 0.12, blue: 0.13))
                    .frame(width: 140, height: 140)
                    .overlay(
                        Image(systemName: "lock.fill")
                            .font(.system(size: 60))
                            .foregroundColor(Color(red: 0.76, green: 0.76, blue: 1))
                    )
            }
            
            VStack(spacing: 12) {
                Text("Welcome to\nyour digital\nsanctuary.")
                    .font(.system(size: 42, weight: .heavy))
                    .multilineTextAlignment(.center)
                    .foregroundColor(.white)
                
                Text("FORTIFIED BY MILITARY-GRADE ENCRYPTION")
                    .font(.system(size: 10, weight: .bold))
                    .tracking(1.5)
                    .foregroundColor(.gray)
            }
            
            // Status systemu
            VStack(alignment: .leading, spacing: 12) {
                Text("SYSTEM STATUS")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.gray)
                HStack {
                    Text("Maximum Security")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                    Spacer()
                    Capsule()
                        .fill(LinearGradient(colors: [Color.blue, Color.purple], startPoint: .leading, endPoint: .trailing))
                        .frame(width: 80, height: 8)
                }
            }
            .padding()
            .background(Color.white.opacity(0.05))
            .cornerRadius(16)
            .padding(.horizontal, 24)
            
            Spacer()
            
            // Przyciski akcji
            VStack(spacing: 16) {
                Button(action: onRegister) {
                    Label("Create New Vault", systemImage: "shield.fill")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(red: 0.51, green: 0.51, blue: 1))
                        .foregroundColor(.black)
                        .cornerRadius(16)
                }
                
                Button(action: onLogin) {
                    Label("Enter Existing Vault", systemImage: "key.fill")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.white.opacity(0.05))
                        .foregroundColor(.white)
                        .cornerRadius(16)
                        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.1)))
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
    }
}
