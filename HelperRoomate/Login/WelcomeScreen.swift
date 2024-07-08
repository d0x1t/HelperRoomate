//
//  WelcomeScreenView.swift
//  login
//
//  Created by Abu Anwar MD Abdullah on 23/4/21.
//

import SwiftUI

struct Login: View {
    var colore = Color(red: 57 / 255, green: 128 / 255, blue: 216 / 255)
    var body: some View {
        NavigationView {
            ZStack {
                
                    
                // Background color matching the image's background
                colore.edgesIgnoringSafeArea(/*@START_MENU_TOKEN@*/.all/*@END_MENU_TOKEN@*/)
                
                VStack {
                    
                    Spacer()
                    
                    withAnimation(.spring().speed(0.6)) {
                                  Image(uiImage: #imageLiteral(resourceName: "iconaLogin"))
                                      .resizable()
                                      .aspectRatio(contentMode: .fit)  // Mantieni l'aspect ratio per adattarsi al frame
                                      .frame(width: 400, height: 400)
                              }
                    Spacer()
                    
           
                    
                    HStack {
                        NavigationLink(
                            destination: ContentView().navigationBarHidden(true),
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
                                               .stroke(colore, lineWidth: 5) // Colore del bordo e larghezza del bordo
                                       )
                                    .shadow(color: Color.black.opacity(0.08), radius: 60, x: 0.0, y: 16)
                                    .padding(.vertical)
                            })
                            .navigationBarHidden(true)
                        
                        NavigationLink(
                            destination: ContentView().navigationBarHidden(true),
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
                    .background(Color(red: 87 / 255, green: 158 / 255, blue: 236 / 255)).edgesIgnoringSafeArea(.bottom)
                    .cornerRadius(20)
                    
                }
            }.edgesIgnoringSafeArea(.bottom)
        }
    }
}

struct Login_Previews: PreviewProvider {
    static var previews: some View {
        Login()
    }
}
