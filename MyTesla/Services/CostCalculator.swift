//
//  CostCalculator.swift
//  TeslaMateApp
//

import Foundation

struct CostCalculator {
    static func calculateCost(charge: Charge, geofences: [Geofence], prices: [ElectricityPrice]) -> Double {
        guard let matched = GeofenceManager.matchGeofence(lat: charge.positionLat, lon: charge.positionLon, geofences: geofences) else {
            guard let defaultPrice = prices.first else { return 0 }
            return charge.energyAdded * defaultPrice.pricePerKwh
        }
        guard let priceId = matched.electricityPriceId,
              let price = prices.first(where: { $0.id == priceId }) else {
            return 0
        }
        let hour = Calendar.current.component(.hour, from: charge.startTime)
        if hour >= price.startHour && hour < price.endHour {
            return charge.energyAdded * price.pricePerKwh
        }
        return 0
    }
}
