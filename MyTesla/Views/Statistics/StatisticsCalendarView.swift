//
//  StatisticsCalendarView.swift
//  MyTesla
//

import SwiftUI

struct StatisticsCalendarView: View {
    let data: [Date: (distance: Double, energy: Double, cost: Double)]
    @State private var selectedDate: Date?

    var body: some View {
        VStack {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 4) {
                ForEach(daysInMonth(), id: \.self) { date in
                    if let dayData = data[date] {
                        Button {
                            selectedDate = date
                        } label: {
                            VStack {
                                Text("\(Calendar.current.component(.day, from: date))")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                Text("\(Int(dayData.distance))")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                            .frame(height: 40)
                            .frame(maxWidth: .infinity)
                            .background(Color.blue.opacity(0.2))
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                        }
                        .buttonStyle(.plain)
                    } else {
                        Text("\(Calendar.current.component(.day, from: date))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .frame(height: 40)
                            .frame(maxWidth: .infinity)
                    }
                }
            }
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func daysInMonth() -> [Date] {
        let calendar = Calendar.current
        let now = Date()
        guard let range = calendar.range(of: .day, in: .month, for: now) else { return [] }
        return range.compactMap { day in
            calendar.date(from: DateComponents(year: calendar.component(.year, from: now), month: calendar.component(.month, from: now), day: day))
        }
    }
}
