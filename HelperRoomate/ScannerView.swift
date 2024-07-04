//
//  ScannerView.swift
//  Scan-Ocr
//
//   Created by d0x1t on 02/07/2024.
//

import VisionKit
import SwiftUI

struct ScannerView: UIViewControllerRepresentable {
    private let completionHandler: ([String]?) -> Void
     
    //escaping:
    init(completion: @escaping ([String]?) -> Void) {
        self.completionHandler = completion
    }
    //Obbligatorio per il protocollo implementato. stiamo dicendo il tipo
    //di componente che scannerView dovrà rappresentare
    
    typealias UIViewControllerType = VNDocumentCameraViewController
    
    //Primo metodo obbligatorio se si implementa il protocollo UIViewControllerRepresentable
    //Viene chiamato quando SwiftUI ha il bisogno di inizializzare il controller
    //che deve essere presentato all'utente
    func makeUIViewController(context: UIViewControllerRepresentableContext<ScannerView>) -> VNDocumentCameraViewController {
        // Creazione di un'istanza di VNDocumentCameraViewController
        let viewController = VNDocumentCameraViewController()
        
        // Assegnazione del coordinator al delegato del view controller
        // Operazione necessaria perche stiamo usando un controller che
        // appartiene a UIKit quindi dobbiamo creare un coordinatore cioè
        // un ponte fra UIkit e SwiftUI per consentire la gestione delle interazioni
        viewController.delegate = context.coordinator
        
        // Restituzione del view controller creato
        return viewController
    }

     //Secondo metodo obbligatorio
    func updateUIViewController(_ uiViewController: VNDocumentCameraViewController, context: UIViewControllerRepresentableContext<ScannerView>) {
        //Viene chiamato quando cambia lo stato dello ScannerView ma non ci serve al momento.
    }
     //Terza funzione obbligatoria: viene chiamata nel momento in cui si fa
    // context.coordinator quindi ritorna un istanza di coordinator che ha 3 override
    //obbligatori per le classi che implementano il protocollo VNDocumentCameraViewControllerDelegate
    func makeCoordinator() -> Coordinator {
        return Coordinator(completion: completionHandler)
    }
     
    final class Coordinator: NSObject, VNDocumentCameraViewControllerDelegate {
        private let completionHandler: ([String]?) -> Void
         
        init(completion: @escaping ([String]?) -> Void) {
            self.completionHandler = completion
        }
         //quando lo scanner viene eseguito con successo la funzione che viene chiamata
        //è questa.
        func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFinishWith scan: VNDocumentCameraScan) {
            print("Document camera view controller did finish with ", scan)
            //in scan sono contenute le immagini scannerizzate
            let recognizer = TextRecognizer(cameraScan: scan)
            recognizer.recognizeText(withCompletionHandler: completionHandler)
        }
        //quando lo scanner viene chiuso senza scansione la funzione che viene chiamata
       //è questa.
        func documentCameraViewControllerDidCancel(_ controller: VNDocumentCameraViewController) {
            completionHandler(nil)
        }
         //funzione chiamata in caso di errori nello scanner
        
        func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFailWithError error: Error) {
            print("Document camera view controller did finish with error ", error)
            completionHandler(nil)
        }
    }
}
