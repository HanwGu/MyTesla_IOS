//
//  DashboardViewModel.swift
//  TeslaMateApp
//

import SwiftUI
import SwiftData

@MainActor
class DashboardViewModel: ObservableObject {
    @Published var status: VehicleStatus?
    @Published var recentDrive: Drive?
    @Published var vehicleDetail: Vehicle?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var lastUpdated: Date?
    @Published var cardOrder: [CardType] = [.battery, .statusGrid, .location]

    enum CardType {
        case vehicleInfo, battery, charging, drivingSummary, statusGrid, location
    }

    private var modelContext: ModelContext?
    private var vehicleId: Int?

    func configure(context: ModelContext, vehicleId: Int) {
        self.modelContext = context
        self.vehicleId = vehicleId
    }

    func refresh() async {
        guard let vehicleId = vehicleId, let context = modelContext else {
            errorMessage = "未配置车辆或数据库"
            return
        }
        isLoading = true
        errorMessage = nil

        do {
            try Task.checkCancellation()

            // 1. 车辆详情（独立 do-catch）
            do {
                let detail = try await APIClient.shared.getVehicle(carId: vehicleId)
                let existingVehicles = try context.fetch(FetchDescriptor<Vehicle>())
                if let existing = existingVehicles.first(where: { $0.id == detail.id }) {
                    existing.name = detail.name
                    existing.model = detail.model
                    existing.softwareVersion = detail.softwareVersion
                    existing.vin = detail.vin
                    existing.carType = detail.carType
                    existing.lastUpdated = Date()
                } else {
                    context.insert(detail)
                }
                self.vehicleDetail = detail
            } catch {
                // 忽略
            }

            // 2. 车辆状态（核心数据）
            let status = try await APIClient.shared.getVehicleStatus(carId: vehicleId)
            self.status = status
            self.lastUpdated = Date()

            // 3. 充电记录（独立 do-catch）
            do {
                let charges = try await APIClient.shared.getCharges(carId: vehicleId, limit: 200, offset: 0)
                let geofences = try context.fetch(FetchDescriptor<Geofence>())
                let prices = try context.fetch(FetchDescriptor<ElectricityPrice>())
                let existingCharges = try context.fetch(FetchDescriptor<Charge>())
                for charge in charges {
                    if let existing = existingCharges.first(where: { $0.id == charge.id }) {
                        existing.energyAdded = charge.energyAdded
                        existing.startTime = charge.startTime
                        existing.endTime = charge.endTime
                        existing.positionLat = charge.positionLat
                        existing.positionLon = charge.positionLon
                        existing.address = charge.address
                        existing.socStart = charge.socStart
                        existing.socEnd = charge.socEnd
                        existing.maxPower = charge.maxPower
                        existing.avgPower = charge.avgPower
                        if existing.cost == nil {
                            existing.cost = CostCalculator.calculateCost(charge: charge, geofences: geofences, prices: prices)
                        }
                    } else {
                        charge.cost = CostCalculator.calculateCost(charge: charge, geofences: geofences, prices: prices)
                        context.insert(charge)
                    }
                }
                try context.save()
            } catch {
                // 忽略
            }

            // 4. 同步最近行程（1条）
            do {
                let trips = try await APIClient.shared.getDrives(carId: vehicleId, limit: 1, offset: 0)
                if let lastTrip = trips.first {
                    // 获取历史行程（已排序，最多100条）
                    var historicalDescriptor = FetchDescriptor<Drive>(
                        sortBy: [SortDescriptor(\Drive.startTime, order: .reverse)]
                    )
                    historicalDescriptor.fetchLimit = DrivingInsightEngine.maxHistoricalCount
                    let historicalDrives = try context.fetch(historicalDescriptor)

                    let existingDrives = try context.fetch(FetchDescriptor<Drive>())
                    if let existing = existingDrives.first(where: { $0.id == lastTrip.id }) {
                        existing.startTime = lastTrip.startTime
                        existing.endTime = lastTrip.endTime
                        existing.startAddress = lastTrip.startAddress
                        existing.endAddress = lastTrip.endAddress
                        existing.distance = lastTrip.distance
                        existing.avgEnergy = lastTrip.avgEnergy
                        existing.duration = lastTrip.duration
                        existing.maxSpeed = lastTrip.maxSpeed
                        existing.avgSpeed = lastTrip.avgSpeed
                        existing.regenEnergy = lastTrip.regenEnergy
                        existing.elevationGain = lastTrip.elevationGain
                        existing.outsideTemp = status.outsideTemp
                        existing.insightBadge = DrivingInsightEngine.generateInsight(
                            for: lastTrip,
                            recentDrives: historicalDrives
                        )
                        self.recentDrive = existing
                    } else {
                        let drive = Drive(
                            id: lastTrip.id,
                            startTime: lastTrip.startTime,
                            endTime: lastTrip.endTime,
                            startAddress: lastTrip.startAddress,
                            endAddress: lastTrip.endAddress,
                            distance: lastTrip.distance,
                            avgEnergy: lastTrip.avgEnergy,
                            duration: lastTrip.duration,
                            maxSpeed: lastTrip.maxSpeed,
                            avgSpeed: lastTrip.avgSpeed,
                            regenEnergy: lastTrip.regenEnergy,
                            elevationGain: lastTrip.elevationGain,
                            outsideTemp: status.outsideTemp
                        )
                        drive.insightBadge = DrivingInsightEngine.generateInsight(
                            for: lastTrip,
                            recentDrives: historicalDrives
                        )
                        context.insert(drive)
                        self.recentDrive = drive
                    }
                    try context.save()
                }
            } catch {
                // 忽略
            }

            updateCardOrder(status: status)

        } catch is CancellationError {
            // 取消
        } catch {
            errorMessage = "刷新失败: \(error.localizedDescription)"
        }

        isLoading = false
    }

    private func updateCardOrder(status: VehicleStatus) {
        var order: [CardType] = []
        if vehicleDetail != nil {
            order.append(.vehicleInfo)
        }
        if status.isCharging {
            order.append(.charging)
        }
        if let drive = recentDrive {
            let elapsed = Date().timeIntervalSince(drive.endTime)
            if elapsed < Constants.drivingSummaryExpiryHours * 3600 {
                order.append(.drivingSummary)
            }
        }
        order.append(contentsOf: [.battery, .statusGrid, .location])
        withAnimation(.easeInOut) {
            cardOrder = order
        }
    }
}
