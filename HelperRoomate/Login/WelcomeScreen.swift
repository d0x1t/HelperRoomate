import SwiftUI

struct WelcomeScreen: View {
    @StateObject var authenticationViewModel = AuthenticationViewModel() // Inizializza AuthenticationViewModel come @StateObject
    
    var colore = Color(red: 57 / 255, green: 128 / 255, blue: 216 / 255)
    
    var body: some View {
        NavigationView {
            ZStack {
                colore.edgesIgnoringSafeArea(.all)
                
                VStack {
                    Spacer()
                    
                    // Immagine con animazione
                    withAnimation(.spring().speed(0.6)) {
                        Image(uiImage: #imageLiteral(resourceName: "iconaLogin"))
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 400, height: 400)
                    }
                    
                    Spacer()
                    
                    HStack {
                        NavigationLink(
                            destination: LoginView().navigationBarHidden(true).environmentObject(authenticationViewModel), // Fornisci authenticationViewModel come environmentObject
                            label: {
                                Text("Sign In")
                                    .font(.title3)
                                    .fontWeight(.bold)
                                    .foregroundColor(colore)
                                    .padding()
                                    .frame(maxWidth: .infinity)
                                    .background(Color.white)
                                    .cornerRadius(10.0)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(colore, lineWidth: 5)
                                    )
                                    .shadow(color: Color.black.opacity(0.08), radius: 60, x: 0.0, y: 16)
                                    .padding(.vertical)
                            })
                            .navigationBarHidden(true)
                        
                        NavigationLink(
                            destination: LoginView().navigationBarHidden(true).environmentObject(authenticationViewModel), // Fornisci authenticationViewModel come environmentObject
                            label: {
                                Text("Registrati")
                                    .font(.title3)
                                    .fontWeight(.bold)
                                    .foregroundColor(Color.white)
                                    .padding()
                                    .frame(maxWidth: .infinity)
                                    .background(colore)
                                    .cornerRadius(10.0)
                                    .shadow(color: Color.black.opacity(0.08), radius: 60, x: 0.0, y: 16)
                                    .padding(.vertical)
                            })
                            .navigationBarHidden(true)
                    }
                    .padding()
                    .padding(.bottom)
                    .background(Color(red: 87 / 255, green: 158 / 255, blue: 236 / 255))
                    .edgesIgnoringSafeArea(.bottom)
                    .cornerRadius(20)
                }
            }
            .edgesIgnoringSafeArea(.bottom)
        }
    }
}

struct WelcomeScreen_Previews: PreviewProvider {
    static var previews: some View {
        WelcomeScreen()
    }
}
