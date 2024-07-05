//
//  Novita.swift
//  HelperRoomate
//
//  Created by Studente on 05/07/24.
//

import SwiftUI

struct Novita: View {
    @Binding var spese: [Spesa]
    @Binding var coinquilini: [Coinquilino]
    
    var body: some View {
        NavigationView { // Aggiungi NavigationView qui
            VStack{
                List{
                    ForEach($coinquilini, id: \.username){ $coinquilino in
                        NavigationLink(destination: Report(spese: $spese, coinquilini: $coinquilini)){
                            Circle()
                                .fill(Color.blue) // Colore del cerchio
                                .frame(width: 100, height: 100) // Dimensioni del cerchio
                            Text(coinquilino.nome.prefix(1).uppercased())
                                .font(.largeTitle) // Dimensione del testo
                                .foregroundColor(.white) // Colore del testo
                        }
                    }
                }
                .navigationTitle("Immagini")
                .navigationBarTitleDisplayMode(.large)
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Novità") // Aggiungi un titolo di navigazione
            .toolbar{
                ToolbarItem(placement: .navigationBarTrailing){ // Usa .navigationBarTrailing invece di .topBarTrailing
                    Button(action: {
                        // Aggiungi la tua azione qui
                        print("Salva button pressed")
                    }) {
                        Text("Salva")
                    }
                }
            }
        }
    }
}

#Preview {
    // Provide a sample binding for preview
    Novita(spese: .constant([Spesa]()), coinquilini: .constant([Coinquilino]()))
}
