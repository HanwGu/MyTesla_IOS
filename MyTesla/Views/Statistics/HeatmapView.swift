//
//  HeatmapView.swift
//  MyTesla
//

import SwiftUI

struct HeatmapView: View {
    let data: [Date: Double]

    var body: some View {
        VStack(alignment: .leading) {
            Text("年度热力图")
                .font(.headline)
                .padding(.leading)
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 53), spacing: 2) {
                ForEach(weeksInYear(), id: \.self) { date in
                    let distance = data[date] ?? 0
                    Rectangle()
                        .fill(color(for: distance))
                        .frame(height: 12)
                        .clipShape(RoundedRectangle(cornerRadius: 2))
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func color(for distance: Double) -> Color {
        switch distance {
        case 0: return .gray.opacity(0.2)
        case 1...10: return .green.opacity(0.3)
        case 10...50: return .green.opacity(0.6)
        default: return .green.opacity(0.9)
        }
    }

    private func weeksInYear() -> [Date] {
        let calendar = Calendar.current
        let now = Date()
        let currentYear = calendar.component(.year, from: now)
        guard let startOfYear = calendar.date(from: DateComponents(year: currentYear, month: 1, day: 1)) else { return [] }
        var dates: [Date] = []
        for weekOffset in 0..<53 {
            guard let date = calendar.date(byAdding: .day, value: weekOffset * 7, to: startOfYear),
                  calendar.component(.year, from: date) == currentYear else { break }
            dates.append(date)
        }
        return dates
    }
}
