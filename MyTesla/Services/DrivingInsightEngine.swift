//
//  DrivingInsightEngine.swift
//  TeslaMateApp
//

import Foundation

struct DrivingInsightEngine {
    static let minimumHistoricalCount = 20
    static let maxHistoricalCount = 100

    static func generateInsight(for trip: Trip, recentDrives: [Drive]) -> String? {
        if trip.distance < 3.0 {
            return nil
        }

        if recentDrives.count < minimumHistoricalCount {
            return fallbackInsight(for: trip)
        }

        let energyPct = percentile(
            value: trip.avgEnergy,
            in: recentDrives.map { $0.avgEnergy },
            higherIsBetter: false
        )
        let smoothPct = percentile(
            value: (trip.maxSpeed ?? 0) - (trip.avgSpeed ?? 0),
            in: recentDrives.map { ($0.maxSpeed ?? 0) - ($0.avgSpeed ?? 0) },
            higherIsBetter: false
        )
        let regenPct = percentile(
            value: trip.regenEnergy ?? 0,
            in: recentDrives.map { $0.regenEnergy ?? 0 },
            higherIsBetter: true
        )
        let climbPct: Int?
        if let elevation = trip.elevationGain, elevation > 0 {
            climbPct = percentile(
                value: elevation,
                in: recentDrives.map { $0.elevationGain ?? 0 }.filter { $0 > 0 },
                higherIsBetter: true
            )
        } else {
            climbPct = nil
        }

        let isCongested = (trip.avgSpeed ?? 0) < 20 && trip.duration > 15
        let isHighway = (trip.avgSpeed ?? 0) > 80
        let isCold = (trip.outsideTemp ?? 99) < 5

        var badges: [String] = []

        if !isCongested {
            if energyPct >= 90 { badges.append("⚡ 能效超越 \(energyPct)% 的行程") }
            else if energyPct >= 70 { badges.append("⚡ 能效超越 \(energyPct)% 的行程") }
            else if energyPct >= 40 { badges.append("⚡ 能效超越 \(energyPct)% 的行程") }
        }

        if !isHighway && !isCongested {
            if smoothPct >= 90 { badges.append("🛡️ 平稳性超越 \(smoothPct)% 的行程") }
            else if smoothPct >= 70 { badges.append("🛡️ 平稳性超越 \(smoothPct)% 的行程") }
            else if smoothPct >= 40 { badges.append("🛡️ 平稳性超越 \(smoothPct)% 的行程") }
        }

        if regenPct >= 90 { badges.append("♻️ 回收效率超越 \(regenPct)% 的行程") }
        else if regenPct >= 70 { badges.append("♻️ 回收效率超越 \(regenPct)% 的行程") }
        else if regenPct >= 40 { badges.append("♻️ 回收效率超越 \(regenPct)% 的行程") }

        if let climb = climbPct {
            if climb >= 90 { badges.append("⛰️ 爬坡超越 \(climb)% 的行程") }
            else if climb >= 70 { badges.append("⛰️ 爬坡超越 \(climb)% 的行程") }
        }

        let corePcts: [Int]
        if isHighway || isCongested {
            corePcts = [energyPct, regenPct]
        } else {
            corePcts = [energyPct, smoothPct, regenPct]
        }
        let avgPct = Double(corePcts.reduce(0, +)) / Double(corePcts.count)
        let overallBadge: String
        if avgPct >= 90 { overallBadge = "⭐⭐⭐ 全面卓越" }
        else if avgPct >= 70 { overallBadge = "⭐⭐ 表现优秀" }
        else if avgPct >= 40 { overallBadge = "⭐ 稳步提升" }
        else { overallBadge = "" }

        if !overallBadge.isEmpty {
            badges.insert(overallBadge, at: 0)
        }

        if isCold {
            badges.append("❄️ 低温环境，能耗正常偏高")
        }
        if isHighway {
            badges.append("🛣️ 高速行驶")
        }
        if isCongested {
            badges.append("🚦 拥堵路段，能耗正常偏高")
        }

        return badges.isEmpty ? nil : badges.joined(separator: " · ")
    }

    // 修正后的百分位计算
    private static func percentile(value: Double, in array: [Double], higherIsBetter: Bool) -> Int {
        guard !array.isEmpty else { return 0 }
        let sorted = array.sorted()
        let count = sorted.count
        let lowerCount = sorted.filter { $0 < value }.count
        let equalCount = sorted.filter { $0 == value }.count
        let greaterCount = count - lowerCount - equalCount

        let rank: Double
        if higherIsBetter {
            rank = Double(lowerCount) + Double(equalCount) / 2.0
        } else {
            rank = Double(greaterCount) + Double(equalCount) / 2.0
        }
        let pct = (rank / Double(count)) * 100.0
        return Int(pct.rounded())
    }

    private static func fallbackInsight(for trip: Trip) -> String? {
        var badges: [String] = []

        if trip.avgEnergy < 140 {
            badges.append("⚡ 黄金右脚")
        } else if trip.avgEnergy < 160 {
            badges.append("⚡ 能耗良好")
        }

        if let maxSpeed = trip.maxSpeed, let avgSpeed = trip.avgSpeed {
            let variance = maxSpeed - avgSpeed
            if variance < 30 {
                badges.append("🛡️ 安全跟车")
            }
        }

        if trip.avgEnergy < 155,
           let maxSpeed = trip.maxSpeed, let avgSpeed = trip.avgSpeed,
           (maxSpeed - avgSpeed) < 35 {
            badges.append("🚗 平顺驾驶")
        }

        if let regen = trip.regenEnergy, regen > 1.5 {
            badges.append("♻️ 高效回收")
        }

        if let elevation = trip.elevationGain, elevation > 50 && trip.avgEnergy < 160 {
            badges.append("⛰️ 爬坡能手")
        }

        if (trip.avgSpeed ?? 0) < 20 && trip.duration > 15 {
            badges.append("🚦 拥堵路段，能耗正常偏高")
        }
        if (trip.avgSpeed ?? 0) > 80 {
            badges.append("🛣️ 高速行驶")
        }

        return badges.isEmpty ? nil : badges.joined(separator: " · ")
    }
}
