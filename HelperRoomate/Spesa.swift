//
//  Spesa.swift
//  HelperRoomate
//
//  Created by Studente on 05/07/24.
//

import Foundation

enum Categoria{
    case spesa
    case utenza
    case manutenzione
    case generale
}

struct Spesa{
    var nome: String
    var categoria: Categoria
    var data: Date
    var importo: Double
    var descrizione: String?   //descrizione della spesa opzionale
    var descrizioneSpesa: [String: Double]   //descrizione della spesa opzionale
    var pagatoDa: [String]   //vettore di coinquilini che hanno contribuito alla spesa
    var divisaTra: [String]   //vettore di coinquilini che devono contribuire alla spesa
    var abitazione: Int
}
