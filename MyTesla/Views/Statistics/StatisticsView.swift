//
//  StatisticsView.swift
//  MyTesla
//

import SwiftUI
import SwiftData

struct StatisticsView: View {
    @StateObject private var viewModel = StatisticsViewModel()
    @Environment(\.modelContext) private var modelContext
    @State private var vehicleId: Int?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    if viewModel.isLoading {
                        LoadingView()
                    } else if let error = viewModel.errorMessage {
                        ErrorView(message: error) {
                            Task { await viewModel.loadStatistics() }
                        }
                    } else {
                        Group {
                            Text(viewModel.weeklyReview)
                                .font(.headline)
                                .padding()
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(.regularMaterial)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                            Text(viewModel.monthlyReview)
                                .font(.headline)
                                .padding()
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(.regularMaterial)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .padding(.horizontal)

                        if let week = viewModel.weekCompare {
                            PeriodCompareView(current: week.current, previous: week.previous, label: "本周里程")
                        }
                        if let month = viewModel.monthCompare {
                            PeriodCompareView(current: month.current, previous: month.previous, label: "本月里程")
                        }

                        StatisticsCalendarView(data: viewModel.calendarData)
                            .padding(.horizontal)

                        HeatmapView(data: viewModel.heatmapData)
                            .padding(.horizontal)

                        if !viewModel.chargeHistory.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("⚡ 充电历史")
                                    .font(.headline)
                                    .padding(.horizontal)

                                ForEach(viewModel.chargeHistory.prefix(20)) { charge in
                                    if let vehicleId = vehicleId {
                                        NavigationLink {
                                            ChargeDetailView(charge: charge, vehicleId: vehicleId)
                                        } label: {
                                            ChargeHistoryRow(charge: charge)
                                        }
                                        .buttonStyle(.plain)
                                    } else {
                                        ChargeHistoryRow(charge: charge)
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                            .padding(.vertical, 8)
                            .background(.regularMaterial)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .padding(.horizontal)
                        }

                        if !viewModel.localDrives.isEmpty || !viewModel.localCharges.isEmpty {
                            NavigationLink("查看地点洞察") {
                                let insights = PlaceInsightAggregator.aggregate(
                                    drives: viewModel.localDrives,
                                    charges: viewModel.localCharges
                                )
                                PlaceInsightsView(insights: Array(insights.values))
                            }
                            .padding()
                        }
                    }
                }
                .padding(.vertical)
            }
            .background(Color(.systemBackground))
            .navigationTitle("统计")
            .navigationBarTitleDisplayMode(.large)
            .refreshable {
                await viewModel.loadStatistics()
            }
            .task {
                await loadVehicleAndStats()
            }
        }
    }

    private func loadVehicleAndStats() async {
        do {
            let vehicles = try await APIClient.shared.getVehicles()
            if let first = vehicles.first {
                vehicleId = first.id
                viewModel.configure(context: modelContext, vehicleId: first.id)
                do {
                    let detail = try await APIClient.shared.getVehicle(carId: first.id)
                    let predicate = #Predicate<Vehicle> { $0.id == detail.id }
                    let existing = try modelContext.fetch(FetchDescriptor<Vehicle>(predicate: predicate))
                    if existing.isEmpty {
                        modelContext.insert(detail)
                    } else {
                        let v = existing.first!
                        v.name = detail.name
                        v.model = detail.model
                        v.softwareVersion = detail.softwareVersion
                        v.vin = detail.vin
                        v.carType = detail.carType
                        v.lastUpdated = Date()
                    }
                    try modelContext.save()
                } catch {
                    // 车辆详情同步失败不影响统计数据加载
                }
                await viewModel.loadStatistics()
            } else {
                viewModel.errorMessage = "未找到车辆，请检查 TeslaMate 配置"
            }
        } catch {
            viewModel.errorMessage = error.localizedDescription
        }
    }
}
