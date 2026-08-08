//
//  Trip.swift
//  MyTesla
//

import Foundation

struct Trip: Identifiable {
    let id: Int
    let startTime: Date
    let endTime: Date
    let startAddress: String?
    let endAddress: String?
    let startLat: Double?
    let startLon: Double?
    let endLat: Double?
    let endLon: Double?
    let distance: Double
    let avgEnergy: Double
    let duration: Int
    let maxSpeed: Double?
    let avgSpeed: Double?
    let elevationGain: Double?
    let regenEnergy: Double?
    let outsideTemp: Double?

    var category: String?
    var note: String?
    var insightBadge: String?
}
