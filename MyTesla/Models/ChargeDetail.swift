//
//  ChargeDetail.swift
//  MyTesla
//

import Foundation

struct ChargeDetail: Decodable {
    let id: Int
    let startTime: Date
    let endTime: Date
    let energyAdded: Double
    let positionLat: Double
    let positionLon: Double
    let address: String?
    let maxPower: Double?
    let avgPower: Double?
    let socStart: Int
    let socEnd: Int
    let startIdealRange: Double?
    let endIdealRange: Double?
    let outsideTemp: Double?
    let insideTemp: Double?
    let cost: Double?
    let parkingCost: Double?

    enum CodingKeys: String, CodingKey {
        case id
        case startTime = "start_time"
        case endTime = "end_time"
        case energyAdded = "energy_added"
        case positionLat = "position_lat"
        case positionLon = "position_lon"
        case address
        case maxPower = "max_power"
        case avgPower = "avg_power"
        case socStart = "soc_start"
        case socEnd = "soc_end"
        case startIdealRange = "start_ideal_range"
        case endIdealRange = "end_ideal_range"
        case outsideTemp = "outside_temp"
        case insideTemp = "inside_temp"
        case cost
        case parkingCost = "parking_cost"
    }
}
