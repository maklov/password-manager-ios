import SwiftUI

  

struct ContentView: View {

    // Zmienne do przechowywania wpisanych danych (to z nimi będziemy robić szyfrowanie!)

    @State private var email: String = ""

    @State private var password: String = ""

    @State private var rememberEmail: Bool = true

     

    var body: some View {

        // ZStack układa warstwy JEDNA NA DRUGIEJ (Tło -> Efekty -> Formularz)

        ZStack {

            // 1. Tło główne

            Color(red: 0.07, green: 0.07, blue: 0.08)

                .ignoresSafeArea()

             

            // 2. Efekty rozmycia (Figma blurs)

            Circle()

                .fill(Color(red: 0.76, green: 0.76, blue: 1).opacity(0.10))

                .frame(width: 300)

                .offset(x: -150, y: -350)

                .blur(radius: 120)

             

            Circle()

                .fill(Color(red: 0.51, green: 0.51, blue: 1).opacity(0.05))

                .frame(width: 250)

                .offset(x: 150, y: 350)

                .blur(radius: 100)

             

            // 3. Główny formularz

            VStack(alignment: .leading, spacing: 40) {

                 

                // Sekcja Nagłówka

                VStack(alignment: .leading, spacing: 8) {

                    // Miejsce na logo

                    RoundedRectangle(cornerRadius: 16)

                        .fill(Color(red: 0.16, green: 0.16, blue: 0.17))

                        .frame(width: 64, height: 64)

                        .overlay(

                            RoundedRectangle(cornerRadius: 16)

                                .stroke(Color(red: 0.76, green: 0.76, blue: 1).opacity(0.15), lineWidth: 0.5)

                        )

                        .shadow(color: Color.black.opacity(0.25), radius: 50, y: 25)

                        .padding(.bottom, 16)

                     

                    Text("Vault Sentinel")

                        .font(.system(size: 30, weight: .heavy, design: .default))

                        .foregroundColor(Color(red: 0.89, green: 0.89, blue: 0.89))

                     

                    Text("Welcome back")

                        .font(.system(size: 16, weight: .light, design: .default))

                        .foregroundColor(Color(red: 0.76, green: 0.78, blue: 0.84))

                }

                 

                // Sekcja Pól Tekstowych

                VStack(alignment: .leading, spacing: 24) {

                     

                    // Pole Email

                    VStack(alignment: .leading, spacing: 8) {

                        Text("Email address")

                            .font(.system(size: 11, weight: .medium))

                            .tracking(1.1)

                            .foregroundColor(Color(red: 0.76, green: 0.78, blue: 0.84))

                         

                        TextField("name@domain.com", text: $email)

                            .padding()

                            .background(Color(red: 0.16, green: 0.16, blue: 0.17))

                            .cornerRadius(12)

                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color(red: 0.76, green: 0.76, blue: 1).opacity(0.15), lineWidth: 0.5))

                            .foregroundColor(.white)

                            .keyboardType(.emailAddress)

                            .autocapitalization(.none)

                    }

                     

                    // Pole Hasło

                    VStack(alignment: .leading, spacing: 8) {

                        Text("Account Password")

                            .font(.system(size: 11, weight: .medium))

                            .tracking(1.1)

                            .foregroundColor(Color(red: 0.76, green: 0.78, blue: 0.84))

                         

                        SecureField("••••••••", text: $password)

                            .padding()

                            .background(Color(red: 0.16, green: 0.16, blue: 0.17))

                            .cornerRadius(12)

                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color(red: 0.76, green: 0.76, blue: 1).opacity(0.15), lineWidth: 0.5))

                            .foregroundColor(.white)

                    }

                     

                    // Opcje (Remember / Forgot)

                    HStack {

                        Toggle(isOn: $rememberEmail) {

                            Text("Remember my email")

                                .font(.system(size: 14, weight: .medium))

                                .foregroundColor(Color(red: 0.76, green: 0.78, blue: 0.84))

                        }

                        .toggleStyle(SwitchToggleStyle(tint: Color(red: 0.51, green: 0.51, blue: 1)))

                         

                        Spacer()

                         

                        Button("Forgot password?") {

                            print("Kliknięto przypomnienie hasła")

                        }

                        .font(.system(size: 14, weight: .semibold))

                        .foregroundColor(Color(red: 0.76, green: 0.76, blue: 1))

                    }

                }

                 

                // Przycisk "Next"

                Button(action: {

                    print("Rozpoczynam logowanie dla: \(email)")

                    // TUTAJ DODAMY LOGIKĘ KRYPTOGRAFICZNĄ!

                }) {

                    Text("Next")

                        .font(.system(size: 16, weight: .bold))

                        .foregroundColor(Color(red: 0.08, green: 0, blue: 0.58))

                        .frame(maxWidth: .infinity)

                        .padding(.vertical, 16)

                        .background(Color(red: 0.51, green: 0.51, blue: 1))

                        .cornerRadius(12)

                        .shadow(color: Color(red: 0.51, green: 0.51, blue: 1).opacity(0.2), radius: 24, y: 8)

                }

                 

                Spacer() // Spychamy wszystko do góry, a stempel AES na dół

                 

                // Stempel szyfrowania na dole

                HStack {

                    Spacer()

                    HStack(spacing: 8) {

                        Circle()

                            .fill(Color(red: 0.76, green: 0.76, blue: 1))

                            .frame(width: 6, height: 6)

                            .shadow(color: Color(red: 0.76, green: 0.76, blue: 1), radius: 8)

                         

                        Text("ENCRYPTED VIA AES-256 BIT")

                            .font(.system(size: 11, weight: .medium))

                            .tracking(0.55)

                            .foregroundColor(Color(red: 0.76, green: 0.78, blue: 0.84))

                    }

                    .padding(.horizontal, 16)

                    .padding(.vertical, 8)

                    .background(Color(red: 0.11, green: 0.11, blue: 0.11))

                    .cornerRadius(9999)

                    .overlay(

                        RoundedRectangle(cornerRadius: 9999)

                            .stroke(Color(red: 0.76, green: 0.76, blue: 1).opacity(0.15), lineWidth: 0.5)

                    )

                    Spacer()

                }

            }

            .padding(32)

        }

    }

}

  

struct ContentView_Previews: PreviewProvider {

    static var previews: some View {

        ContentView()

    }

} 
