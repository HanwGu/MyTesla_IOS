//
//  ChargeDetailViewModel.swift
//  TeslaMateApp
//

import SwiftUI

@MainActor
class ChargeDetailViewModel: ObservableObject {
    @Published var detail: ChargeDetail?
    @Published var isLoading = false
    @Published var errorMessage: String?

    private var vehicleId: Int?
    private var chargeId: Int?

    func configure(vehicleId: Int, chargeId: Int) {
        self.vehicleId = vehicleId
        self.chargeId = chargeId
    }

    func loadDetail() async {
        guard let vehicleId = vehicleId, let chargeId = chargeId else {
            errorMessage = "缺少充电记录信息"
            return
        }
        isLoading = true
        errorMessage = nil

        do {
            try Task.checkCancellation()
            let detail = try await APIClient.shared.getCharge(carId: vehicleId, chargeId: chargeId)
            self.detail = detail
        } catch is CancellationError {
        } catch {
            errorMessage = "加载充电详情失败: \(error.localizedDescription)"
        }
        isLoading = false
    }
}
