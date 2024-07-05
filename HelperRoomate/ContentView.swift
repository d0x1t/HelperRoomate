//
//  ContentView.swift
//  primaApp
//
//  Created by Studente on 25/06/24.
//

import SwiftUI

struct ContentView: View {
    @State var spese = [
        Spesa(
            nome: "Spesa alimentare",
            categoria: .spesa,
            data: Date(),
            importo: 150.75,
            descrizione: "Spesa settimanale al supermercato",
            descrizioneSpesa: ["Pane": 10.0, "Latte": 15.0, "Carne": 50.0, "Verdura": 25.0, "Frutta": 20.0, "Altro": 30.75],
            pagatoDa: ["Alice", "Bob"],
            divisaTra: ["Alice", "Bob", "Charlie"],
            abitazione: 1
        ),
        Spesa(
            nome: "Bolletta elettrica",
            categoria: .utenza,
            data: Date(),
            importo: 75.20,
            descrizione: "Bolletta del mese di Giugno",
            descrizioneSpesa: ["Consumo": 75.20],
            pagatoDa: ["Alice"],
            divisaTra: ["Alice", "Bob", "Charlie"],
            abitazione: 1
        ),
        Spesa(
            nome: "Riparazione lavatrice",
            categoria: .manutenzione,
            data: Date(),
            importo: 120.00,
            descrizione: "Intervento tecnico per riparare la lavatrice",
            descrizioneSpesa: ["Manodopera": 80.0, "Ricambi": 40.0],
            pagatoDa: ["Charlie"],
            divisaTra: ["Alice", "Bob", "Charlie"],
            abitazione: 1
        ),
        Spesa(
            nome: "Pulizia scale",
            categoria: .generale,
            data: Date(),
            importo: 45.00,
            descrizione: "Pulizia settimanale delle scale condominiali",
            descrizioneSpesa: ["Servizio di pulizia": 45.0],
            pagatoDa: ["Bob"],
            divisaTra: ["Alice", "Bob", "Charlie"],
            abitazione: 1
        ),
        Spesa(
            nome: "Abbonamento internet",
            categoria: .utenza,
            data: Date(),
            importo: 60.00,
            descrizione: "Abbonamento mensile internet",
            descrizioneSpesa: ["Internet": 60.0],
            pagatoDa: ["Alice"],
            divisaTra: ["Alice", "Bob", "Charlie"],
            abitazione: 1
        )
    ]
    
    @State var coinquilini = [
        Coinquilino(nome: "Mario", cognome: "Rossi", username: "mario@example.com", hashedPassword: "1", abitazione: 1),
        Coinquilino(nome: "Giulia", cognome: "Verdi", username: "giulia@example.com", hashedPassword: "1", abitazione: 1),
        Coinquilino(nome: "Luca", cognome: "Bianchi", username: "luca@example.com", hashedPassword: "1", abitazione: 1)
    ]
    
    @State var selection: Int = 0
    var body: some View {
        TabView(selection: $selection) {
            Novita(spese: $spese, coinquilini: $coinquilini)
                .tabItem { Label("Novita", systemImage: "photo")
                    .accentColor(.primary)}
            
                .tag(0)
            Report(spese: $spese, coinquilini: $coinquilini)
                .tabItem { Label("Report", systemImage: "paintpalette")
                        .accentColor(.primary)
                }
                .tag(1)
            AggiungiSpesa(spese: $spese, coinquilini: $coinquilini)
                .tabItem { Label("Aggiungi Spesa", systemImage: "paintpalette")
                        .accentColor(.primary)
                }
                .tag(2)
        }
    }
}
#Preview {
    ContentView()
}
