//
//  ChargingCard.swift
//  MyTesla
//

import SwiftUI

struct ChargingCard: View {
    let status: VehicleStatus

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "bolt.circle.fill")
                    .foregroundColor(.green)
                Text("充电中")
                    .font(.headline)
                Spacer()
                if let power = status.chargerPower {
                    Text("\(String(format: "%.1f", power)) kW")
                        .font(.headline)
                        .monospacedDigit()
                } else {
                    Text("功率未知")
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
            }
            Divider()
            HStack {
                VStack(alignment: .leading) {
                    Text("当前电量")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(status.batteryLevel)%")
                        .font(.title3)
                        .monospacedDigit()
                }
                Spacer()
                if let remaining = status.chargeTimeRemaining {
                    VStack(alignment: .trailing) {
                        Text("预计充满")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("\(remaining)分钟")
                            .font(.title3)
                            .monospacedDigit()
                    }
                } else {
                    VStack(alignment: .trailing) {
                        Text("预计充满")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("计算中...")
                            .font(.title3)
                            .foregroundColor(.secondary)
                    }
                }
            }
            if status.batteryLevel < 100 {
                ProgressView(value: Double(status.batteryLevel), total: 100)
                    .progressViewStyle(.linear)
                    .tint(.green)
                    .padding(.top, 4)
            } else {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("已充满")
                        .font(.subheadline)
                        .foregroundColor(.green)
                }
                .padding(.top, 4)
            }
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}
