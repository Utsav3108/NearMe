import Foundation

struct PlaceCoordinate: Codable, Hashable, Sendable {
    let latitude: Double
    let longitude: Double
}

enum PlaceCategory: String, CaseIterable, Codable, Hashable, Sendable {
    case all
    case food
    case cafes
    case parks
    case attractions

    var title: String {
        switch self {
        case .all: "All"
        case .food: "Food"
        case .cafes: "Cafes"
        case .parks: "Parks"
        case .attractions: "Attractions"
        }
    }

    var nearbySearchTypes: [String] {
        switch self {
        case .all: []
        case .food: ["restaurant", "meal_takeaway", "bakery"]
        case .cafes: ["cafe", "coffee_shop"]
        case .parks: ["park"]
        case .attractions: ["tourist_attraction", "museum", "amusement_park"]
        }
    }

    static func from(types: [String], primaryType: String?) -> PlaceCategory {
        let allTypes = Set(types + (primaryType.map { [$0] } ?? []))

        if !allTypes.isDisjoint(with: ["cafe", "coffee_shop"]) {
            return .cafes
        }
        if allTypes.contains("park") {
            return .parks
        }
        if !allTypes.isDisjoint(with: ["tourist_attraction", "museum", "amusement_park", "art_gallery", "zoo"]) {
            return .attractions
        }
        return .food
    }
}

struct PhotoAttribution: Hashable, Sendable {
    let displayName: String
    let uri: URL?
}

struct PlacePhoto: Hashable, Sendable {
    let placeId : String
    /// Short-lived Google photo resource. Keep this in memory only.
    let resourceName: String
    let width: Int?
    let height: Int?
    let attributions: [PhotoAttribution]
}

struct PlaceSummary: Identifiable, Hashable, Sendable {
    let id: String
    let name: String
    let formattedAddress: String?
    let coordinate: PlaceCoordinate
    let category: PlaceCategory
    let rating: Double?
    let reviewCount: Int?
    let isOpenNow: Bool?
    let businessStatus: String?
    let primaryPhoto: PlacePhoto?

    var isOperational: Bool {
        businessStatus == nil || businessStatus == "OPERATIONAL"
    }
}

struct RankedPlace: Identifiable, Hashable, Sendable {
    let place: PlaceSummary
    let score: Double
    let reasons: [RecommendationReason]

    var id: String { place.id }
}

enum RecommendationReason: String, Hashable, Sendable {
    case openNow
    case matchesYourInterests
    case nearby
    case popularNearby
    case greatRating

    var displayText: String {
        switch self {
        case .openNow: "Open now"
        case .matchesYourInterests: "Matches your interests"
        case .nearby: "Nearby"
        case .popularNearby: "Popular nearby"
        case .greatRating: "Great rating"
        }
    }
}

enum TimeOfDayBucket: Sendable {
    case morning
    case afternoon
    case evening
    case night

    init(date: Date = .now, calendar: Calendar = .current) {
        switch calendar.component(.hour, from: date) {
        case 5..<12: self = .morning
        case 12..<17: self = .afternoon
        case 17..<22: self = .evening
        default: self = .night
        }
    }

    var preferredCategories: Set<PlaceCategory> {
        switch self {
        case .morning: [.food, .cafes, .parks, .attractions]
        case .afternoon: [.food, .attractions]
        case .evening: [.cafes, .food, .parks, .attractions]
        case .night: [.food, .cafes]
        }
    }
}

enum WeatherCondition: Sendable {
    case unknown
}

protocol WeatherProviding: Sendable {
    func currentWeather(at coordinate: PlaceCoordinate) async -> WeatherCondition
}

struct UnavailableWeatherProvider: WeatherProviding {
    func currentWeather(at coordinate: PlaceCoordinate) async -> WeatherCondition {
        .unknown
    }
}

struct UserPreferenceProfile: Sendable {
    var categoryAffinity: [PlaceCategory: Double] = [:]

    static let empty = UserPreferenceProfile()
}

struct RecommendationContext: Sendable {
    let coordinate: PlaceCoordinate
    let selectedCategory: PlaceCategory
    let timeOfDay: TimeOfDayBucket
    let weather: WeatherCondition
    let preferences: UserPreferenceProfile
}
