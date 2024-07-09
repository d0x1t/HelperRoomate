//
//  TextRecognizer.swift
//  Scan-Ocr
//
//  Created by d0x1t on 02/07/2024.
//

import Foundation
import Vision
import VisionKit

final class TextRecognizer {
    var descrizioni: [(Double,String)]
    var iva: [Int]
    var prezzo: [(Double, Double)]
    let cameraScan: VNDocumentCameraScan
    var arrayContenitore: [Double: (descrizione: String, iva: Int, prezzo: Double)]
    
    init(cameraScan: VNDocumentCameraScan) {
        self.cameraScan = cameraScan
        self.arrayContenitore = [:] // Inizializziamo con un dizionario vuoto
        self.iva = []
        self.descrizioni = []
        self.prezzo = []
    }
    
    private let queue = DispatchQueue(label: "scan-codes", qos: .default, attributes: [], autoreleaseFrequency: .workItem)
    
    func recognizeText(withCompletionHandler completionHandler: @escaping ([String]) -> Void) {
        
        queue.async { [self] in
            //(0..<self.cameraScan.pageCount) creo un intervallo da 0 al numero di
            //foto scattate
            //compactMap itera attraverso l'intervallo, saltando i nil e applica la funzione
            //ad ogni valore
            let images = (0..<self.cameraScan.pageCount).compactMap({
                //$0 rappresenta l'indice corrente.
                //cgImage trasforma l'elemento VNDocumentCameraScan in un
                //CGImage
                self.cameraScan.imageOfPage(at: $0).cgImage
            })
            
            //map è una funzione di trasformazione che prende l'array di soli CGImage e associa ad ogni immagine una richiesta di VNRecognizeTextRequest() quindi si avrà questo array
            //[(image1, request1), (image2, request2), ..., (imageN, requestN)]
            let imagesAndRequests = images.map({ (image: $0, request: VNRecognizeTextRequest()) })
            
            //con map si applica la funzione seguente a ciascuna tupla (image, request) che trasforma il tutto in una stringa
            let textPerPage = imagesAndRequests.map { image, request -> String in
                //VNImageRequestHandler gestisce tutte le richieste legate ad una specifica immagine.
                let handler = VNImageRequestHandler(cgImage: image, options: [:])
                do {
                    //si esegue la richiesta viene utilizzata la struttura do-try-catch per gestire eventuali errori durante l'esecuzione della richiesta.
                    try handler.perform([request])
                    //in observations se tutto va bene viene salvato l'oggetto VNRecognizedTextObservation che rappresenta un pezzo di testo riconosciuto dalla foto, NOTA: siccome una foto può essere frammentata in più pezzi allora observation è un array di VNRecognizedTextObservation, in caso di errori si ritorna la stringa vuota.
                    guard let observations = request.results else { return "" }
                    
                    //per ogni VNRecognizedTextObservation contenuto nell'array observations viene eseguita la funzione di compactMap (funziona come map solo che salta i nil) siccome siamo in un iteratore $0 significa elemento corrente. topCandidates(1) è un metodo di VNRecognizedTextObservation che restituisce un array dei migliori candidati di testo riconosciuto, ordinati per affidabilità. ci andiamo a prendere il 1 array e poi con first prendiamo il primo elemento dell'array e restituiamo la stringa. siccome compactMap itera su più elementi dell'array perché una foto è composta da molti pezzi di testo joined unisce tutti gli elementi con lo spazio.
                    //NUOVA AGGIUNTA. Mi sono accorto che ogni frammento letto veniva poi recuperato in modo casuale facendo cosi si inizia a fare la scansione dall'alto verso il basso e soprattutto da sinistra verso destra.
                    let sortedObservations = observations.sorted {
                        if $0.boundingBox.origin.y == $1.boundingBox.origin.y {
                            return $0.boundingBox.origin.x < $1.boundingBox.origin.x
                        } else {
                            return $0.boundingBox.origin.y > $1.boundingBox.origin.y
                        }
                    }
                    
                    //Calcolo della posizione di inizio IVA e fine dettagli
                    var minXForIVA: CGFloat = CGFloat.greatestFiniteMagnitude
                    var posizioneYDiFineDettagli: CGFloat = CGFloat.greatestFiniteMagnitude
                    var primaLettura = true
                    for observation in sortedObservations {
                        guard let topCandidate = observation.topCandidates(1).first else { continue }
                        var text = topCandidate.string
                                            
                        let boundingBox = observation.boundingBox
                                        
                        if text.contains("%") {
                            text = text.replacingOccurrences(of: ",", with: ".")
                            posizioneYDiFineDettagli = boundingBox.origin.y
                            
                            if let _ = text.range(of: "^\\d+(\\.\\d+)?%$", options: .regularExpression) {
                                
                                minXForIVA = min(minXForIVA, boundingBox.origin.x)
                                print("Aggiornato minXForIVA a: \(minXForIVA) per testo: \(text)")
                            }
                        }
                    }
                    //******************************************//
                    
                    //Calcolo della posizione di inizio PRICE e inizio dettagli
                    var minXForPrice: CGFloat = CGFloat.greatestFiniteMagnitude
                    
                    var posizioneYDiPartenzaDettagli:  CGFloat = CGFloat.greatestFiniteMagnitude
                    var altezzaDelPrimoPrezzo: Double = 0.00
                    var altezzaDelTotale: Double = 0.00
                    var possibiliTotali: [Double] = []
                    for observation in sortedObservations {
                        guard let topCandidate = observation.topCandidates(1).first else { continue }
                        var text = topCandidate.string
                        let boundingBox = observation.boundingBox
                        let coordinataX = observation.boundingBox.origin.x
                        
                            if let _ = text.range(of: #"^\d+([.,]\d+)?$"#, options: .regularExpression) {
                                let larghezzaNumero = boundingBox.size.width
                                let altezzaNumero = boundingBox.size.height
                                
                                            
                                if(coordinataX > minXForIVA ){
                                    if((larghezzaNumero + altezzaNumero) > altezzaDelTotale){
                                        altezzaDelTotale = larghezzaNumero + altezzaNumero
                                        text = text.replacingOccurrences(of: ",", with: ".")
                                        
                                        if let possibilePrezzoTotale = Double(text){
                                        possibiliTotali.append(possibilePrezzoTotale)
                                        }
                                    }

                                    if(primaLettura){
                                        posizioneYDiPartenzaDettagli = boundingBox.origin.y
                                        altezzaDelPrimoPrezzo = boundingBox.size.height
                                        primaLettura = false
                                    }
                                    minXForPrice = min(minXForPrice, boundingBox.origin.x)
                                }
                            }
                                        
                        }
                    //******************************************//
                    
                    //BEGIN.
                    //Prelevo le Descrizioni, IVA e Prezzo per inserirli negli appositi Array
                    for observation in sortedObservations {
                        guard let topCandidate = observation.topCandidates(1).first else { continue }
                        var text = topCandidate.string
                        text = text.replacingOccurrences(of: ",", with: ".")
                        _ = observation.boundingBox
                        let coordinataX = observation.boundingBox.origin.x
                        let coordinataY = observation.boundingBox.origin.y


                        //Logica per skippare tutte le altre info DOPO i dettagli
                        if(coordinataY < posizioneYDiFineDettagli - 0.009){
                            continue
                        }
                        //Logica per skippare tutte le altre info PRIMA dei dettagli
                        //NOTA: per alcuni scontrini il titolo descrizione viene incluso come se fosse un prodotto.
                        if(coordinataY > (posizioneYDiPartenzaDettagli + altezzaDelPrimoPrezzo)){
                            continue
                        }
                        
                        //Logica per prelevare la DESCRIZIONE.
                        if(coordinataX < minXForIVA){
                            // Controlla se il testo contiene il simbolo di percentuale
                            if let percentRange = text.range(of: "%", options: .backwards) {
                                // Trova il punto in cui inizia la descrizione (ultimo spazio bianco prima del numero percentuale)
                                var endIndex = percentRange.lowerBound
                                while endIndex > text.startIndex && !text[endIndex].isWhitespace {
                                    endIndex = text.index(before: endIndex)
                                }
                                
                                // Estrai la descrizione e l'IVA
                                let descrizione = String(text[text.startIndex..<endIndex]).trimmingCharacters(in: .whitespaces)
                                let ivaString = String(text[text.index(after: endIndex)..<percentRange.upperBound]).trimmingCharacters(in: .whitespaces)
                                let ivaStringWithoutPercent = ivaString.replacingOccurrences(of: "%", with: "")
                                
                                
                                if let ivaValue = Int(ivaStringWithoutPercent) {
                                    self.iva.append(ivaValue)
                                }
                                self.descrizioni.append((coordinataY, descrizione))
                                continue
                        } else {
                                // Se non viene trovato il simbolo di percentuale, aggiungi l'intero testo come descrizione
                                self.descrizioni.append((coordinataY,text))
                                continue
                            }
                        }
                        //FINE: ho inserito correttamente la descrizione nell'array

                        
                        
                       //LOGICA: la descrizione è prelevata con la logica precedente, quindi sono sicuro che tutto quello che
                        //       sta prima del prezzo è l'IVA
                        if(coordinataX < minXForPrice){
                            if let ivaValue = Int(text.trimmingCharacters(in: CharacterSet(charactersIn: "%"))) {
                                self.iva.append(ivaValue)
                                continue
                            }
                            
                        }
                        //Se non è IVA allora sicuro è il Prezzo
                        else if(coordinataX > minXForIVA){
                            if let prezzoValue = Double(text) {
                                self.prezzo.append((coordinataY, prezzoValue))
                                prezzo.sort { $0.0 > $1.0 }
                            }
                        }
                        
                    }//COMMIT For
                    
                    //UNISCO GLI ARRAY ->

                    var risultato: [(String, Double)] = []

                    // Calcola la differenza media dei primi valori (coordinate x)
                    var sommaDeltaY: Double = 0.0
                    
                    if(prezzo.count == 0){
                        return sortedObservations.compactMap { $0.topCandidates(1).first?.string }.joined(separator: "\n")
                    }
                    if(prezzo.count == 1){
                        risultato.append((self.descrizioni[0].1,self.prezzo[0].1))
                        risultato.append(("TOTALE COMPLESSIVO", possibiliTotali.max()!))
                    }else{
                        
                        for i in 0..<prezzo.count - 1 {
                            let y1 = prezzo[i].0
                            let y2 = prezzo[i + 1].0
                            let deltaY = abs(y2 - y1)
                            sommaDeltaY += deltaY
                        }
                        
                        let deltaYMedio = sommaDeltaY / Double(prezzo.count - 1)
                        
                        print("Differenza media dei primi valori (Delta Y medio):", deltaYMedio)
                        
                        // Imposta la soglia uguale alla media delle differenze
                        let soglia = deltaYMedio * 1.5
                        
                        // Itera attraverso l'array prezzo e confronta ogni coppia di valori con la soglia
                        let numeroDettagli = prezzo.count
                        for i in 0..<numeroDettagli - 1{
                            let x1 = prezzo[i].0
                            let x2 = prezzo[i + 1].0
                            let differenza = abs(x2 - x1)
                            
                            if differenza > soglia {
                                //Questa logica puo essere utile se ci sono due righe di descrizione
                                var stringa1 = descrizioni[i].1
                                let stringa2 = descrizioni[i+1].1
                                stringa1.append(" " + stringa2)
                                descrizioni.remove(at: i+1)
                                risultato.append((stringa1,self.prezzo[i].1))
                                print("C'è più spazio tra", x1, "e", x2)
                            } else {
                                risultato.append((self.descrizioni[i].1, self.prezzo[i].1))
                                print("Non c'è più spazio tra", x1, "e", x2)
                            }
                        }
                        
                        //siccome sopra faccion il confronto a due a due e inserisco il primo succede che l'ultimo elemento non viene aggiunto quindi lo faccio ora
                        if numeroDettagli > 0 && numeroDettagli <= self.descrizioni.count && numeroDettagli <= self.prezzo.count {
                            risultato.append((self.descrizioni[numeroDettagli-1].1, self.prezzo[numeroDettagli-1].1))
                        }
                        risultato.append(("TOTALE COMPLESSIVO", possibiliTotali.max()!))
                    }
                                                    
                   print("DESCRIZIONI")
                   print(descrizioni)
                   print("-----------------------------")
                   print(self.iva)
                   print(prezzo)
                   print("UNSCO GLI ARRAY")
                   print(risultato)

                    return sortedObservations.compactMap { $0.topCandidates(1).first?.string }.joined(separator: "\n")
                    
                } catch {
                    print(error)
                    return ""
                }
            }
            
            DispatchQueue.main.async {
                completionHandler(textPerPage)
            }
        }
    }
}
