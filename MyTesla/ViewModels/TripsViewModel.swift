//
//  TripsViewModel.swift
//  TeslaMateApp
//

import SwiftUI
import SwiftData

@MainActor
class TripsViewModel: ObservableObject {
    @Published var trips: [Trip] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var hasMoreData = true

    private var cachedGroupedTrips: [(date: Date, trips: [Trip])] = []
    private var lastTripsHash: Int = 0

    private var vehicleId: Int?
    private var currentOffset = 0
    private let limit = 20
    private var modelContext: ModelContext?

    func configure(context: ModelContext, vehicleId: Int) {
        self.modelContext = context
        self.vehicleId = vehicleId
    }

    func loadTrips(reset: Bool = false) async {
        guard let vehicleId = vehicleId else { return }
        if reset {
            trips.removeAll()
            currentOffset = 0
            hasMoreData = true
            cachedGroupedTrips.removeAll()
            lastTripsHash = 0
        }
        guard hasMoreData else { return }
        isLoading = true
        errorMessage = nil

        do {
            try Task.checkCancellation()

            let newTrips = try await APIClient.shared.getDrives(carId: vehicleId, limit: limit, offset: currentOffset)
            if newTrips.isEmpty {
                hasMoreData = false
            } else {
                var enrichedTrips: [Trip] = []
                if let context = modelContext {
                    // 获取已排序的历史行程（最多100条）
                    let historicalDescriptor = FetchDescriptor<Drive>(
                        sortBy: [SortDescriptor(\Drive.startTime, order: .reverse)]
                    )
                    historicalDescriptor.fetchLimit = DrivingInsightEngine.maxHistoricalCount
                    let historicalDrives = try context.fetch(historicalDescriptor)

                    for var trip in newTrips {
                        let predicate = #Predicate<Drive> { $0.id == trip.id }
                        let existing = try context.fetch(FetchDescriptor<Drive>(predicate: predicate))
                        if let drive = existing.first {
                            // 更新现有
                            drive.startTime = trip.startTime
                            drive.endTime = trip.endTime
                            drive.startAddress = trip.startAddress
                            drive.endAddress = trip.endAddress
                            drive.distance = trip.distance
                            drive.avgEnergy = trip.avgEnergy
                            drive.duration = trip.duration
                            drive.maxSpeed = trip.maxSpeed
                            drive.avgSpeed = trip.avgSpeed
                            drive.regenEnergy = trip.regenEnergy
                            drive.elevationGain = trip.elevationGain
                            // 重新生成徽章
                            drive.insightBadge = DrivingInsightEngine.generateInsight(
                                for: trip,
                                recentDrives: historicalDrives
                            )
                            // 回填到 Trip
                            trip.category = drive.category
                            trip.note = drive.note
                            trip.insightBadge = drive.insightBadge
                        } else {
                            // 新建
                            let drive = Drive(
                                id: trip.id,
                                startTime: trip.startTime,
                                endTime: trip.endTime,
                                startAddress: trip.startAddress,
                                endAddress: trip.endAddress,
                                distance: trip.distance,
                                avgEnergy: trip.avgEnergy,
                                duration: trip.duration,
                                maxSpeed: trip.maxSpeed,
                                avgSpeed: trip.avgSpeed,
                                regenEnergy: trip.regenEnergy,
                                elevationGain: trip.elevationGain,
                                outsideTemp: nil
                            )
                            drive.insightBadge = DrivingInsightEngine.generateInsight(
                                for: trip,
                                recentDrives: historicalDrives
                            )
                            context.insert(drive)
                            trip.insightBadge = drive.insightBadge
                        }
                        enrichedTrips.append(trip)
                    }
                    try context.save()
                } else {
                    enrichedTrips = newTrips
                }
                trips.append(contentsOf: enrichedTrips)
                currentOffset += limit
                cachedGroupedTrips.removeAll()
            }
        } catch is CancellationError {
        } catch {
            errorMessage = "加载失败: \(error.localizedDescription)"
        }
        isLoading = false
    }

    func refresh() async {
        await loadTrips(reset: true)
    }

    func loadMoreIfNeeded(currentTrip: Trip?) async {
        guard let current = currentTrip else {
            if trips.isEmpty && hasMoreData {
                await loadTrips()
            }
            return
        }
        guard let last = trips.last, last.id == current.id, hasMoreData, !isLoading else { return }
        await loadTrips()
    }

    func groupTripsByDate() -> [(date: Date, trips: [Trip])] {
        var hasher = Hasher()
        for trip in trips {
            hasher.combine(trip.id)
        }
        let hash = hasher.finalize()
        if hash == lastTripsHash && !cachedGroupedTrips.isEmpty {
            return cachedGroupedTrips
        }
        let grouped = Dictionary(grouping: trips) { trip -> Date in
            Calendar.current.startOfDay(for: trip.startTime)
        }
        let result = grouped.sorted { $0.key > $1.key }.map { (date: $0.key, trips: $0.value) }
        cachedGroupedTrips = result
        lastTripsHash = hash
        return result
    }

    func updateTrip(_ updatedTrip: Trip) {
        if let index = trips.firstIndex(where: { $0.id == updatedTrip.id }) {
            trips[index] = updatedTrip
            cachedGroupedTrips.removeAll()
            lastTripsHash = 0
        }
    }
}
