//
//  MapView.swift
//  MyTesla
//

import SwiftUI
import SwiftData
import MapKit
import CoreLocation

struct MapView: View {
    @StateObject private var viewModel = MapViewModel()
    @State private var position = MapCameraPosition.automatic
    @State private var locationManager = CLLocationManager()
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        NavigationStack {
            Map(position: $position) {
                ForEach(viewModel.routes, id: \.self) { route in
                    MapPolyline(route)
                        .stroke(.blue, lineWidth: 3)
                }
                ForEach(viewModel.chargeAnnotations) { annotation in
                    Annotation(annotation.title ?? "充电点", coordinate: annotation.coordinate) {
                        Image(systemName: "bolt.circle.fill")
                            .foregroundColor(.green)
                            .background(Circle().fill(.white).frame(width: 24, height: 24))
                    }
                }
            }
            .mapControls {
                MapUserLocationButton()
            }
            .onAppear {
                locationManager.requestWhenInUseAuthorization()
            }
            .navigationTitle("地图")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button("全部") {
                            viewModel.showOnlyCharges = false
                            viewModel.applyFilters()
                            updateCameraPosition()
                        }
                        Button("仅充电点") {
                            viewModel.showOnlyCharges = true
                            viewModel.applyFilters()
                            updateCameraPosition()
                        }
                    } label: {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                    }
                }
            }
            .overlay {
                if viewModel.isLoading {
                    ProgressView()
                }
            }
            .task {
                await loadMapData()
            }
            .onChange(of: viewModel.cachedRegion) { _, newRegion in
                if let region = newRegion {
                    position = .region(region)
                }
            }
        }
    }

    private func loadMapData() async {
        do {
            let vehicles = try await APIClient.shared.getVehicles()
            if let first = vehicles.first {
                do {
                    let detail = try await APIClient.shared.getVehicle(carId: first.id)
                    let existingVehicles = try modelContext.fetch(FetchDescriptor<Vehicle>())
                    if let existing = existingVehicles.first(where: { $0.id == detail.id }) {
                        existing.name = detail.name
                        existing.model = detail.model
                        existing.softwareVersion = detail.softwareVersion
                        existing.vin = detail.vin
                        existing.carType = detail.carType
                        existing.lastUpdated = Date()
                    } else {
                        modelContext.insert(detail)
                    }
                    try modelContext.save()
                } catch {
                    // 车辆详情同步失败不影响地图数据加载
                }
                viewModel.configure(vehicleId: first.id)
                await viewModel.loadMapData()
                updateCameraPosition()
            } else {
                viewModel.errorMessage = "未找到车辆，请检查 TeslaMate 配置"
            }
        } catch {
            viewModel.errorMessage = error.localizedDescription
        }
    }

    private func updateCameraPosition() {
        if let region = viewModel.cachedRegion {
            position = .region(region)
        }
    }
}
