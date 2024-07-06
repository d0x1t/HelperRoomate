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
                    
                    //Calcolo della posizione di inizio iva
                    var minXForIVA: CGFloat = CGFloat.greatestFiniteMagnitude
                    var posizioneYDiPartenzaDettagli:  CGFloat = CGFloat.greatestFiniteMagnitude
                   
                    var primaLettura = true
                                        for observation in sortedObservations {
                                            guard let topCandidate = observation.topCandidates(1).first else { continue }
                                            let text = topCandidate.string
                                            let boundingBox = observation.boundingBox
                                            
                                            if text.contains("%") {
                                                if let _ = text.range(of: #"^\d+%$"#, options: .regularExpression) {
                                                    minXForIVA = min(minXForIVA, boundingBox.origin.x)
                                                    print("Aggiornato minXForIVA a: \(minXForIVA) per testo: \(text)")
                                                }
                                            }
                                        }
                    //******************************************//
                    
                    //Calcolo della posizione di inizio Price
                    var minXForPrice: CGFloat = CGFloat.greatestFiniteMagnitude
                    var minYForPrice: CGFloat = CGFloat.greatestFiniteMagnitude
                    
                                        for observation in sortedObservations {
                                        guard let topCandidate = observation.topCandidates(1).first else { continue }
                                        let text = topCandidate.string
                                        let boundingBox = observation.boundingBox
                                        let coordinataX = observation.boundingBox.origin.x
                        
                                        
                                        if let _ = text.range(of: #"^\d+([.,]\d+)?$"#, options: .regularExpression) {
                                            if(coordinataX > minXForIVA ){
                                                if(primaLettura){
                                                    posizioneYDiPartenzaDettagli = boundingBox.origin.y
                                                    primaLettura = false
                                                }

                                                minYForPrice = min(minYForPrice,boundingBox.origin.y)
                                                minXForPrice = min(minXForPrice, boundingBox.origin.x)
                                                print("Aggiornato minForPrice a: \(minXForIVA) per testo: \(text)")
                                            }
                                            }
                                        
                                    }
                    //******************************************//
                    
                    for observation in sortedObservations {
                        guard let topCandidate = observation.topCandidates(1).first else { continue }
                        var text = topCandidate.string
                        text = text.replacingOccurrences(of: ",", with: ".")
                        let boundingBox = observation.boundingBox
                        let coordinataX = observation.boundingBox.origin.x
                        let coordinataY = observation.boundingBox.origin.y
                        
                        
                     print("Testo: \(text)")
                        print("Posizione (Bounding Box):")
                        print("- Origine X: \(boundingBox.origin.x)")
                        print("- Origine Y: \(boundingBox.origin.y)")
                        print("- Larghezza: \(boundingBox.size.width)")
                        print("- Altezza: \(boundingBox.size.height)")
                        print("----------------")
                        
                        /*    //Controlla se l'espressione corrente matcha il pattern numeri + %
                         if let _ = text.range(of: #"\d+%"#, options: .regularExpression){
                         //Prova a togliere % e converte il numero in intero
                         if let ivaValue = Int(text.trimmingCharacters(in: CharacterSet(charactersIn: "%"))) {
                         self.iva.append(ivaValue)
                         }
                         //prova a fare la conversione del text in double quindi riesce solo se
                         //il text contiene solo un numero
                         } else if let prezzoValue = Double(text) {
                         self.prezzo.append(prezzoValue)
                         } else {
                         
                         self.descrizioni.append(text) // Aggiunge la descrizione all'array descrizioni
                         }
                         }
                         
                         */
                        //Logica per skippare tutte le altre info prima dei dettagli
                       
                        

                        //se sono la descrizione allora la coordinataX è minore del minXForIVA
                        print("I DETTAGLI PARTONO DA")
                        print(posizioneYDiPartenzaDettagli)
                        if(coordinataX < minXForIVA){
                            
                            if(coordinataY > posizioneYDiPartenzaDettagli){
                                continue
                            }
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
                                print("Ho letto una stringa con la percentuale")
                                print(ivaString)
                                
                                // Converti l'IVA da String a Int
                                if let ivaValue = Int(ivaStringWithoutPercent) {
                                    self.iva.append(ivaValue)
                                }
                                
                                // Aggiungi la descrizione
                                self.descrizioni.append((coordinataY, descrizione))
                                continue
                            } else {
                                // Se non viene trovato il simbolo di percentuale, aggiungi l'intero testo come descrizione
                                self.descrizioni.append((coordinataY,text))
                                continue
                            }
                        }

                        
                        //Sono sicuro che la descrizione viene aggiunta prima quindi per essere l'iva allora
                        //la coordinata x è sicuramente minore di quella del prezzo.
                       
                        if(coordinataX < minXForPrice){
                            if let ivaValue = Int(text.trimmingCharacters(in: CharacterSet(charactersIn: "%"))) {
                                self.iva.append(ivaValue)
                                continue
                            }
                        } else if(coordinataX > minXForIVA){
                            if let prezzoValue = Double(text) {
                                self.prezzo.append((coordinataY, prezzoValue))
                                prezzo.sort { $0.0 > $1.0 }
                            }
                        }
                            }
                    //stabilisco l'ordine dei prezzi in base alla cordinata y.
                        
                                                    print("DESCRIZIONI")
                                                    print(descrizioni) // Stampa le descrizioni raccolte
                    print("-----------------------------")
                    print(self.iva)
                                                    print(prezzo)
                    
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
