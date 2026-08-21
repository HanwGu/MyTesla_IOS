//
//  SettingsViewModel.swift
//  TeslaMateApp
//

import SwiftUI
import SwiftData

@MainActor
class SettingsViewModel: ObservableObject {
    @AppStorage("serverURL") var serverURL: String = ""
    @AppStorage("apiToken") var apiToken: String = ""
    @AppStorage("apiTokenHeader") var apiTokenHeader: String = "Authorization"
    @Published var isSaving = false
    @Published var saveMessage: String?
    @Published var isProcessing = false
    var modelContext: ModelContext?

    func saveConfiguration() async -> Bool {
        guard !serverURL.isEmpty, !apiToken.isEmpty else {
            saveMessage = "请填写完整信息"
            return false
        }
        isSaving = true
        saveMessage = nil
        APIClient.shared.configure(baseURL: serverURL, token: apiToken, tokenHeaderName: apiTokenHeader)
        do {
            _ = try await APIClient.shared.getVehicles()
            saveMessage = "✅ 连接成功"
            isSaving = false
            return true
        } catch {
            saveMessage = "❌ 连接失败: \(error.localizedDescription)"
            isSaving = false
            return false
        }
    }

    func batchUpdateCosts() async {
        guard let container = modelContext?.container else {
            saveMessage = "❌ 数据库未初始化"
            return
        }

        isProcessing = true
        saveMessage = nil

        Task(priority: .userInitiated) { [weak self, container] in
            guard let self = self else { return }

            let backgroundContext = ModelContext(container)

            do {
                let charges = try backgroundContext.fetch(FetchDescriptor<Charge>())
                let geofences = try backgroundContext.fetch(FetchDescriptor<Geofence>())
                let prices = try backgroundContext.fetch(FetchDescriptor<ElectricityPrice>())

                for (index, charge) in charges.enumerated() {
                    charge.cost = CostCalculator.calculateCost(charge: charge, geofences: geofences, prices: prices)
                    if index % 100 == 0 && index > 0 {
                        try backgroundContext.save()
                        backgroundContext.processPendingChanges()
                    }
                }
                try backgroundContext.save()

                let count = charges.count
                await MainActor.run {
                    self.isProcessing = false
                    self.saveMessage = "✅ 批量更新完成，共更新 \(count) 条记录"
                }
            } catch {
                await MainActor.run {
                    self.isProcessing = false
                    self.saveMessage = "❌ 批量更新失败: \(error.localizedDescription)"
                }
            }
        }
    }
}
