//
//  ElectricityPrice.swift
//  MyTesla
//

import Foundation
import SwiftData

@Model
final class ElectricityPrice: @unchecked Sendable {
    @Attribute(.unique) var id: UUID
    var name: String
    var startHour: Int
    var endHour: Int
    var pricePerKwh: Double

    init(name: String, startHour: Int, endHour: Int, pricePerKwh: Double) {
        self.id = UUID()
        self.name = name
        self.startHour = startHour
        self.endHour = endHour
        self.pricePerKwh = pricePerKwh
    }
}
