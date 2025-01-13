//
//  PoolHealthTests.swift
//  PoolHealthTests
//
//  Created by user on 03/01/2025.
//

import Testing
import Foundation
@testable import PoolHealth

struct PoolHealthTests {

    @Test func measureByMonth() async throws {
        let now = Date()
        func dateDaysAgo(_ days: Double) -> Date {
            now.addingTimeInterval(TimeInterval(86400 * -days))
        }
        let data = [
            Measurement(createdAt: dateDaysAgo(50), chlorine: 100, ph: 100, alkalinity: 100),
            Measurement(createdAt: dateDaysAgo(100), chlorine: 200, ph: 200, alkalinity: 200),
            Measurement(createdAt: dateDaysAgo(200), chlorine: 100, ph: 100, alkalinity: 100),
            Measurement(createdAt: dateDaysAgo(300), chlorine: 200, ph: 200, alkalinity: 200),
            Measurement(createdAt: dateDaysAgo(490), chlorine: 100, ph: 100, alkalinity: 100),
            Measurement(createdAt: dateDaysAgo(498), chlorine: 200, ph: 200, alkalinity: 200),
            Measurement(createdAt: dateDaysAgo(499), chlorine: 100, ph: 100, alkalinity: 100),
            Measurement(createdAt: dateDaysAgo(500), chlorine: 200, ph: 200, alkalinity: 200),
            Measurement(createdAt: dateDaysAgo(890), chlorine: 100, ph: 100, alkalinity: 100),
            Measurement(createdAt: dateDaysAgo(899), chlorine: 200, ph: 200, alkalinity: 200),
            Measurement(createdAt: dateDaysAgo(900), chlorine: 100, ph: 100, alkalinity: 100),
        ]
       
       
        
        let result = measurementsByMonth(measurements: data)
        #expect(result.orderedKeys.count == 8)
        print(result.orderedKeys)
    }

}
