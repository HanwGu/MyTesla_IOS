//
//  PlaceInsightAggregator.swift
//  TeslaMateApp
//

import Foundation

struct PlaceInsightAggregator {
    static func aggregate(drives: [Drive], charges: [Charge]) -> [String: PlaceInsight] {
        var dict: [String: PlaceInsight] = [:]
        for drive in drives {
            let key = drive.startAddress ?? "未知位置"
            if dict[key] == nil {
                dict[key] = PlaceInsight(name: key, totalStays: 0, totalDistance: 0, totalCharges: 0)
            }
            dict[key]?.totalStays += 1
            dict[key]?.totalDistance += drive.distance
        }
        for charge in charges {
            let key = charge.address ?? "未知位置"
            if dict[key] == nil {
                dict[key] = PlaceInsight(name: key, totalStays: 0, totalDistance: 0, totalCharges: 0)
            }
            dict[key]?.totalCharges += 1
        }
        return dict
    }
}

struct PlaceInsight: Identifiable {
    let name: String
    var totalStays: Int
    var totalDistance: Double
    var totalCharges: Int

    var id: String { name }
}
