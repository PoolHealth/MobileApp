//
//  Action.swift
//  PoolHealth
//
//  Created by user on 20/01/2025.
//
import Foundation

enum ActionType: String, CaseIterable {
    case net = "Net"
    case brush = "Brush"
    case vacuum = "Vacuum"
    case backwash = "Backwash"
    case scumLine = "Scum line"
    case pumpBasketClean = "Pump basket clean"
    case skimmerBasketClean = "Skimmer basket clean"
    case unknown = "Unknown"
}

struct Action {
    var actions: [ActionType]
    var createdAt: Date
}
