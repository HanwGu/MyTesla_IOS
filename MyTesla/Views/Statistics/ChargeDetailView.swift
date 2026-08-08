//
//  ChargeDetailView.swift
//  MyTesla
//

import SwiftUI
import SwiftData

struct ChargeDetailView: View {
    let charge: Charge
    let vehicleId: Int
    @StateObject private var viewModel = ChargeDetailViewModel()

    var body: some View {
        List {
            if viewModel.isLoading {
                Section {
                    HStack { Spacer(); ProgressView(); Spacer() }
                }
            } else if let error = viewModel.errorMessage {
                Section {
                    Text(error)
                        .foregroundColor(.secondary)
                }
            } else if let detail = viewModel.detail {
                Section("充电概况") {
                    DetailRow(label: "开始时间", value: detail.startTime.formatted(date: .abbreviated, time: .shortened))
                    DetailRow(label: "结束时间", value: detail.endTime.formatted(date: .abbreviated, time: .shortened))
                    let duration = Int(detail.endTime.timeIntervalSince(detail.startTime) / 60)
                    DetailRow(label: "充电时长", value: duration > 0 ? "\(duration) 分钟" : "< 1 分钟")
                    DetailRow(label: "位置", value: detail.address ?? "未知")
                    DetailRow(label: "SOC变化", value: "\(detail.socStart)% → \(detail.socEnd)%")
                    DetailRow(label: "充电量", value: "\(Int(detail.energyAdded)) kWh")
                    if let avgPower = detail.avgPower {
                        DetailRow(label: "平均功率", value: "\(String(format: "%.1f", avgPower)) kW")
                    }
                    if let maxPower = detail.maxPower {
                        DetailRow(label: "最高功率", value: "\(String(format: "%.1f", maxPower)) kW")
                    }
                    if let cost = detail.cost {
                        DetailRow(label: "费用", value: "¥\(String(format: "%.2f", cost))")
                    }
                    if let parkingCost = detail.parkingCost {
                        DetailRow(label: "停车费", value: "¥\(String(format: "%.2f", parkingCost))")
                    }
                    if let startRange = detail.startIdealRange, let endRange = detail.endIdealRange {
                        let gained = endRange - startRange
                        DetailRow(label: "续航增加", value: "+\(Int(gained)) km（\(Int(startRange)) km → \(Int(endRange)) km）")
                    }
                    if let outsideTemp = detail.outsideTemp {
                        DetailRow(label: "车外温度", value: "\(Int(outsideTemp))°C")
                    }
                    if let insideTemp = detail.insideTemp {
                        DetailRow(label: "车内温度", value: "\(Int(insideTemp))°C")
                    }
                }
            } else {
                Section {
                    Text("暂无充电详情数据")
                        .foregroundColor(.secondary)
                }
            }
        }
        .navigationTitle("充电详情")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            viewModel.configure(vehicleId: vehicleId, chargeId: charge.id)
            await viewModel.loadDetail()
        }
    }
}
