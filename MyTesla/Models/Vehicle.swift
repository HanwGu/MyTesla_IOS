//
//  Vehicle.swift
//  MyTesla
//

import Foundation
import SwiftData

@Model
final class Vehicle: @unchecked Sendable {
    @Attribute(.unique) var id: Int
    var name: String
    var model: String?
    var softwareVersion: String?
    var vin: String?
    var carType: String?
    var lastUpdated: Date

    init(id: Int, name: String, model: String? = nil, softwareVersion: String? = nil, vin: String? = nil, carType: String? = nil, lastUpdated: Date = Date()) {
        self.id = id
        self.name = name
        self.model = model
        self.softwareVersion = softwareVersion
        self.vin = vin
        self.carType = carType
        self.lastUpdated = lastUpdated
    }
}
