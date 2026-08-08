//
//  SettingsView.swift
//  MyTesla
//

import SwiftUI
import SwiftData

struct SettingsView: View {
    @StateObject private var viewModel = SettingsViewModel()
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        NavigationStack {
            Form {
                Section("API 配置") {
                    TextField("服务器地址", text: $viewModel.serverURL)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                        .keyboardType(.URL)
                    SecureField("API Token", text: $viewModel.apiToken)
                    Button("保存配置") {
                        Task { _ = await viewModel.saveConfiguration() }
                    }
                    .disabled(viewModel.isSaving)
                    if let message = viewModel.saveMessage {
                        Text(message)
                            .font(.caption)
                            .foregroundColor(message.hasPrefix("✅") ? .green : .red)
                    }
                }

                Section("数据源") {
                    HStack {
                        Text("当前")
                        Spacer()
                        Text("HTTP (TeslaMateApi)")
                            .foregroundColor(.secondary)
                    }
                }

                Section("费用管理") {
                    Button("批量更新充电成本") {
                        Task {
                            await viewModel.batchUpdateCosts()
                        }
                    }
                    .disabled(viewModel.isProcessing)
                    if viewModel.isProcessing {
                        HStack {
                            ProgressView()
                                .progressViewStyle(.circular)
                            Text("更新中...")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    if let message = viewModel.saveMessage,
                       message.hasPrefix("✅") || message.hasPrefix("❌") {
                        Text(message)
                            .font(.caption)
                            .foregroundColor(message.hasPrefix("✅") ? .green : .red)
                    }
                }

                Section("地理围栏") {
                    NavigationLink("管理围栏") {
                        GeofenceSettingsView(settingsViewModel: viewModel)
                    }
                }

                Section("分时电价") {
                    NavigationLink("电价设置") {
                        ElectricityPriceSettingsView(settingsViewModel: viewModel)
                    }
                }

                Section("停车费用") {
                    NavigationLink("停车记录") {
                        ParkingCostView()
                    }
                }

                Section("关于") {
                    HStack {
                        Text("版本")
                        Spacer()
                        Text("1.0")
                            .foregroundColor(.secondary)
                    }
                    HStack {
                        Text("数据来源")
                        Spacer()
                        Text("TeslaMate")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("设置")
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                viewModel.modelContext = modelContext
            }
        }
    }
}
