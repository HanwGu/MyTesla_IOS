//
//  VehicleInfoCard.swift
//  MyTesla
//

import SwiftUI

struct VehicleInfoCard: View {
    let vehicle: Vehicle

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: "car.fill")
                .font(.largeTitle)
                .foregroundColor(.blue)
                .frame(width: 48, height: 48)
                .background(Color.blue.opacity(0.15))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text(vehicle.name)
                    .font(.headline)
                    .fontWeight(.semibold)
                if let model = vehicle.model {
                    Text(model)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                if let vin = vehicle.vin {
                    Text("VIN: \(vin)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .monospaced()
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                if let version = vehicle.softwareVersion {
                    Label(version, systemImage: "gear")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                if let carType = vehicle.carType {
                    Text(carType)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}
