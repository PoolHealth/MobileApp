//
//  Chemicals.swift
//  PoolHealth
//
//  Created by user on 09/01/2025.
//

import Foundation

struct Chemicalicals {
    var createdAt: Date
    var chlorineChemicals: Dictionary<ChlorineChemicals, Double>?
    var acidChemicals: Dictionary<AcidChemicals, Double>?
    var alkalinityChemical: Dictionary<AlkalinityChemicals, Double>?
}

enum ChlorineChemicals: String, CaseIterable, Identifiable, Comparable, Hashable {
    static func < (lhs: ChlorineChemicals, rhs: ChlorineChemicals) -> Bool {
        lhs.rawValue > rhs.rawValue
    }
    
    case dichlor65Percent = "Dichlor 65%"
    case calciumHypochlorite65Percent = "Calcium Hypochlorite 65%"
    case sodiumHypochlorite12Percent = "Sodium Hypochlorite 12%"
    case sodiumHypochlorite14Percent = "Sodium Hypochlorite 14%"
    case multiActionTablets = "Multi-Action Tablets"
    case tCCA90PercentTablets = "TCCA 90% Tablets"
    case tCCA90PercentGranules = "TCCA 90% Granules"
    var id: Self { self }
}

enum AcidChemicals: String, CaseIterable, Identifiable, Comparable, Hashable {
    static func < (lhs: AcidChemicals, rhs: AcidChemicals) -> Bool {
        lhs.rawValue > rhs.rawValue
    }
    case hydrochloricAcid = "Hydrochloric Acid"
    case sodiumBisulphate = "Sodium Bisulphate"
    var id: Self { self }
}

enum AlkalinityChemicals: String, CaseIterable, Identifiable, Comparable, Hashable {
    static func < (lhs: AlkalinityChemicals, rhs: AlkalinityChemicals) -> Bool {
        lhs.rawValue > rhs.rawValue
    }
    case sodiumBicarbonate = "Sodium Bicarbonate"
    var id: Self { self }
}

enum UnknownChemicals: Error {
    case chlorine
    case acid
    case alkalinity
}
