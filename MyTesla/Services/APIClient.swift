//
//  APIClient.swift
//  TeslaMateApp
//

import Foundation

// MARK: - Cache Actor
actor CacheManager {
    private struct CacheEntry {
        let data: Data
        let timestamp: Date
        let cost: Int
    }

    private var storage: [String: CacheEntry] = [:]
    private var keyOrder: [String] = []
    private var inFlightTasks: [String: Task<Data?, Never>] = [:]
    private var retryCount: [String: Int] = [:]
    private let cacheDuration: TimeInterval = 300
    private let maxEntryCount = 50
    private let maxTotalCost = 5 * 1024 * 1024
    private var currentTotalCost = 0

    func fetch(key: String, httpRequest: @escaping () async throws -> Data) async throws -> Data {
        if let entry = storage[key],
           Date().timeIntervalSince(entry.timestamp) < cacheDuration {
            return entry.data
        }

        if let task = inFlightTasks[key] {
            if let data = await task.value {
                return data
            } else {
                let currentRetry = retryCount[key, default: 0] + 1
                retryCount[key] = currentRetry
                if currentRetry > 2 {
                    inFlightTasks[key] = nil
                    retryCount[key] = nil
                    throw APIError.requestFailed
                }
                inFlightTasks[key] = nil
            }
        }

        let task = Task<Data?, Never> { () -> Data? in
            do {
                return try await httpRequest()
            } catch {
                return nil
            }
        }

        inFlightTasks[key] = task
        guard let data = await task.value else {
            inFlightTasks[key] = nil
            let currentRetry = retryCount[key, default: 0] + 1
            retryCount[key] = currentRetry
            if currentRetry > 2 {
                retryCount[key] = nil
            }
            throw APIError.requestFailed
        }

        retryCount[key] = nil
        set(key, data: data)
        inFlightTasks[key] = nil
        return data
    }

    private func set(_ key: String, data: Data) {
        let cost = data.count
        if let oldEntry = storage.removeValue(forKey: key) {
            currentTotalCost -= oldEntry.cost
            keyOrder.removeAll { $0 == key }
        }
        storage[key] = CacheEntry(data: data, timestamp: Date(), cost: cost)
        currentTotalCost += cost
        keyOrder.append(key)

        while storage.count > maxEntryCount || currentTotalCost > maxTotalCost {
            guard let oldestKey = keyOrder.first,
                  let entry = storage.removeValue(forKey: oldestKey) else { break }
            currentTotalCost -= entry.cost
            keyOrder.removeFirst()
        }
    }

    func remove(_ key: String) {
        if let entry = storage.removeValue(forKey: key) {
            currentTotalCost -= entry.cost
            keyOrder.removeAll { $0 == key }
        }
        inFlightTasks[key] = nil
        retryCount[key] = nil
    }

    func clear() {
        storage.removeAll()
        keyOrder.removeAll()
        inFlightTasks.removeAll()
        retryCount.removeAll()
        currentTotalCost = 0
    }
}

// MARK: - Intermediate Decodable Types
private struct APIVehicle: Decodable {
    let carId: Int
    let carName: String
    let model: String?

    enum CodingKeys: String, CodingKey {
        case carId = "car_id"
        case carName = "car_name"
        case model
    }
}

private struct APIVehicleDetail: Decodable {
    let carId: Int
    let carName: String
    let model: String?
    let softwareVersion: String?
    let vin: String?
    let carType: String?

    enum CodingKeys: String, CodingKey {
        case carId = "car_id"
        case carName = "car_name"
        case model
        case softwareVersion = "software_version"
        case vin
        case carType = "car_type"
    }
}

private struct APITrip: Decodable {
    let id: Int
    let startTime: Date
    let endTime: Date
    let startAddress: String?
    let endAddress: String?
    let startLat: Double?
    let startLon: Double?
    let endLat: Double?
    let endLon: Double?
    let distance: Double
    let avgEnergy: Double
    let duration: Int
    let maxSpeed: Double?
    let avgSpeed: Double?
    let elevationGain: Double?
    let regenEnergy: Double?

    enum CodingKeys: String, CodingKey {
        case id
        case startTime = "start_time"
        case endTime = "end_time"
        case startAddress = "start_address"
        case endAddress = "end_address"
        case startLat = "start_lat"
        case startLon = "start_lon"
        case endLat = "end_lat"
        case endLon = "end_lon"
        case distance
        case avgEnergy = "avg_energy"
        case duration
        case maxSpeed = "max_speed"
        case avgSpeed = "avg_speed"
        case elevationGain = "elevation_gain"
        case regenEnergy = "regen_energy"
    }
}

private struct APICharge: Decodable {
    let id: Int
    let startTime: Date
    let endTime: Date
    let energyAdded: Double
    let positionLat: Double
    let positionLon: Double
    let address: String?
    let maxPower: Double?
    let avgPower: Double?
    let socStart: Int
    let socEnd: Int

    enum CodingKeys: String, CodingKey {
        case id
        case startTime = "start_time"
        case endTime = "end_time"
        case energyAdded = "energy_added"
        case positionLat = "position_lat"
        case positionLon = "position_lon"
        case address
        case maxPower = "max_power"
        case avgPower = "avg_power"
        case socStart = "soc_start"
        case socEnd = "soc_end"
    }
}

private struct VehiclesResponse: Decodable {
    let data: [APIVehicle]
}

private struct VehicleDetailResponse: Decodable {
    let data: APIVehicleDetail
}

// MARK: - APIClient
// 线程安全说明：仅 baseURL 和 token 的读写受 NSLock 保护，其他属性为不可变或线程安全类型
class APIClient: DataSource {
    static let shared = APIClient()
    private var baseURL: String = ""
    private var token: String = ""
    private let lock = NSLock()

    private static let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()

    private let cache = CacheManager()

    func configure(baseURL: String, token: String) {
        lock.lock()
        defer { lock.unlock() }
        self.baseURL = baseURL
        self.token = token
    }

    private func request<T: Decodable>(_ endpoint: APIEndpoint, method: String = "GET", forceRefresh: Bool = false) async throws -> T {
        let currentBaseURL: String
        let currentToken: String
        lock.lock()
        currentBaseURL = self.baseURL
        currentToken = self.token
        lock.unlock()

        guard let url = endpoint.buildURL(baseURL: currentBaseURL) else {
            throw APIError.invalidURL
        }
        let urlString = url.absoluteString

        let shouldCache: Bool
        if case .status = endpoint {
            shouldCache = false
        } else {
            shouldCache = !forceRefresh
        }

        if shouldCache {
            let data = try await cache.fetch(key: urlString) {
                let (data, _) = try await self.performRequest(url: url, method: method, token: currentToken)
                return data
            }
            do {
                return try Self.decoder.decode(T.self, from: data)
            } catch {
                await cache.remove(urlString)
                throw APIError.decodingFailed
            }
        } else {
            let (data, _) = try await performRequest(url: url, method: method, token: currentToken)
            return try Self.decoder.decode(T.self, from: data)
        }
    }

    private func performRequest(url: URL, method: String, token: String) async throws -> (Data, URLResponse) {
        var request = URLRequest(url: url)
        request.httpMethod = method

        if !token.isEmpty {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw APIError.requestFailed
        }
        return (data, response)
    }

    // MARK: - Vehicle List
    func getVehicles() async throws -> [Vehicle] {
        let response: VehiclesResponse = try await request(.vehicles)
        return response.data.map {
            Vehicle(id: $0.carId, name: $0.carName, model: $0.model)
        }
    }

    // MARK: - Vehicle Detail
    func getVehicle(carId: Int) async throws -> Vehicle {
        let response: VehicleDetailResponse = try await request(.vehicle(carId: carId))
        let detail = response.data
        return Vehicle(
            id: detail.carId,
            name: detail.carName,
            model: detail.model,
            softwareVersion: detail.softwareVersion,
            vin: detail.vin,
            carType: detail.carType,
            lastUpdated: Date()
        )
    }

    // MARK: - Vehicle Status
    func getVehicleStatus(carId: Int) async throws -> VehicleStatus {
        let status: VehicleStatus = try await request(.status(carId: carId), forceRefresh: true)
        return status
    }

    // MARK: - Drives List
    func getDrives(carId: Int, limit: Int = 100, offset: Int = 0) async throws -> [Trip] {
        let apiTrips: [APITrip] = try await request(.drives(carId: carId, limit: limit, offset: offset))
        return apiTrips.map { apiTrip in
            Trip(
                id: apiTrip.id,
                startTime: apiTrip.startTime,
                endTime: apiTrip.endTime,
                startAddress: apiTrip.startAddress,
                endAddress: apiTrip.endAddress,
                startLat: apiTrip.startLat,
                startLon: apiTrip.startLon,
                endLat: apiTrip.endLat,
                endLon: apiTrip.endLon,
                distance: apiTrip.distance,
                avgEnergy: apiTrip.avgEnergy,
                duration: apiTrip.duration,
                maxSpeed: apiTrip.maxSpeed,
                avgSpeed: apiTrip.avgSpeed,
                elevationGain: apiTrip.elevationGain,
                regenEnergy: apiTrip.regenEnergy,
                outsideTemp: nil
            )
        }
    }

    // MARK: - Drive Detail
    func getDrive(carId: Int, driveId: Int) async throws -> TripDetail {
        let detail: TripDetail = try await request(.drive(carId: carId, driveId: driveId))
        return detail
    }

    // MARK: - Charges List
    func getCharges(carId: Int, limit: Int = 100, offset: Int = 0) async throws -> [Charge] {
        let apiCharges: [APICharge] = try await request(.charges(carId: carId, limit: limit, offset: offset))
        return apiCharges.map { apiCharge in
            Charge(
                id: apiCharge.id,
                startTime: apiCharge.startTime,
                endTime: apiCharge.endTime,
                energyAdded: apiCharge.energyAdded,
                cost: nil,
                parkingCost: nil,
                positionLat: apiCharge.positionLat,
                positionLon: apiCharge.positionLon,
                address: apiCharge.address,
                maxPower: apiCharge.maxPower,
                avgPower: apiCharge.avgPower,
                socStart: apiCharge.socStart,
                socEnd: apiCharge.socEnd
            )
        }
    }

    // MARK: - Charge Detail
    func getCharge(carId: Int, chargeId: Int) async throws -> ChargeDetail {
        let detail: ChargeDetail = try await request(.charge(carId: carId, chargeId: chargeId))
        return detail
    }

    // MARK: - Battery Health
    func getBatteryHealth(carId: Int) async throws -> BatteryHealth {
        let health: BatteryHealth = try await request(.batteryHealth(carId: carId))
        return health
    }
}

enum APIError: Error {
    case invalidURL
    case requestFailed
    case decodingFailed
}
