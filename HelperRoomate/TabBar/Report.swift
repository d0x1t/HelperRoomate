//
//  Report.swift
//  HelperRoomate
//
//  Created by Studente on 05/07/24.
//

import SwiftUI

struct Report: View {
    @Binding var spese: [Spesa]
    @Binding var coinquilini: [Coinquilino]

    
    var body: some View {
        Text(/*@START_MENU_TOKEN@*/"Hello, World!"/*@END_MENU_TOKEN@*/)
    }
}

#Preview {
    // Provide a sample binding for preview
    Report(spese: .constant([Spesa]()), coinquilini: .constant([Coinquilino]()))
}
