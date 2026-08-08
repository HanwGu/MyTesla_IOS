//
//  Drive.swift
//  MyTesla
//

import Foundation
import SwiftData

@Model
final class Drive {
    @Attribute(.unique) var id: Int
    var startTime: Date
    var endTime: Date
    var startAddress: String?
    var endAddress: String?
    var distance: Double
    var avgEnergy: Double
    var duration: Int
    var maxSpeed: Double?
    var avgSpeed: Double?
    var regenEnergy: Double?
    var elevationGain: Double?
    var outsideTemp: Double?
    var category: String?
    var subcategory: String?
    var note: String?
    var insightBadge: String?

    init(id: Int, startTime: Date, endTime: Date, startAddress: String? = nil, endAddress: String? = nil, distance: Double, avgEnergy: Double, duration: Int, maxSpeed: Double? = nil, avgSpeed: Double? = nil, regenEnergy: Double? = nil, elevationGain: Double? = nil, outsideTemp: Double? = nil, category: String? = nil, subcategory: String? = nil, note: String? = nil, insightBadge: String? = nil) {
        self.id = id
        self.startTime = startTime
        self.endTime = endTime
        self.startAddress = startAddress
        self.endAddress = endAddress
        self.distance = distance
        self.avgEnergy = avgEnergy
        self.duration = duration
        self.maxSpeed = maxSpeed
        self.avgSpeed = avgSpeed
        self.regenEnergy = regenEnergy
        self.elevationGain = elevationGain
        self.outsideTemp = outsideTemp
        self.category = category
        self.subcategory = subcategory
        self.note = note
        self.insightBadge = insightBadge
    }
}
