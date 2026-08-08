//
//  LocationCard.swift
//  MyTesla
//

import SwiftUI
import MapKit

struct LocationCard: View {
    let status: VehicleStatus

    var body: some View {
        Button {
            openInMaps()
        } label: {
            HStack {
                Image(systemName: "location.circle.fill")
                    .foregroundColor(.blue)
                    .font(.title3)
                VStack(alignment: .leading, spacing: 2) {
                    Text(status.address ?? "未知位置")
                        .font(.subheadline)
                        .foregroundColor(.primary)
                    Text("点击打开地图")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(.regularMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
    }

    private func openInMaps() {
        let coordinate = CLLocationCoordinate2D(latitude: status.latitude, longitude: status.longitude)
        let placemark = MKPlacemark(coordinate: coordinate)
        let mapItem = MKMapItem(placemark: placemark)
        mapItem.name = "车辆位置"
        mapItem.openInMaps()
    }
}
