//
//  TripDetail.swift
//  MyTesla
//

import Foundation

struct TripDetail: Decodable {
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
    let startOdometer: Double?
    let endOdometer: Double?
    let startIdealRange: Double?
    let endIdealRange: Double?
    let outsideTemp: Double?
    let insideTemp: Double?

    enum CodingKeys: String, CodingKey {
        case id
        case startTime = "start_time"
        case endTime = "end_time"
        case startAddress = "start_address"
        case endAddress = "end_address"
        case startLat = "start_lat"
        case startLon = "start_lon"
        case endLat = "end_lat"
        case endLon = "end_lon"
        case distance
        case avgEnergy = "avg_energy"
        case duration
        case maxSpeed = "max_speed"
        case avgSpeed = "avg_speed"
        case elevationGain = "elevation_gain"
        case regenEnergy = "regen_energy"
        case startOdometer = "start_odometer"
        case endOdometer = "end_odometer"
        case startIdealRange = "start_ideal_range"
        case endIdealRange = "end_ideal_range"
        case outsideTemp = "outside_temp"
        case insideTemp = "inside_temp"
    }
}
