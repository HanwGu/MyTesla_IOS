//
//  TripDetailView.swift
//  MyTesla
//

import SwiftUI
import SwiftData

struct TripDetailView: View {
    let trip: Trip
    let vehicleId: Int
    let onSave: (Trip) -> Void
    @StateObject private var viewModel = TripDetailViewModel()
    @State private var showingEditSheet = false
    @State private var displayCategory: String?
    @State private var displayNote: String?
    @Environment(\.modelContext) private var modelContext

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
                Section("行程概况") {
                    DetailRow(label: "起点", value: detail.startAddress ?? "未知")
                    DetailRow(label: "终点", value: detail.endAddress ?? "未知")
                    DetailRow(label: "距离", value: "\(String(format: "%.1f", detail.distance)) km")
                    DetailRow(label: "用时", value: detail.duration > 0 ? "\(detail.duration) 分钟" : "< 1 分钟")
                    DetailRow(label: "平均能耗", value: "\(Int(detail.avgEnergy)) Wh/km")
                    if let maxSpeed = detail.maxSpeed {
                        DetailRow(label: "最高时速", value: "\(Int(maxSpeed)) km/h")
                    }
                    if let avgSpeed = detail.avgSpeed {
                        DetailRow(label: "平均时速", value: "\(Int(avgSpeed)) km/h")
                    }
                    if let elevation = detail.elevationGain {
                        DetailRow(label: "海拔爬升", value: "\(Int(elevation)) 米")
                    }
                    if let startRange = detail.startIdealRange, let endRange = detail.endIdealRange {
                        let consumed = startRange - endRange
                        DetailRow(label: "续航消耗", value: "\(Int(consumed)) km（\(Int(startRange)) km → \(Int(endRange)) km）")
                    }
                    if let insideTemp = detail.insideTemp {
                        DetailRow(label: "车内温度", value: "\(Int(insideTemp))°C")
                    }
                    if let outsideTemp = detail.outsideTemp {
                        DetailRow(label: "车外温度", value: "\(Int(outsideTemp))°C")
                    }
                }

                Section("驾驶评价") {
                    if let badge = trip.insightBadge {
                        Text(badge)
                            .font(.headline)
                            .foregroundColor(.blue)
                    } else {
                        Text("暂无评价数据")
                            .font(.headline)
                            .foregroundColor(.secondary)
                    }
                }

                Section("备注与分类") {
                    HStack {
                        Text("分类")
                        Spacer()
                        Text(displayCategory ?? "未分类")
                            .foregroundColor(.secondary)
                    }
                    HStack {
                        Text("备注")
                        Spacer()
                        Text(displayNote ?? "无")
                            .foregroundColor(.secondary)
                    }
                    Button("编辑") {
                        showingEditSheet = true
                    }
                }
            } else {
                Section {
                    Text("暂无行程详情数据")
                        .foregroundColor(.secondary)
                }
            }
        }
        .navigationTitle("行程详情")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingEditSheet) {
            TripEditView(trip: trip, onSave: { updatedTrip in
                displayCategory = updatedTrip.category
                displayNote = updatedTrip.note
                onSave(updatedTrip)
            })
        }
        .onAppear {
            loadDriveData()
        }
        .onChange(of: showingEditSheet) { _, newValue in
            if !newValue {
                loadDriveData()
            }
        }
        .task {
            viewModel.configure(vehicleId: vehicleId, driveId: trip.id)
            await viewModel.loadDetail()
        }
    }

    private func loadDriveData() {
        let predicate = #Predicate<Drive> { $0.id == trip.id }
        let descriptor = FetchDescriptor<Drive>(predicate: predicate)
        if let drive = try? modelContext.fetch(descriptor).first {
            displayCategory = drive.category
            displayNote = drive.note
        } else {
            displayCategory = nil
            displayNote = nil
        }
    }
}

struct DetailRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .monospacedDigit()
        }
    }
}

struct TripEditView: View {
    let trip: Trip
    let onSave: (Trip) -> Void
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var category: String = ""
    @State private var note: String = ""
    @State private var driveToEdit: Drive?
    @State private var isLoading = true

    var body: some View {
        NavigationStack {
            Form {
                if isLoading {
                    ProgressView()
                } else {
                    TextField("分类 (通勤/个人/商务)", text: $category)
                    TextField("备注", text: $note)
                }
            }
            .navigationTitle("编辑行程")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        saveChanges()
                        dismiss()
                    }
                    .disabled(isLoading)
                }
            }
            .onAppear {
                loadDrive()
            }
        }
    }

    private func loadDrive() {
        let predicate = #Predicate<Drive> { $0.id == trip.id }
        let descriptor = FetchDescriptor<Drive>(predicate: predicate)
        if let drive = try? modelContext.fetch(descriptor).first {
            driveToEdit = drive
            category = drive.category ?? ""
            note = drive.note ?? ""
        }
        isLoading = false
    }

    private func saveChanges() {
        guard let drive = driveToEdit else { return }
        drive.category = category.isEmpty ? nil : category
        drive.note = note.isEmpty ? nil : note
        try? modelContext.save()

        var updatedTrip = trip
        updatedTrip.category = drive.category
        updatedTrip.note = drive.note
        onSave(updatedTrip)
    }
}
