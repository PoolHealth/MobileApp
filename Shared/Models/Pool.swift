//
//  Pool.swift
//  PoolHealth
//
//  Created by user on 03/01/2025.
//

import Foundation

struct Pool {
    var id: String
    var name: String
    var volume: Double
}

struct PoolDetails{
    var freeChlorine: Double?
    var chlorineDemand: Double?
    var ph: Double?
    var phChanges: Double?
    var alkalinity: Double?
    var alkalinityChanges: Double?
    var measurementsCreatedAt: Date
}
