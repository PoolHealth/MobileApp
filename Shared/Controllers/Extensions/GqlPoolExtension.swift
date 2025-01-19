//
//  Pool.swift
//  PoolHealth
//
//  Created by user on 15/01/2025.
//

import Foundation
import PoolHealthSchema
import MapKit

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
            coordinates: CLLocationCoordinate2D(latitude: settings.coordinates.latitude, longitude: settings.coordinates.longitude)
        )
    }
}

extension PoolSettings {
    func toGql() -> PoolSettingsInput {
        return PoolSettingsInput(type: self.type.toGql(), usageType: self.usageType.toGql(), locationType: self.locationType.toGql(), poolShape: self.shape.toGql(), coordinates: self.coordinates.toGql())
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

extension PoolType? {
    func toGql() -> GraphQLEnum<PoolHealthSchema.PoolType> {
        switch self {
        case .unknown:
            return .unknown("unknown")
        case .none:
            return .unknown("unknown")
        case .infinity:
            return .case(PoolHealthSchema.PoolType.infinity)
        case .overflow:
            return .case(PoolHealthSchema.PoolType.overflow)
        case .skimmer:
            return .case(PoolHealthSchema.PoolType.skimmer)
        }
    }
}

extension UsageType? {
    func toGql() -> GraphQLEnum<PoolHealthSchema.UsageType> {
        switch self {
        case .unknown:
            return .unknown("unknown")
        case .none:
            return .unknown("unknown")
        case .some(.privatePool):
            return .case(PoolHealthSchema.UsageType.private)
        case .some(.community):
            return .case(PoolHealthSchema.UsageType.community)
        case .some(.holiday):
            return .case(PoolHealthSchema.UsageType.holiday)
        }
    }
}

extension PoolLocationType? {
    func toGql() -> GraphQLEnum<PoolHealthSchema.LocationType> {
        switch self {
        case .unknown:
            return .unknown("unknown")
        case .none:
            return .unknown("unknown")
        case .some(.indoor):
            return .case(PoolHealthSchema.LocationType.indoor)
        case .some(.outdoor):
            return .case(PoolHealthSchema.LocationType.outdoor)
        }
    }
}

extension PoolShape? {
    func toGql() -> GraphQLEnum<PoolHealthSchema.PoolShape> {
        switch self {
        case .unknown:
            return .unknown("unknown")
        case .none:
            return .unknown("unknown")
        case .some(.rectangle):
            return .case(PoolHealthSchema.PoolShape.rectangle)
        case .some(.circle):
            return .case(PoolHealthSchema.PoolShape.circle)
        case .some(.oval):
            return .case(PoolHealthSchema.PoolShape.oval)
        case .some(.kidney):
            return .case(PoolHealthSchema.PoolShape.kidney)
        case .some(.l):
            return .case(PoolHealthSchema.PoolShape.l)
        case .some(.t):
            return .case(PoolHealthSchema.PoolShape.t)
        case .some(.freeForm):
            return .case(PoolHealthSchema.PoolShape.freeForm)
        }
    }
}

extension CLLocationCoordinate2D {
    func toGql() -> CoordinatesInput {
        return CoordinatesInput(latitude: self.latitude, longitude: self.longitude)
    }
}



