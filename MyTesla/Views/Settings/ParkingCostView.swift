//
//  ParkingCostView.swift
//  MyTesla
//

import SwiftUI
import SwiftData

struct ParkingCostView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Charge.startTime, order: .reverse) private var charges: [Charge]
    @State private var editingChargeId: Int?
    @State private var editingCost: String = ""

    var body: some View {
        List {
            ForEach(charges) { charge in
                HStack {
                    VStack(alignment: .leading) {
                        Text(charge.address ?? "未知位置")
                            .font(.headline)
                        Text(charge.startTime.formatted(date: .abbreviated, time: .shortened))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    if editingChargeId == charge.id {
                        TextField("停车费", text: $editingCost)
                            .keyboardType(.decimalPad)
                            .frame(width: 80)
                            .textFieldStyle(.roundedBorder)
                        Button("保存") {
                            if let cost = Double(editingCost) {
                                charge.parkingCost = cost
                                try? modelContext.save()
                            }
                            editingChargeId = nil
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.small)
                    } else {
                        Text(charge.parkingCost.map { "\(String(format: "%.2f", $0))元" } ?? "未记录")
                            .foregroundColor(charge.parkingCost != nil ? .primary : .secondary)
                        Button("编辑") {
                            editingCost = charge.parkingCost.map { String(format: "%.2f", $0) } ?? ""
                            editingChargeId = charge.id
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                    }
                }
                .padding(.vertical, 4)
            }
        }
        .navigationTitle("停车费用")
        .navigationBarTitleDisplayMode(.inline)
        .onDisappear {
            editingChargeId = nil
        }
    }
}
