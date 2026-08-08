//
//  APIEndpoint.swift
//  TeslaMateApp
//

import Foundation

enum APIEndpoint {
    case vehicles
    case vehicle(carId: Int)
    case status(carId: Int)
    case drives(carId: Int, limit: Int, offset: Int)
    case drive(carId: Int, driveId: Int)
    case charges(carId: Int, limit: Int, offset: Int)
    case charge(carId: Int, chargeId: Int)
    case batteryHealth(carId: Int)

    var path: String {
        switch self {
        case .vehicles:
            return "/api/v1/cars"
        case .vehicle(let carId):
            return "/api/v1/cars/\(carId)"
        case .status(let carId):
            return "/api/v1/cars/\(carId)/status"
        case .drives(let carId, let limit, let offset):
            return "/api/v1/cars/\(carId)/drives"
        case .drive(let carId, let driveId):
            return "/api/v1/cars/\(carId)/drives/\(driveId)"
        case .charges(let carId, let limit, let offset):
            return "/api/v1/cars/\(carId)/charges"
        case .charge(let carId, let chargeId):
            return "/api/v1/cars/\(carId)/charges/\(chargeId)"
        case .batteryHealth(let carId):
            return "/api/v1/cars/\(carId)/battery-health"
        }
    }

    var queryItems: [URLQueryItem]? {
        switch self {
        case .drives(_, let limit, let offset):
            return [
                URLQueryItem(name: "limit", value: String(limit)),
                URLQueryItem(name: "offset", value: String(offset))
            ]
        case .charges(_, let limit, let offset):
            return [
                URLQueryItem(name: "limit", value: String(limit)),
                URLQueryItem(name: "offset", value: String(offset))
            ]
        default:
            return nil
        }
    }

    func buildURL(baseURL: String) -> URL? {
        guard var components = URLComponents(string: baseURL + path) else {
            return nil
        }
        if let queryItems = queryItems, !queryItems.isEmpty {
            components.queryItems = queryItems
        }
        return components.url
    }
}
