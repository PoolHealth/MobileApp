//
//  Pool.swift
//  PoolHealth
//
//  Created by user on 03/01/2025.
//

import Foundation
import MapKit
import AppIntents
import CoreLocation
import CoreSpotlight


struct Pool: Identifiable {
    var id: String
    var name: String
    var volume: Double
    var settings: PoolSettings?
}

extension Pool: AppEntity {
    // The type-level description of a Pool.
    static var typeDisplayRepresentation: TypeDisplayRepresentation {
        // It is important to instantiate directly.
        TypeDisplayRepresentation(name: "Pool")
    }
    
    // How an individual pool should be shown in Spotlight or Shortcuts.
    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(
            title: LocalizedStringResource(stringLiteral: name),
            subtitle: LocalizedStringResource(stringLiteral: "Volume: \(volume)")
        )
    }
    
    // Provide a default query so the system can retrieve Pool instances.
    static var defaultQuery: PoolQuery {
        PoolQuery()
    }
}

extension Pool: IndexedEntity {
//    var attributeSet: CSSearchableItemAttributeSet {
//        let attributes = CSSearchableItemAttributeSet()
//        
//        attributes.title = name
//        guard let shape = settings?.shape else { return attributes }
//        
//        attributes.keywords = [shape.rawValue]
//        
//        return attributes
//    }
}

// A simple query to retrieve and suggest Pool entities.
struct PoolQuery: EntityQuery {
    // Explicitly declare that the Entity type for this query is Pool.
    typealias Entity = Pool
    // Retrieve pools matching the provided identifiers.
    // In a real app, you’d fetch this from your data store or manager.
    func entities(for identifiers: [String]) async throws -> [Pool] {
        let manager = PoolManager()
        await manager.loadPools()
        // Example: assuming you maintain a shared list of pools.
        return manager.pools.filter { identifiers.contains($0.id) }
    }
    
    // Return a list of pools that you’d like to be suggested.
    func suggestedEntities() async throws -> [Pool] {
        let manager = PoolManager()
        await manager.loadPools()
        return manager.pools
    }
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
    case community = "Communal"
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
