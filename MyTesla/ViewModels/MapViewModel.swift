//
//  MapViewModel.swift
//  TeslaMateApp
//

import SwiftUI
import MapKit
import CoreLocation

@MainActor
class MapViewModel: ObservableObject {
    @Published var routes: [MKPolyline] = []
    @Published var chargeAnnotations: [ChargeAnnotation] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showOnlyCharges = false
    @Published var cachedRegion: MKCoordinateRegion?

    private var vehicleId: Int?
    private var allTrips: [Trip] = []
    private var allCharges: [Charge] = []

    func configure(vehicleId: Int) {
        self.vehicleId = vehicleId
    }

    func loadMapData() async {
        guard let vehicleId = vehicleId else {
            errorMessage = "未配置车辆"
            return
        }
        isLoading = true
        errorMessage = nil

        do {
            try Task.checkCancellation()

            async let tripsTask = APIClient.shared.getDrives(carId: vehicleId, limit: 200, offset: 0)
            async let chargesTask = APIClient.shared.getCharges(carId: vehicleId, limit: 200, offset: 0)
            let (trips, charges) = try await (tripsTask, chargesTask)
            self.allTrips = trips
            self.allCharges = charges

            applyFilters()
        } catch is CancellationError {
        } catch {
            errorMessage = "加载地图数据失败: \(error.localizedDescription)"
        }
        isLoading = false
    }

    func applyFilters() {
        var polylines: [MKPolyline] = []
        var annotations: [ChargeAnnotation] = []

        if !showOnlyCharges {
            for trip in allTrips {
                if let sLat = trip.startLat, let sLon = trip.startLon,
                   let eLat = trip.endLat, let eLon = trip.endLon {
                    let coords = [
                        CLLocationCoordinate2D(latitude: sLat, longitude: sLon),
                        CLLocationCoordinate2D(latitude: eLat, longitude: eLon)
                    ]
                    let polyline = MKPolyline(coordinates: coords, count: coords.count)
                    polylines.append(polyline)
                }
            }
        }
        self.routes = polylines

        for charge in allCharges {
            let coord = CLLocationCoordinate2D(latitude: charge.positionLat, longitude: charge.positionLon)
            annotations.append(ChargeAnnotation(coordinate: coord, title: charge.address ?? "充电点"))
        }
        self.chargeAnnotations = annotations

        self.cachedRegion = calculateRegion(from: polylines, annotations: annotations)
    }

    private func calculateRegion(from polylines: [MKPolyline], annotations: [ChargeAnnotation]) -> MKCoordinateRegion? {
        var coordinates: [CLLocationCoordinate2D] = []

        for route in polylines {
            let pointCount = route.pointCount
            for i in 0..<pointCount {
                coordinates.append(route.points()[i])
            }
        }
        for annotation in annotations {
            coordinates.append(annotation.coordinate)
        }

        guard let first = coordinates.first else { return nil }

        var minLat = first.latitude
        var maxLat = minLat
        var minLon = first.longitude
        var maxLon = minLon

        for coord in coordinates {
            minLat = min(minLat, coord.latitude)
            maxLat = max(maxLat, coord.latitude)
            minLon = min(minLon, coord.longitude)
            maxLon = max(maxLon, coord.longitude)
        }

        let center = CLLocationCoordinate2D(
            latitude: (minLat + maxLat) / 2,
            longitude: (minLon + maxLon) / 2
        )

        let latDelta = max((maxLat - minLat) * 1.5, 0.05)
        let lonDelta = max((maxLon - minLon) * 1.5, 0.05)

        return MKCoordinateRegion(
            center: center,
            span: MKCoordinateSpan(latitudeDelta: latDelta, longitudeDelta: lonDelta)
        )
    }
}

struct ChargeAnnotation: Identifiable {
    let id = UUID()
    let coordinate: CLLocationCoordinate2D
    let title: String?
}
