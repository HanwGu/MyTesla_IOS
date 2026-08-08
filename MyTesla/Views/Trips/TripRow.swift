//
//  TripRow.swift
//  MyTesla
//

import SwiftUI

struct TripRow: View {
    let trip: Trip

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(trip.startAddress ?? "起点")
                Image(systemName: "arrow.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(trip.endAddress ?? "终点")
                Spacer()
                Text("\(String(format: "%.1f", trip.distance)) km")
                    .font(.headline)
                    .monospacedDigit()
            }
            .font(.subheadline)

            HStack(spacing: 12) {
                Label(trip.duration > 0 ? "\(trip.duration)分钟" : "< 1 分钟", systemImage: "clock")
                Label("\(Int(trip.avgEnergy)) Wh/km", systemImage: "bolt")
                Spacer()
                if let badge = trip.insightBadge {
                    Text(badge)
                        .font(.caption2)
                        .foregroundColor(.blue)
                }
            }
            .font(.caption)
            .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}
