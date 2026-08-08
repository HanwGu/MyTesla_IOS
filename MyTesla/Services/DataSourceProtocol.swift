//
//  DataSourceProtocol.swift
//  TeslaMateApp
//

import Foundation

protocol DataSource {
    func getVehicles() async throws -> [Vehicle]
    func getVehicle(carId: Int) async throws -> Vehicle
    func getVehicleStatus(carId: Int) async throws -> VehicleStatus
    func getDrives(carId: Int, limit: Int, offset: Int) async throws -> [Trip]
    func getDrive(carId: Int, driveId: Int) async throws -> TripDetail
    func getCharges(carId: Int, limit: Int, offset: Int) async throws -> [Charge]
    func getCharge(carId: Int, chargeId: Int) async throws -> ChargeDetail
    func getBatteryHealth(carId: Int) async throws -> BatteryHealth
}

struct BatteryHealth: Codable {
    let date: Date
    let batteryLevel: Int
    let range: Double

    enum CodingKeys: String, CodingKey {
        case date
        case batteryLevel = "battery_level"
        case range
    }
}
