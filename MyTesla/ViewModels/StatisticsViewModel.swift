//
//  StatisticsViewModel.swift
//  TeslaMateApp
//

import SwiftUI
import SwiftData

@MainActor
class StatisticsViewModel: ObservableObject {
    @Published var weekCompare: (current: Double, previous: Double, percentage: Double)?
    @Published var monthCompare: (current: Double, previous: Double, percentage: Double)?
    @Published var calendarData: [Date: (distance: Double, energy: Double, cost: Double)] = [:]
    @Published var heatmapData: [Date: Double] = [:]
    @Published var batteryHealthHistory: [(date: Date, capacity: Double, range: Double)] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var weeklyReview: String = ""
    @Published var monthlyReview: String = ""
    @Published var localDrives: [Drive] = []
    @Published var localCharges: [Charge] = []
    @Published var chargeHistory: [Charge] = []

    private var vehicleId: Int?
    private var modelContext: ModelContext?

    func configure(context: ModelContext, vehicleId: Int) {
        self.modelContext = context
        self.vehicleId = vehicleId
    }

    func loadStatistics() async {
        guard let vehicleId = vehicleId, let context = modelContext else {
            errorMessage = "未配置车辆或数据库"
            return
        }
        isLoading = true
        errorMessage = nil

        do {
            try Task.checkCancellation()

            let oneYearAgo = Calendar.current.date(byAdding: .year, value: -1, to: Date())!
            let allDrives = try context.fetch(FetchDescriptor<Drive>())
            let allCharges = try context.fetch(FetchDescriptor<Charge>())
            let drives = allDrives.filter { $0.startTime >= oneYearAgo }
            let charges = allCharges.filter { $0.startTime >= oneYearAgo }
            self.localDrives = drives
            self.localCharges = charges
            self.chargeHistory = charges.sorted { $0.startTime > $1.startTime }

            if drives.count < 10 {
                let newTrips = try await APIClient.shared.getDrives(carId: vehicleId, limit: 500, offset: 0)
                let newCharges = try await APIClient.shared.getCharges(carId: vehicleId, limit: 500, offset: 0)

                // 获取排序后的历史数据用于生成徽章
                let sortedDrives = drives.sorted { $0.startTime > $1.startTime }
                let recentDrives = Array(sortedDrives.prefix(DrivingInsightEngine.maxHistoricalCount))

                let persistedDrives = try context.fetch(FetchDescriptor<Drive>())
                let persistedCharges = try context.fetch(FetchDescriptor<Charge>())
                for trip in newTrips {
                    if persistedDrives.contains(where: { $0.id == trip.id }) {
                        continue
                    }
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
                        recentDrives: recentDrives
                    )
                    context.insert(drive)
                }
                for charge in newCharges {
                    if persistedCharges.contains(where: { $0.id == charge.id }) {
                        continue
                    }
                    context.insert(charge)
                }
                try context.save()
                self.localDrives = try context.fetch(FetchDescriptor<Drive>()).filter { $0.startTime >= oneYearAgo }
                self.localCharges = try context.fetch(FetchDescriptor<Charge>()).filter { $0.startTime >= oneYearAgo }
                self.chargeHistory = self.localCharges.sorted { $0.startTime > $1.startTime }
            }

            // 电池健康数据：独立 do-catch
            do {
                let batteryHealth = try await APIClient.shared.getBatteryHealth(carId: vehicleId)
                let newEntry = (date: batteryHealth.date, capacity: Double(batteryHealth.batteryLevel), range: batteryHealth.range)
                var history = self.batteryHealthHistory
                history.removeAll { Calendar.current.isDate($0.date, inSameDayAs: newEntry.date) }
                history.append(newEntry)
                self.batteryHealthHistory = history.sorted { $0.date > $1.date }
            } catch {
                // 静默失败
            }

            let drivesCopy = self.localDrives
            let chargesCopy = self.localCharges
            let stats = StatisticsViewModel.computeStatistics(drives: drivesCopy, charges: chargesCopy)

            self.weekCompare = stats.weekCompare
            self.monthCompare = stats.monthCompare
            self.calendarData = stats.calendarData
            self.heatmapData = stats.heatmapData
            self.weeklyReview = stats.weeklyReview
            self.monthlyReview = stats.monthlyReview

        } catch is CancellationError {
        } catch {
            errorMessage = "加载统计失败: \(error.localizedDescription)"
        }
        isLoading = false
    }

    static func computeStatistics(drives: [Drive], charges: [Charge]) -> (weekCompare: (Double, Double, Double)?, monthCompare: (Double, Double, Double)?, calendarData: [Date: (Double, Double, Double)], heatmapData: [Date: Double], weeklyReview: String, monthlyReview: String) {
        let calendar = Calendar.current
        let now = Date()

        let thisWeekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now))!
        let lastWeekStart = calendar.date(byAdding: .weekOfYear, value: -1, to: thisWeekStart)!
        let thisWeekEnd = calendar.date(byAdding: .day, value: 7, to: thisWeekStart)!
        let thisWeekDrives = drives.filter(in: thisWeekStart..<thisWeekEnd)
        let lastWeekDrives = drives.filter(in: lastWeekStart..<thisWeekStart)
        let thisWeekDist = thisWeekDrives.reduce(0) { $0 + $1.distance }
        let lastWeekDist = lastWeekDrives.reduce(0) { $0 + $1.distance }
        let weekPct = lastWeekDist > 0 ? ((thisWeekDist - lastWeekDist) / lastWeekDist) * 100 : 0
        let weekCompare = (thisWeekDist, lastWeekDist, weekPct)

        let thisMonthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: now))!
        let lastMonthStart = calendar.date(byAdding: .month, value: -1, to: thisMonthStart)!
        let thisMonthEnd = calendar.date(byAdding: .month, value: 1, to: thisMonthStart)!
        let thisMonthDrives = drives.filter(in: thisMonthStart..<thisMonthEnd)
        let lastMonthDrives = drives.filter(in: lastMonthStart..<thisMonthStart)
        let thisMonthDist = thisMonthDrives.reduce(0) { $0 + $1.distance }
        let lastMonthDist = lastMonthDrives.reduce(0) { $0 + $1.distance }
        let monthPct = lastMonthDist > 0 ? ((thisMonthDist - lastMonthDist) / lastMonthDist) * 100 : 0
        let monthCompare = (thisMonthDist, lastMonthDist, monthPct)

        let thirtyDaysAgo = calendar.date(byAdding: .day, value: -30, to: now)!
        let recentDrives = drives.filter(in: thirtyDaysAgo..<Date())
        var calData: [Date: (Double, Double, Double)] = [:]
        for drive in recentDrives {
            let day = calendar.startOfDay(for: drive.startTime)
            let existing = calData[day] ?? (0, 0, 0)
            calData[day] = (existing.0 + drive.distance, existing.1 + drive.avgEnergy, existing.2)
        }

        let yearStart = calendar.date(from: DateComponents(year: calendar.component(.year, from: now), month: 1, day: 1))!
        let yearEnd = calendar.date(byAdding: .year, value: 1, to: yearStart)!
        let yearDrives = drives.filter(in: yearStart..<yearEnd)
        var heatData: [Date: Double] = [:]
        for drive in yearDrives {
            let day = calendar.startOfDay(for: drive.startTime)
            heatData[day] = (heatData[day] ?? 0) + drive.distance
        }

        let weeklyReview = weekCompare.2 != 0 ? "本周总里程 \(String(format: "%.1f", weekCompare.0))km，环比\(weekCompare.2 >= 0 ? "上升" : "下降")\(String(format: "%.0f", abs(weekCompare.2)))%" : "暂无本周数据"
        let monthlyReview = monthCompare.2 != 0 ? "本月总里程 \(String(format: "%.1f", monthCompare.0))km，环比\(monthCompare.2 >= 0 ? "上升" : "下降")\(String(format: "%.0f", abs(monthCompare.2)))%" : "暂无本月数据"

        return (weekCompare, monthCompare, calData, heatData, weeklyReview, monthlyReview)
    }
}
