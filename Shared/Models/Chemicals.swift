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

enum Units: String {
    case kg = "kg"
    case liters = "liters"
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

var ChlorineChemicalsUnits: [ChlorineChemicals: Units] = [
    .calciumHypochlorite65Percent: .kg,
    .sodiumHypochlorite12Percent: .liters,
    .sodiumHypochlorite14Percent: .liters,
    .tCCA90PercentTablets: .kg,
    .multiActionTablets: .kg,
    .tCCA90PercentGranules: .kg,
    .dichlor65Percent: .kg
]

enum AcidChemicals: String, CaseIterable, Identifiable, Comparable, Hashable {
    static func < (lhs: AcidChemicals, rhs: AcidChemicals) -> Bool {
        lhs.rawValue > rhs.rawValue
    }
    case hydrochloricAcid = "Hydrochloric Acid"
    case sodiumBisulphate = "Sodium Bisulphate"
    var id: Self { self }
}

var AcidChemicalsUnits: [AcidChemicals: Units] = [
    .hydrochloricAcid: .liters,
    .sodiumBisulphate: .kg
]

enum AlkalinityChemicals: String, CaseIterable, Identifiable, Comparable, Hashable {
    static func < (lhs: AlkalinityChemicals, rhs: AlkalinityChemicals) -> Bool {
        lhs.rawValue > rhs.rawValue
    }
    case sodiumBicarbonate = "Sodium Bicarbonate"
    var id: Self { self }
}

var AlkalinityChemicalsUnits: [AlkalinityChemicals: Units] = [
    .sodiumBicarbonate: .kg
]

enum UnknownChemicals: Error {
    case chlorine
    case acid
    case alkalinity
}
