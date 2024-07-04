//
//  ScanData.swift
//  Scan-Ocr
//
//   Created by d0x1t on 02/07/2024.
//

import Foundation


struct ScanData:Identifiable {
    var id = UUID()
    var content:String
    
    init(content:String) {
        self.content = content
    }
    mutating func addLineBreaks() {
         self.content = self.content.replacingOccurrences(of: "%", with: "%\n")
     }
 }

