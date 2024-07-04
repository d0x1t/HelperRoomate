//
//  TextRecognizer.swift
//  Scan-Ocr
//
//   Created by d0x1t on 02/07/2024.
//

import Foundation
import Vision
import VisionKit

final class TextRecognizer {
    let cameraScan: VNDocumentCameraScan
    
    init(cameraScan: VNDocumentCameraScan) {
        self.cameraScan = cameraScan
    }
    
    private let queue = DispatchQueue(label: "scan-codes", qos: .default, attributes: [], autoreleaseFrequency: .workItem)
    
    func recognizeText(withCompletionHandler completionHandler: @escaping ([String]) -> Void) {
        queue.async {
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
                    // Accesso alle informazioni di testo e posizione
                    for observation in sortedObservations {
                        guard let topCandidate = observation.topCandidates(1).first else { continue }
                        let text = topCandidate.string
                        let boundingBox = observation.boundingBox
                        //NOTA: boundingBox.x mi dice la posizione della parte sinistra del box di testo riconosciuta. quindi un valore pari a 0.2 significa che il lato sinistro della bounding box si trova al 20% della larghezza dell'immagine, partendo dal lato sinistro dell'immagine.boundinxBox.y 0.3, significa che il lato superiore della bounding box si trova al 30% dell'altezza dell'immagine, partendo dall'alto dell'immagine.
                        
                        // Stampiamo il testo e la posizione
                        print("Testo: \(text)")
                         print("Posizione (Bounding Box):")
                        print("- Origine X: \(boundingBox.origin.x)")
                        print("- Origine Y: \(boundingBox.origin.y)")
                        print("- Larghezza: \(boundingBox.size.width)")
                        print("- Altezza: \(boundingBox.size.height)")
                        print("----------------")
                    }
                                        return sortedObservations.compactMap { $0.topCandidates(1).first?.string }.joined(separator: "\n")
                                    }  catch {
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
