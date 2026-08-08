//
//  GeofenceSettingsView.swift
//  MyTesla
//

import SwiftUI
import SwiftData

struct GeofenceSettingsView: View {
    let settingsViewModel: SettingsViewModel
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Geofence.name) private var geofences: [Geofence]
    @State private var showingAddSheet = false

    var body: some View {
        List {
            ForEach(geofences) { fence in
                VStack(alignment: .leading) {
                    Text(fence.name)
                        .font(.headline)
                    Text("纬度: \(String(format: "%.4f", fence.latitude)), 经度: \(String(format: "%.4f", fence.longitude))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("半径: \(Int(fence.radius))米")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .onDelete(perform: deleteGeofences)
        }
        .navigationTitle("地理围栏")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("添加") { showingAddSheet = true }
            }
        }
        .sheet(isPresented: $showingAddSheet) {
            AddGeofenceView()
        }
        .onAppear {
            settingsViewModel.modelContext = modelContext
        }
    }

    private func deleteGeofences(offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(geofences[index])
        }
        try? modelContext.save()
        Task {
            await settingsViewModel.batchUpdateCosts()
        }
    }
}

struct AddGeofenceView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var latitude = ""
    @State private var longitude = ""
    @State private var radius = "100"

    var body: some View {
        NavigationStack {
            Form {
                TextField("名称", text: $name)
                TextField("纬度", text: $latitude)
                    .keyboardType(.decimalPad)
                TextField("经度", text: $longitude)
                    .keyboardType(.decimalPad)
                TextField("半径(米)", text: $radius)
                    .keyboardType(.numberPad)
            }
            .navigationTitle("添加围栏")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        guard let lat = Double(latitude),
                              let lon = Double(longitude),
                              let rad = Double(radius) else { return }
                        let fence = Geofence(name: name, latitude: lat, longitude: lon, radius: rad)
                        modelContext.insert(fence)
                        try? modelContext.save()
                        dismiss()
                    }
                    .disabled(name.isEmpty || latitude.isEmpty || longitude.isEmpty)
                }
            }
        }
    }
}
