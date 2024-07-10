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
    var description: [(Double,String)]
    var iva: [Int]
    var price: [(Double, Double)]
    let cameraScan: VNDocumentCameraScan
    var result: [(String, Double)]
    
    
    init(cameraScan: VNDocumentCameraScan) {
        self.cameraScan = cameraScan
        self.result = []
        self.iva = []
        self.description = []
        self.price = []
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
            
            //con map si applica la funzione seguente a ciascuna tupla (image, request) che trasforma il tutto in una string
            let textPerPage = imagesAndRequests.map { image, request -> String in
                //VNImageRequestHandler gestisce tutte le richieste legate ad una specifica immagine.
                let handler = VNImageRequestHandler(cgImage: image, options: [:])
                do {
                    //si esegue la richiesta viene utilizzata la struttura do-try-catch per gestire eventuali errori durante l'esecuzione della richiesta.
                    try handler.perform([request])
                    //in observations se tutto va bene viene salvato l'oggetto VNRecognizedTextObservation che rappresenta un pezzo di testo riconosciuto dalla foto, NOTA: siccome una foto può essere frammentata in più pezzi allora observation è un array di VNRecognizedTextObservation, in caso di errori si ritorna la string vuota.
                    guard let observations = request.results else { return "" }
                    
                    //per ogni VNRecognizedTextObservation contenuto nell'array observations viene eseguita la funzione di compactMap (funziona come map solo che salta i nil) siccome siamo in un iteratore $0 significa elemento corrente. topCandidates(1) è un metodo di VNRecognizedTextObservation che restituisce un array dei migliori candidati di testo riconosciuto, ordinati per affidabilità. ci andiamo a prendere il 1 array e poi con first prendiamo il primo elemento dell'array e restituiamo la string. siccome compactMap itera su più elementi dell'array perché una foto è composta da molti pezzi di testo joined unisce tutti gli elementi con lo spazio.
                    //NUOVA AGGIUNTA. Mi sono accorto che ogni frammento letto veniva poi recuperato in modo casuale facendo cosi si inizia a fare la scansione dall'alto verso il basso e soprattutto da sinistra verso destra.
                    let sortedObservations = observations.sorted {
                        if $0.boundingBox.origin.y == $1.boundingBox.origin.y {
                            return $0.boundingBox.origin.x < $1.boundingBox.origin.x
                        } else {
                            return $0.boundingBox.origin.y > $1.boundingBox.origin.y
                        }
                    }
                    
                    //MARK: variabili per il totale
                    var positionYTotal: Double = 0.00
                    var heightTotal: Double = 0.00
                    
                    
                    var minXForIVA: CGFloat = CGFloat.greatestFiniteMagnitude
                    var positionYEndDetails: CGFloat = CGFloat.greatestFiniteMagnitude
                    var existsIva = false
                    for observation in sortedObservations {
                        guard let topCandidate = observation.topCandidates(1).first else { continue }
                        var text = topCandidate.string
                        let boundingBox = observation.boundingBox
                        
                        if(text.lowercased().contains("totale complessivo")){
                            
                            positionYTotal = boundingBox.origin.y
                            heightTotal = boundingBox.size.height
                        }
                        
                        
                        
                        if text.contains("%") {
                            text = text.replacingOccurrences(of: ",", with: ".")
                            positionYEndDetails = boundingBox.origin.y
                            
                            if let _ = text.range(of: "^\\d+(\\.\\d+)?%$", options: .regularExpression) {
                                existsIva = true
                                minXForIVA = min(minXForIVA, boundingBox.origin.x)
                                print("Aggiornato minXForIVA a: \(minXForIVA) per testo: \(text)")
                            }
                        }
                    }
                    //******************************************//
                    if(existsIva){
                        //Calcolo della posizione di inizio PRICE e inizio dettagli
                        var minXForPrice: CGFloat = CGFloat.greatestFiniteMagnitude
                        var positionYStartDetails:  CGFloat = CGFloat.greatestFiniteMagnitude
                        var heightOfFirstPrice: Double = 0.00
                        var TotalHeight: Double = 0.00
                        var possibiliTotali: [Double] = []
                        var firstRead = true
                        for observation in sortedObservations {
                            guard let topCandidate = observation.topCandidates(1).first else { continue }
                            var text = topCandidate.string
                            let boundingBox = observation.boundingBox
                            let coordinateX = observation.boundingBox.origin.x
                            
                            if let _ = text.range(of: #"^\d+([.,]\d+)?$"#, options: .regularExpression) {
                                let widthNumber = boundingBox.size.width
                                let heightNumber = boundingBox.size.height
                                
                                
                                if(coordinateX > minXForIVA ){
                                    if((widthNumber + heightNumber) > TotalHeight){
                                        TotalHeight = widthNumber + heightNumber
                                        text = text.replacingOccurrences(of: ",", with: ".")
                                        
                                        if let possibilePrezzoTotale = Double(text){
                                            possibiliTotali.append(possibilePrezzoTotale)
                                        }
                                    }
                                    
                                    if(firstRead){
                                        positionYStartDetails = boundingBox.origin.y
                                        heightOfFirstPrice = boundingBox.size.height
                                        firstRead = false
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
                            let coordinateX = observation.boundingBox.origin.x
                            let coordinateY = observation.boundingBox.origin.y
                            
                            
                            //Logica per skippare tutte le altre info DOPO i dettagli
                            if(coordinateY < (positionYEndDetails - heightOfFirstPrice * 2.0)){
                                continue
                            }
                            
                            //Logica per skippare tutte le altre info PRIMA dei dettagli
                            if(coordinateY > (positionYStartDetails + heightOfFirstPrice)){
                                continue
                            }
                            //Logica per skippare l'intestazione dei prodotti
                            if(text.lowercased().contains("descrizione") || text.lowercased().contains("iva") || text.lowercased().contains("prezzo")){
                                continue
                            }
                            
                            //Inserisco la description
                            if(coordinateX < minXForIVA){
                                setDescription(text: text, coordinateY: coordinateY)
                            }
                            
                            if(coordinateX < minXForPrice && coordinateX > minXForIVA){
                                setIva(text: text)
                                
                            } else if(coordinateX > minXForIVA){
                                setPrice(text:text,coordinateY: coordinateY)
                            }
                            
                        }//FOR
                        //CASO LIMITE 1: Scontrino senza %
                        if(price.count == 0){
                            return sortedObservations.compactMap { $0.topCandidates(1).first?.string }.joined(separator: "\n")
                        }
                        //CASO LIMITE 2: Solo un prodotto acquistato.
                        if(price.count == 1){
                            self.result.append((self.description[0].1,self.price[0].1))
                            self.result.append(("TOTALE COMPLESSIVO", possibiliTotali.max()!))
                            
                        }else{
                            
                            let theshold = averageSpaceProducts() * 1.5
                            joinArrays(theshold: theshold)
                            result.append(("TOTALE COMPLESSIVO", possibiliTotali.max()!))
                        }
                        
                        return result.map { "\($0.0): \($0.1)" }.joined(separator: "\n")
                    }
                    
                    else
                    //Lo scontrino non riporta l'IVA
                    {
                        var possibleTotal: [Double] = []
          
                        for observation in sortedObservations {
                            guard let topCandidate = observation.topCandidates(1).first else { continue }
                            var text = topCandidate.string
                            let boundingBox = observation.boundingBox
                            
                            //MARK: logica per skippare tutte le altre info PRIMA del totale
                            if(boundingBox.origin.y > positionYTotal + heightTotal){
                                continue
                            }
                            
                            //MARK: logica per skippare tutte le altre info DOPO del totale
                            if(boundingBox.origin.y < (positionYTotal - heightTotal)){
                                continue
                            }
                            
                            if let _ = text.range(of: #"^\d+([.,]\d+)?$"#, options: .regularExpression) {
                                let widthNumber = boundingBox.size.width
                                let heightNumber = boundingBox.size.height

                                if((widthNumber + heightNumber) > heightTotal){
                                
                                    text = text.replacingOccurrences(of: ",", with: ".")
                                    
                                    if let possibleTotalPrice = Double(text){
                                        possibleTotal.append(possibleTotalPrice)
                                    }
                                }
                                
                            }
                            
                        }
                       
                        if let maxTotal = possibleTotal.max() {
                            return "TOTALE COMPLESSIVO \(maxTotal)"
                        } else {
                            return ""
                        }
                    }
                    
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
    
    func setDescription(text: String, coordinateY: Double){
        // Controlla se il testo contiene il simbolo di percentuale
        if let percentRange = text.range(of: "%", options: .backwards) {
            // Trova il punto in cui inizia la description (ultimo spazio bianco prima del numero percentuale)
            var endIndex = percentRange.lowerBound
            while endIndex > text.startIndex && !text[endIndex].isWhitespace {
                endIndex = text.index(before: endIndex)
            }
            
            // Estrai la description e l'IVA
            let description = String(text[text.startIndex..<endIndex]).trimmingCharacters(in: .whitespaces)
            let ivaString = String(text[text.index(after: endIndex)..<percentRange.upperBound]).trimmingCharacters(in: .whitespaces)
            let ivaStringWithoutPercent = ivaString.replacingOccurrences(of: "%", with: "")
            
            
            if let ivaValue = Int(ivaStringWithoutPercent) {
                self.iva.append(ivaValue)
            }
            self.description.append((coordinateY, description))
            
        } else {
            // Se non viene trovato il simbolo di percentuale, aggiungi l'intero testo come description
            self.description.append((coordinateY,text))
            
        }
    }
    func setIva(text:String){
        if let ivaValue = Int(text.trimmingCharacters(in: CharacterSet(charactersIn: "%"))) {
            self.iva.append(ivaValue)
            
        }
    }
    func setPrice(text:String,coordinateY: Double){
        if let priceValue = Double(text) {
            self.price.append((coordinateY, priceValue))
            price.sort { $0.0 > $1.0 }
        }
    }
    func averageSpaceProducts() -> Double{
        var sumDeltaY: Double = 0.0
        
        for i in 0..<price.count - 1 {
            let y1 = price[i].0
            let y2 = price[i + 1].0
            let deltaY = abs(y2 - y1)
            sumDeltaY += deltaY
        }
        let deltaYMedium = sumDeltaY / Double(price.count - 1)
        return deltaYMedium
    }
    
    func joinArrays(theshold: Double){
        // Itera attraverso l'array price e confronta ogni coppia di valori con la theshold
        let numberDetails = price.count
        for i in 0..<numberDetails - 1{
            let x1 = price[i].0
            let x2 = price[i + 1].0
            let difference = abs(x2 - x1)
            
            if difference > theshold {
                //Questa logica puo essere utile se ci sono due righe di description
                var string1 = description[i].1
                let string2 = description[i+1].1
                string1.append(" " + string2)
                description.remove(at: i+1)
                result.append((string1,self.price[i].1))
                print("C'è più spazio tra", x1, "e", x2)
            } else {
                result.append((self.description[i].1, self.price[i].1))
                print("Non c'è più spazio tra", x1, "e", x2)
            }
        }
        
        //siccome sopra faccion il confronto a due a due e inserisco il primo succede che l'ultimo elemento non viene aggiunto quindi lo faccio ora
        if numberDetails > 0 && numberDetails <= self.description.count && numberDetails <= self.price.count {
            result.append((self.description[numberDetails-1].1, self.price[numberDetails-1].1))
        }
        
    }
    
}
