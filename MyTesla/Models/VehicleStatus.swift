//
//  VehicleStatus.swift
//  MyTesla
//

import Foundation

struct VehicleStatus: Codable {
    let batteryLevel: Int
    let range: Double
    let insideTemp: Double?
    let outsideTemp: Double?
    let isCharging: Bool
    let chargerPower: Double?
    let chargeTimeRemaining: Int?
    let latitude: Double
    let longitude: Double
    let address: String?
    let odometer: Double

    enum CodingKeys: String, CodingKey {
        case batteryLevel = "battery_level"
        case range
        case insideTemp = "inside_temp"
        case outsideTemp = "outside_temp"
        case isCharging = "is_charging"
        case chargerPower = "charger_power"
        case chargeTimeRemaining = "charge_time_remaining"
        case latitude
        case longitude
        case address
        case odometer
    }
}
