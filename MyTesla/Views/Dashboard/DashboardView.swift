//
//  DashboardView.swift
//  MyTesla
//

import SwiftUI
import SwiftData

struct DashboardView: View {
    @StateObject private var viewModel = DashboardViewModel()
    @Environment(\.modelContext) private var modelContext
    @State private var vehicleId: Int?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 12) {
                    if viewModel.isLoading && viewModel.status == nil {
                        LoadingView()
                    } else if let error = viewModel.errorMessage {
                        ErrorView(message: error) {
                            Task { await viewModel.refresh() }
                        }
                    } else {
                        ForEach(viewModel.cardOrder, id: \.self) { cardType in
                            switch cardType {
                            case .vehicleInfo:
                                if let vehicle = viewModel.vehicleDetail {
                                    VehicleInfoCard(vehicle: vehicle)
                                }
                            case .battery:
                                if let status = viewModel.status {
                                    BatteryCard(status: status)
                                }
                            case .charging:
                                if let status = viewModel.status, status.isCharging {
                                    ChargingCard(status: status)
                                }
                            case .drivingSummary:
                                if let drive = viewModel.recentDrive {
                                    DrivingSummaryCard(drive: drive)
                                }
                            case .statusGrid:
                                if let status = viewModel.status {
                                    StatusGridCard(status: status)
                                }
                            case .location:
                                if let status = viewModel.status {
                                    LocationCard(status: status)
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
            }
            .background(Color(.systemBackground))
            .refreshable {
                await viewModel.refresh()
            }
            .navigationTitle("MyTesla")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    if let lastUpdated = viewModel.lastUpdated {
                        Text(lastUpdated.timeAgoDisplay())
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .task {
                await loadVehicleAndRefresh()
            }
        }
    }

    private func loadVehicleAndRefresh() async {
        do {
            let vehicles = try await APIClient.shared.getVehicles()
            if let first = vehicles.first {
                vehicleId = first.id
                viewModel.configure(context: modelContext, vehicleId: first.id)
                await viewModel.refresh()
            } else {
                viewModel.errorMessage = "未找到车辆，请检查 TeslaMate 配置"
            }
        } catch {
            viewModel.errorMessage = error.localizedDescription
        }
    }
}
