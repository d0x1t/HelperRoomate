//
//  ContentView.swift
//  Scan-Ocr
//
//  Created by d0x1t on 02/07/2024.
//

import SwiftUI

struct ContentView: View {
    @State private var showScannerSheet = false
    @State private var texts:[ScanData] = []
    var body: some View {
        NavigationView{
            VStack{
                if texts.count > 0{
                    List{
                        ForEach(texts){text in
                            NavigationLink(
                                destination:ScrollView{Text(text.content)},
                                label: {
                                    Text(text.content).lineLimit(1)
                                })
                        }
                    }
                }
                else{
                    Text("No scan yet").font(.title)
                }
            }
                .navigationTitle("Scan OCR")
            //Aggiunge un pulsante sulla destra(trailing)
                .navigationBarItems(trailing: Button(action: {
                    self.showScannerSheet = true
                }, label: {
                    Image(systemName: "doc.text.viewfinder")
                        .font(.title)
                })
                    .sheet(isPresented: $showScannerSheet, content: {
                    self.makeScannerView()
                })
                )
        }
    }
    /* NOTA: textPerPage è un array che contiene tutto il testo di ogni scansione
    questo perche l'app permette di scattare piu foto e poi ottenere la
    scansione di tutte le foto.
    textPerPage[0]->testo della prima foto,
    textPerPage[1]->testo della seconda foto...
     */
    private func makeScannerView()-> ScannerView {
        ScannerView(completion: {
//            Closure: Sto passando al parametro completion una funzione che accetta
              //una array di stringhe e ritorna void
            textPerPage in
            //dobbiamo unire tutte le scansioni fatte. le unisco e come separatore
            //metto un semplice \n
            if let outputText = textPerPage?.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines){
                var newScanData = ScanData(content: outputText)
                newScanData.addLineBreaks()
                self.texts.append(newScanData)
                
            }
            //chiudo lo scanner
            self.showScannerSheet = false
        })
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
