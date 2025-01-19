//
//  Pool.swift
//  PoolHealth
//
//  Created by user on 03/01/2025.
//

import Foundation
import MapKit

struct Pool {
    var id: String
    var name: String
    var volume: Double
    var settings: PoolSettings?
}

struct PoolSettings {
    var type: PoolType?
    var usageType: UsageType?
    var shape: PoolShape?
    var locationType: PoolLocationType?
    var coordinates: CLLocationCoordinate2D
}

enum PoolType: String, CaseIterable, Identifiable, Hashable {
    var id: Self { self }
    
    case infinity = "Infinity"
    case overflow = "Overflow"
    case skimmer = "Skimmer"
    case unknown = "None"
    
}

enum UsageType: String, CaseIterable, Identifiable, Hashable {
    var id: Self { self }
    case privatePool = "Private"
    case community = "Community"
    case holiday = "Holiday"
    case unknown = "None"
}

enum PoolShape: String, CaseIterable {
    case rectangle = "Rectangle"
    case circle = "Circle"
    case oval = "Oval"
    case kidney = "Kidney"
    case l = "L"
    case t = "T"
    case freeForm = "FreeForm"
    case unknown = "None"
}

enum PoolLocationType: String, CaseIterable {
    case indoor = "Indoor"
    case outdoor = "Outdoor"
    case unknown = "None"
}

struct Coordinates {
    var longtitude: Double
    var latitude: Double
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
