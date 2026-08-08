//
//  PeriodCompareView.swift
//  MyTesla
//

import SwiftUI

struct PeriodCompareView: View {
    let current: Double
    let previous: Double
    let label: String

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(label)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text("\(String(format: "%.1f", current))")
                    .font(.title2)
                    .monospacedDigit()
            }
            Spacer()
            VStack(alignment: .trailing) {
                Text("上周/上月")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text("\(String(format: "%.1f", previous))")
                    .font(.subheadline)
                    .monospacedDigit()
                let percentage = previous > 0 ? ((current - previous) / previous) * 100 : 0
                Text(percentage >= 0 ? "↑ \(String(format: "%.1f", percentage))%" : "↓ \(String(format: "%.1f", abs(percentage)))%")
                    .font(.caption)
                    .foregroundColor(percentage >= 0 ? .green : .red)
            }
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
