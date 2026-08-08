//
//  StatusGridCard.swift
//  MyTesla
//

import SwiftUI

struct StatusGridCard: View {
    let status: VehicleStatus

    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
            StatusItem(
                icon: "thermometer.medium",
                value: status.insideTemp.map { "\(Int($0))°" } ?? "--",
                label: "车内温度"
            )
            StatusItem(
                icon: "thermometer",
                value: status.outsideTemp.map { "\(Int($0))°" } ?? "--",
                label: "车外温度"
            )
            StatusItem(
                icon: "speedometer",
                value: status.odometer.map { "\(Int($0))" } ?? "--",
                label: "总里程 km"
            )
            StatusItem(
                icon: "gauge.medium",
                value: "\(status.batteryLevel)%",
                label: "电量"
            )
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

struct StatusItem: View {
    let icon: String
    let value: String
    let label: String

    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.secondary)
                .frame(width: 24)
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.headline)
                    .monospacedDigit()
                Text(label)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            Spacer()
        }
        .padding(.vertical, 4)
    }
}
