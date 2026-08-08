//
//  BatteryCard.swift
//  MyTesla
//

import SwiftUI

struct BatteryCard: View {
    let status: VehicleStatus

    var body: some View {
        HStack {
            ZStack {
                Circle()
                    .stroke(Color(.systemGray4), lineWidth: 8)
                    .frame(width: 80, height: 80)
                if status.batteryLevel > 0 {
                    Circle()
                        .trim(from: 0, to: CGFloat(status.batteryLevel) / 100)
                        .stroke(batteryColor, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                        .frame(width: 80, height: 80)
                        .rotationEffect(.degrees(-90))
                        .animation(.easeInOut, value: status.batteryLevel)
                }
                Text("\(status.batteryLevel)%")
                    .font(.title2)
                    .fontWeight(.bold)
                    .monospacedDigit()
            }
            VStack(alignment: .leading, spacing: 4) {
                Text("续航里程")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Text("\(Int(status.range)) km")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .monospacedDigit()
                if let odometer = status.odometer {
                    Text("总里程 \(Int(odometer)) km")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.leading, 8)
            Spacer()
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var batteryColor: Color {
        let level = status.batteryLevel
        if level > 50 { return .green }
        if level > 20 { return .orange }
        return .red
    }
}
