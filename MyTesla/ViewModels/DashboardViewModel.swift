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
                let predicate = #Predicate<Vehicle> { $0.id == detail.id }
                let existing = try context.fetch(FetchDescriptor<Vehicle>(predicate: predicate))
                if existing.isEmpty {
                    context.insert(detail)
                } else {
                    let v = existing.first!
                    v.name = detail.name
                    v.model = detail.model
                    v.softwareVersion = detail.softwareVersion
                    v.vin = detail.vin
                    v.carType = detail.carType
                    v.lastUpdated = Date()
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
                for charge in charges {
                    let predicate = #Predicate<Charge> { $0.id == charge.id }
                    let existing = try context.fetch(FetchDescriptor<Charge>(predicate: predicate))
                    if existing.isEmpty {
                        charge.cost = CostCalculator.calculateCost(charge: charge, geofences: geofences, prices: prices)
                        context.insert(charge)
                    } else {
                        let c = existing.first!
                        c.energyAdded = charge.energyAdded
                        c.startTime = charge.startTime
                        c.endTime = charge.endTime
                        c.positionLat = charge.positionLat
                        c.positionLon = charge.positionLon
                        c.address = charge.address
                        c.socStart = charge.socStart
                        c.socEnd = charge.socEnd
                        c.maxPower = charge.maxPower
                        c.avgPower = charge.avgPower
                        if c.cost == nil {
                            c.cost = CostCalculator.calculateCost(charge: charge, geofences: geofences, prices: prices)
                        }
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
                    let historicalDescriptor = FetchDescriptor<Drive>(
                        sortBy: [SortDescriptor(\Drive.startTime, order: .reverse)]
                    )
                    historicalDescriptor.fetchLimit = DrivingInsightEngine.maxHistoricalCount
                    let historicalDrives = try context.fetch(historicalDescriptor)

                    let predicate = #Predicate<Drive> { $0.id == lastTrip.id }
                    let existing = try context.fetch(FetchDescriptor<Drive>(predicate: predicate))
                    if existing.isEmpty {
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
                    } else {
                        let drive = existing.first!
                        drive.startTime = lastTrip.startTime
                        drive.endTime = lastTrip.endTime
                        drive.startAddress = lastTrip.startAddress
                        drive.endAddress = lastTrip.endAddress
                        drive.distance = lastTrip.distance
                        drive.avgEnergy = lastTrip.avgEnergy
                        drive.duration = lastTrip.duration
                        drive.maxSpeed = lastTrip.maxSpeed
                        drive.avgSpeed = lastTrip.avgSpeed
                        drive.regenEnergy = lastTrip.regenEnergy
                        drive.elevationGain = lastTrip.elevationGain
                        drive.outsideTemp = status.outsideTemp
                        drive.insightBadge = DrivingInsightEngine.generateInsight(
                            for: lastTrip,
                            recentDrives: historicalDrives
                        )
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
