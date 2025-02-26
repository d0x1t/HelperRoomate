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
    var descrizioni: [String]
    var iva: [Int]
    var prezzo: [Double]
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
                    
                    var minXForIVA: CGFloat = CGFloat.greatestFiniteMagnitude
                                        for observation in sortedObservations {
                                            guard let topCandidate = observation.topCandidates(1).first else { continue }
                                            let text = topCandidate.string
                                            let boundingBox = observation.boundingBox
                                            
                                            if text.contains("%") {
                                                if let _ = text.range(of: #"^\d+%$"#    , options: .regularExpression) {
                                                    minXForIVA = min(minXForIVA, boundingBox.origin.x)
                                                    print("Aggiornato minXForIVA a: \(minXForIVA) per testo: \(text)")
                                                }
                                            }
                                        }
                    var minXForPrice: CGFloat = CGFloat.greatestFiniteMagnitude
                                        for observation in sortedObservations {
                                        guard let topCandidate = observation.topCandidates(1).first else { continue }
                                        let text = topCandidate.string
                                        let boundingBox = observation.boundingBox
                        
                                        
                                        if let _ = text.range(of: #"^\d+([.,]\d+)?%$"#, options: .regularExpression) {
                                        minXForPrice = min(minXForIVA, boundingBox.origin.x)
                                        print("Aggiornato maxForPrice a: \(minXForIVA) per testo: \(text)")
                                            }
                                        
                                    }
                                       for observation in sortedObservations {
                                           guard let topCandidate = observation.topCandidates(1).first else { continue }
                                           var text = topCandidate.string
                                           text = text.replacingOccurrences(of: ",", with: ".")
                                           let boundingBox = observation.boundingBox
                                        
                                           
                                           print("Testo: \(text)")
                                           print("Posizione (Bounding Box):")
                                           print("- Origine X: \(boundingBox.origin.x)")
                                           print("- Origine Y: \(boundingBox.origin.y)")
                                           print("- Larghezza: \(boundingBox.size.width)")
                                           print("- Altezza: \(boundingBox.size.height)")
                                           print("----------------")
                                           
                                           //Controlla se l'espressione corrente matcha il pattern numeri + %
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
                                       
                                       
                                                    print(descrizioni) // Stampa le descrizioni raccolte
                                                    print(iva)
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
