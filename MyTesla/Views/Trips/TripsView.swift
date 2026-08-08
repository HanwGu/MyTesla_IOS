//
//  TripsView.swift
//  MyTesla
//

import SwiftUI
import SwiftData

struct TripsView: View {
    @StateObject private var viewModel = TripsViewModel()
    @Environment(\.modelContext) private var modelContext
    @State private var vehicleId: Int?

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading && viewModel.trips.isEmpty {
                    LoadingView()
                } else if let error = viewModel.errorMessage {
                    ErrorView(message: error) {
                        Task { await viewModel.refresh() }
                    }
                } else {
                    List {
                        ForEach(viewModel.groupTripsByDate(), id: \.date) { group in
                            Section(header: Text(group.date.formatted(date: .abbreviated, time: .omitted))) {
                                ForEach(group.trips) { trip in
                                    if let vehicleId = vehicleId {
                                        NavigationLink {
                                            TripDetailView(
                                                trip: trip,
                                                vehicleId: vehicleId,
                                                onSave: { updatedTrip in
                                                    viewModel.updateTrip(updatedTrip)
                                                }
                                            )
                                        } label: {
                                            TripRow(trip: trip)
                                        }
                                    } else {
                                        TripRow(trip: trip)
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                        }
                        if viewModel.hasMoreData {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                                .onAppear {
                                    if let lastTrip = viewModel.trips.last {
                                        Task { await viewModel.loadMoreIfNeeded(currentTrip: lastTrip) }
                                    } else {
                                        Task { await viewModel.loadMoreIfNeeded(currentTrip: nil) }
                                    }
                                }
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("行程")
            .navigationBarTitleDisplayMode(.large)
            .refreshable {
                await viewModel.refresh()
            }
            .task {
                await loadVehicleAndTrips()
            }
        }
    }

    private func loadVehicleAndTrips() async {
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
                    // 车辆详情同步失败不影响行程列表加载
                }
                await viewModel.loadTrips()
            } else {
                viewModel.errorMessage = "未找到车辆，请检查 TeslaMate 配置"
            }
        } catch {
            viewModel.errorMessage = error.localizedDescription
        }
    }
}
