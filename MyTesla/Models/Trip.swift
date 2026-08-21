//
//  Trip.swift
//  MyTesla
//

import Foundation

struct Trip: Identifiable, Hashable {
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
    var favorite: Bool = false
    var insightBadge: String?

    init(id: Int, startTime: Date, endTime: Date, startAddress: String? = nil, endAddress: String? = nil, startLat: Double? = nil, startLon: Double? = nil, endLat: Double? = nil, endLon: Double? = nil, distance: Double, avgEnergy: Double, duration: Int, maxSpeed: Double? = nil, avgSpeed: Double? = nil, elevationGain: Double? = nil, regenEnergy: Double? = nil, outsideTemp: Double? = nil, category: String? = nil, note: String? = nil, favorite: Bool = false, insightBadge: String? = nil) {
        self.id = id
        self.startTime = startTime
        self.endTime = endTime
        self.startAddress = startAddress
        self.endAddress = endAddress
        self.startLat = startLat
        self.startLon = startLon
        self.endLat = endLat
        self.endLon = endLon
        self.distance = distance
        self.avgEnergy = avgEnergy
        self.duration = duration
        self.maxSpeed = maxSpeed
        self.avgSpeed = avgSpeed
        self.elevationGain = elevationGain
        self.regenEnergy = regenEnergy
        self.outsideTemp = outsideTemp
        self.category = category
        self.note = note
        self.favorite = favorite
        self.insightBadge = insightBadge
    }
}
