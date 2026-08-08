//
//  PlaceInsightsView.swift
//  MyTesla
//

import SwiftUI

struct PlaceInsightsView: View {
    let insights: [PlaceInsight]

    var body: some View {
        List {
            ForEach(insights) { insight in
                VStack(alignment: .leading) {
                    Text(insight.name)
                        .font(.headline)
                    HStack(spacing: 12) {
                        Label("\(insight.totalStays)次", systemImage: "car")
                            .font(.caption)
                        Label("\(Int(insight.totalDistance))km", systemImage: "road.lanes")
                            .font(.caption)
                        Label("\(insight.totalCharges)次充电", systemImage: "bolt")
                            .font(.caption)
                    }
                    .foregroundColor(.secondary)
                }
                .padding(.vertical, 4)
            }
        }
        .navigationTitle("地点洞察")
        .navigationBarTitleDisplayMode(.inline)
    }
}
