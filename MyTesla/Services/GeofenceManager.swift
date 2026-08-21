//
//  GeofenceManager.swift
//  TeslaMateApp
//

import Foundation
import SwiftData

struct GeofenceManager {
    static func matchGeofence(lat: Double, lon: Double, geofences: [Geofence]) -> Geofence? {
        for fence in geofences {
            let distance = haversineDistance(lat1: lat, lon1: lon, lat2: fence.latitude, lon2: fence.longitude)
            if distance <= fence.radius {
                return fence
            }
        }
        return nil
    }

    static func haversineDistance(lat1: Double, lon1: Double, lat2: Double, lon2: Double) -> Double {
        let earthRadius = 6371000.0
        let dLat = (lat2 - lat1) * .pi / 180
        let dLon = (lon2 - lon1) * .pi / 180
        let a = sin(dLat / 2) * sin(dLat / 2) +
                cos(lat1 * .pi / 180) * cos(lat2 * .pi / 180) *
                sin(dLon / 2) * sin(dLon / 2)
        let c = 2 * atan2(sqrt(a), sqrt(1 - a))
        return earthRadius * c
    }
}

@MainActor
final class GeofenceStore: ObservableObject {
    @Published var geofences: [Geofence] = []
    private var container: ModelContainer?

    init(container: ModelContainer? = nil) {
        self.container = container
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(reloadGeofences),
            name: NSNotification.Name("GeofenceDidChange"),
            object: nil
        )
        if let container {
            load(from: container)
        }
    }

    func load(from container: ModelContainer) {
        self.container = container
        do {
            let geofences = try container.mainContext.fetch(FetchDescriptor<Geofence>())
            self.geofences = geofences.sorted { $0.name < $1.name }
        } catch {
            self.geofences = []
        }
    }

    @objc private func reloadGeofences() {
        guard let container else { return }
        load(from: container)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}
