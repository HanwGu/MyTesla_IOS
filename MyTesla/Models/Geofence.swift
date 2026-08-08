//
//  Geofence.swift
//  MyTesla
//

import Foundation
import SwiftData

@Model
final class Geofence {
    @Attribute(.unique) var name: String
    var latitude: Double
    var longitude: Double
    var radius: Double
    var electricityPriceId: UUID?

    init(name: String, latitude: Double, longitude: Double, radius: Double, electricityPriceId: UUID? = nil) {
        self.name = name
        self.latitude = latitude
        self.longitude = longitude
        self.radius = radius
        self.electricityPriceId = electricityPriceId
    }
}
