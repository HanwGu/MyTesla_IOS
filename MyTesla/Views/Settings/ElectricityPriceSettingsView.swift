//
//  ElectricityPriceSettingsView.swift
//  MyTesla
//

import SwiftUI
import SwiftData

struct ElectricityPriceSettingsView: View {
    let settingsViewModel: SettingsViewModel
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \ElectricityPrice.startHour) private var prices: [ElectricityPrice]
    @State private var showingAddSheet = false

    var body: some View {
        List {
            ForEach(prices) { price in
                HStack {
                    Text(price.name)
                        .font(.headline)
                    Spacer()
                    Text("\(price.startHour):00 - \(price.endHour):00")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(String(format: "%.2f", price.pricePerKwh))元/kWh")
                        .font(.subheadline)
                        .monospacedDigit()
                }
            }
            .onDelete(perform: deletePrices)
        }
        .navigationTitle("分时电价")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("添加") { showingAddSheet = true }
            }
        }
        .sheet(isPresented: $showingAddSheet) {
            AddPriceView()
        }
        .onAppear {
            settingsViewModel.modelContext = modelContext
        }
    }

    private func deletePrices(offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(prices[index])
        }
        try? modelContext.save()
        Task {
            await settingsViewModel.batchUpdateCosts()
        }
    }
}

struct AddPriceView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var startHour = 8
    @State private var endHour = 10
    @State private var price = ""

    var body: some View {
        NavigationStack {
            Form {
                TextField("时段名称", text: $name)
                Stepper("开始时间: \(startHour):00", value: $startHour, in: 0...23)
                Stepper("结束时间: \(endHour):00", value: $endHour, in: 0...23)
                TextField("电价 (元/kWh)", text: $price)
                    .keyboardType(.decimalPad)
            }
            .navigationTitle("添加电价时段")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        guard let p = Double(price) else { return }
                        let newPrice = ElectricityPrice(name: name, startHour: startHour, endHour: endHour, pricePerKwh: p)
                        modelContext.insert(newPrice)
                        try? modelContext.save()
                        dismiss()
                    }
                    .disabled(name.isEmpty || price.isEmpty)
                }
            }
        }
    }
}
