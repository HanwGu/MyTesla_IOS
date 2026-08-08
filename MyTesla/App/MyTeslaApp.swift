//
//  MyTeslaApp.swift
//  MyTesla
//  iOS 17.0+
//

import SwiftUI
import SwiftData

@main
struct MyTeslaApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(for: [
                    Vehicle.self,
                    Drive.self,
                    Charge.self,
                    Geofence.self,
                    ElectricityPrice.self
                ])
        }
    }
}

struct ContentView: View {
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            DashboardView()
                .tabItem { Label("仪表盘", systemImage: "gauge.medium") }
                .tag(0)
            TripsView()
                .tabItem { Label("行程", systemImage: "list.bullet") }
                .tag(1)
            MapView()
                .tabItem { Label("地图", systemImage: "map") }
                .tag(2)
            StatisticsView()
                .tabItem { Label("统计", systemImage: "chart.bar") }
                .tag(3)
            SettingsView()
                .tabItem { Label("设置", systemImage: "gear") }
                .tag(4)
        }
    }
}
