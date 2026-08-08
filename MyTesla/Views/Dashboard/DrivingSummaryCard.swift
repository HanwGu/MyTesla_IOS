//
//  DrivingSummaryCard.swift
//  MyTesla
//

import SwiftUI

struct DrivingSummaryCard: View {
    let drive: Drive

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "car.fill")
                    .foregroundColor(.blue)
                Text("最近驾驶")
                    .font(.headline)
                Spacer()
                if let badge = drive.insightBadge {
                    Text(badge)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.blue.opacity(0.2))
                        .clipShape(Capsule())
                }
            }
            Divider()
            HStack {
                VStack(alignment: .leading) {
                    Text(drive.startAddress ?? "起点")
                    Image(systemName: "arrow.down")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(drive.endAddress ?? "终点")
                }
                .font(.subheadline)
                Spacer()
                VStack(alignment: .trailing) {
                    Text("\(String(format: "%.1f", drive.distance)) km")
                        .font(.headline)
                        .monospacedDigit()
                    Text("\(drive.duration)分钟 · \(Int(drive.avgEnergy)) Wh/km")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .monospacedDigit()
                }
            }
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}
