//
//  TripDetailViewModel.swift
//  TeslaMateApp
//

import SwiftUI

@MainActor
class TripDetailViewModel: ObservableObject {
    @Published var detail: TripDetail?
    @Published var isLoading = false
    @Published var errorMessage: String?

    private var vehicleId: Int?
    private var driveId: Int?

    func configure(vehicleId: Int, driveId: Int) {
        self.vehicleId = vehicleId
        self.driveId = driveId
    }

    func loadDetail() async {
        guard let vehicleId = vehicleId, let driveId = driveId else {
            errorMessage = "缺少行程信息"
            return
        }
        isLoading = true
        errorMessage = nil

        do {
            try Task.checkCancellation()
            let detail = try await APIClient.shared.getDrive(carId: vehicleId, driveId: driveId)
            self.detail = detail
        } catch is CancellationError {
        } catch {
            errorMessage = "加载行程详情失败: \(error.localizedDescription)"
        }
        isLoading = false
    }
}
