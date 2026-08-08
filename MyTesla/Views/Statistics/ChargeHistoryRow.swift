//
//  ChargeHistoryRow.swift
//  MyTesla
//

import SwiftUI

struct ChargeHistoryRow: View {
    let charge: Charge

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(charge.startTime.formatted(date: .abbreviated, time: .shortened))
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Spacer()
                Text("\(charge.socStart)% → \(charge.socEnd)%")
                    .font(.subheadline)
                    .monospacedDigit()
                Text("+\(Int(charge.energyAdded)) kWh")
                    .font(.subheadline)
                    .foregroundColor(.green)
                    .monospacedDigit()
            }

            HStack {
                Text(charge.address ?? "未知位置")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                if let power = charge.avgPower {
                    Text("\(String(format: "%.1f", power)) kW")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .monospacedDigit()
                }
                if let cost = charge.cost {
                    Text("¥\(String(format: "%.2f", cost))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .monospacedDigit()
                }
            }
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 16)
    }
}
