//
//  DateFormats.swift
//  PoolHealth
//
//  Created by user on 27/01/2025.
//

import Foundation

enum DateFormat: String, CaseIterable {
    case iso8601 = "yyyy-MM-dd'T'HH:mm:ssZ"
    case iso8601WithMilliseconds = "yyyy-MM-dd'T'HH:mm:ss.SSSSSSZZZZZ"
}

func parseDate(_ raw: String) throws -> Date? {
    let dateFormatter = DateFormatter()
    dateFormatter.locale = Locale(identifier: "en_US_POSIX") // set locale to reliable US_POSIX
    var date: Date? = nil

    for item in DateFormat.allCases {
        dateFormatter.dateFormat = item.rawValue
        
        guard let el = dateFormatter.date(from:raw) else {
            continue
        }
        
        date = el
        
        break
    }
    
    guard let date = date else {        
        throw MatchingMeasurementError.invalidateDateFormat
    }
    
    return date
}
