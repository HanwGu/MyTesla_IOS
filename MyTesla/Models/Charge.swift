//
//  Charge.swift
//  MyTesla
//

import Foundation
import SwiftData

@Model
final class Charge: @unchecked Sendable {
    @Attribute(.unique) var id: Int
    var startTime: Date
    var endTime: Date
    var energyAdded: Double
    var cost: Double?
    var parkingCost: Double?
    var positionLat: Double
    var positionLon: Double
    var address: String?
    var maxPower: Double?
    var avgPower: Double?
    var socStart: Int
    var socEnd: Int

    init(id: Int, startTime: Date, endTime: Date, energyAdded: Double, cost: Double? = nil, parkingCost: Double? = nil, positionLat: Double, positionLon: Double, address: String? = nil, maxPower: Double? = nil, avgPower: Double? = nil, socStart: Int, socEnd: Int) {
        self.id = id
        self.startTime = startTime
        self.endTime = endTime
        self.energyAdded = energyAdded
        self.cost = cost
        self.parkingCost = parkingCost
        self.positionLat = positionLat
        self.positionLon = positionLon
        self.address = address
        self.maxPower = maxPower
        self.avgPower = avgPower
        self.socStart = socStart
        self.socEnd = socEnd
    }
}
