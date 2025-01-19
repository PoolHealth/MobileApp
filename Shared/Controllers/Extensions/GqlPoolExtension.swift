//
//  Pool.swift
//  PoolHealth
//
//  Created by user on 15/01/2025.
//

import Foundation
import PoolHealthSchema

// Map GQL types to the corresponding app models.
extension ListQuery.Data.Pool.Settings? {
    func toModel() -> PoolSettings? {
        guard let settings = self else {
            return nil
        }
        
        return PoolSettings(
            type: settings.type.toModel(),
            usageType: settings.usageType.toModel(),
            shape: settings.shape.toModel(),
            locationType: settings.locationType.toModel(),
            coordinates: Coordinates(longtitude: settings.coordinates.longitude, latitude: settings.coordinates.latitude)
        )
    }
}

extension GraphQLEnum<PoolHealthSchema.PoolType> {
    func toModel() -> PoolType {
        switch self {
        case .infinity:
            return .infinity
        case .overflow:
            return .overflow
        case .skimmer:
            return .skimmer
        case .case(_), .unknown(_):
            return .unknown
        }
    }
}

extension GraphQLEnum<PoolHealthSchema.UsageType> {
    func toModel() -> UsageType {
        switch self {
        case .community:
            return .community
        case .private:
            return .privatePool
        case .holiday:
            return .holiday
        case .unknown(_), .case(_):
            return .unknown
        }
    }
}

extension GraphQLEnum<PoolHealthSchema.PoolShape> {
    func toModel() -> PoolShape {
        switch self {
        case .circle:
            return .circle
        case .rectangle:
            return .rectangle
        case .oval:
            return .oval
        case .kidney:
            return .kidney
        case .l:
            return .l
        case .t:
            return .t
        case .freeForm:
            return .freeForm
        case .case(_), .unknown(_):
            return .unknown
        }
    }
}

extension GraphQLEnum<PoolHealthSchema.LocationType> {
    func toModel() -> PoolLocationType {
        switch self {
        
        case .indoor:
            return .indoor
        case .outdoor:
            return .outdoor
        case .case(_), .unknown(_):
            return .unknown
        }
    }
}
