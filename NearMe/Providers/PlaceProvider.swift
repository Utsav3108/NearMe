import Foundation


protocol PlacesRepository: Sendable {
    func nearbyPlaces(
        around coordinate: PlaceCoordinate,
        category: PlaceCategory?,
        rankPreference: NearbyRankPreference
    ) async throws -> [PlaceSummary]

    func textSearch(
        query: String,
        around coordinate: PlaceCoordinate
    ) async throws -> [PlaceSummary]
    
    func getPlaceDetails(id: String) async throws -> PlaceDDetail
}

enum NearbyRankPreference: String, Encodable, Sendable {
    case popularity = "POPULARITY"
    case distance = "DISTANCE"
}

struct PlaceSearchResponse: Decodable {
    fileprivate let places: [GooglePlace]?
}

private struct GooglePlace: Decodable {
    let id: String
    let displayName: LocalizedText?
    let formattedAddress: String?
    let location: GoogleCoordinate?
    let primaryType: String?
    let types: [String]?
    let rating: Double?
    let userRatingCount: Int?
    let businessStatus: String?
    let currentOpeningHours: OpeningHours?
    let photos: [GooglePhoto]?

    func summary() -> PlaceSummary? {
        guard let displayName, let location else { return nil }

        return PlaceSummary(
            id: id,
            name: displayName.text,
            formattedAddress: formattedAddress,
            coordinate: PlaceCoordinate(latitude: location.latitude, longitude: location.longitude),
            category: PlaceCategory.from(types: types ?? [], primaryType: primaryType),
            rating: rating,
            reviewCount: userRatingCount,
            isOpenNow: currentOpeningHours?.openNow,
            businessStatus: businessStatus,
            primaryPhoto: photos?.first?.makePhoto(id: id)
        )
    }
}

private struct LocalizedText: Decodable {
    let text: String
}

private struct GoogleCoordinate: Decodable {
    let latitude: Double
    let longitude: Double
}

private struct OpeningHours: Decodable {
    let openNow: Bool?
}

struct GooglePhoto: Codable, Sendable, Identifiable {
    let name: String
    let widthPx: Int?
    let heightPx: Int?
    let authorAttributions: [GooglePhotoAttribution]?
    
    var id: String {
        name
    }

    func makePhoto(id: String) -> PlacePhoto {
        PlacePhoto(
            placeId: id,
            resourceName: name,
            width: widthPx,
            height: heightPx,
            attributions: (authorAttributions ?? []).map {
                PhotoAttribution(displayName: $0.displayName, uri: URL(string: $0.uri ?? ""))
            }
        )
    }
}

struct GooglePhotoAttribution: Codable {
    let displayName: String
    let uri: String?
}

//private extension PlacePhoto {
//    init(_ photo: GooglePhoto) {
//        self = photo.makePhoto()
//    }
//}

private struct NearbyRequest: Encodable {
    struct LocationRestriction: Encodable {
        struct Circle: Encodable {
            let center: PlaceCoordinate
            let radius: Double
        }

        let circle: Circle
    }

    let includedTypes: [String]?
    let maxResultCount: Int
    let locationRestriction: LocationRestriction
    let rankPreference: NearbyRankPreference
}

private struct TextSearchRequest: Encodable {
    struct LocationBias: Encodable {
        struct Circle: Encodable {
            let center: PlaceCoordinate
            let radius: Double
        }

        let circle: Circle
    }

    let textQuery: String
    let locationBias: LocationBias
    let maxResultCount: Int
}

final class PlaceProvider: PlacesRepository, Sendable {
    private let network: Network

    init(network: Network = Network()) {
        self.network = network
    }
    
    func getPlaceDetails(id: String) async throws -> PlaceDDetail {
        
        
        let details = try await performFetch(endpoint: "https://places.googleapis.com/v1/places/\(id)")
        
        
        return details
    }

    func nearbyPlaces(
        around coordinate: PlaceCoordinate,
        category: PlaceCategory?,
        rankPreference: NearbyRankPreference
    ) async throws -> [PlaceSummary] {
        let requestBody = NearbyRequest(
            includedTypes: category?.nearbySearchTypes.isEmpty == false ? category?.nearbySearchTypes : nil,
            maxResultCount: 20,
            locationRestriction: .init(circle: .init(center: coordinate, radius: 8_000)),
            rankPreference: rankPreference
        )

        return try await performSearch(
            endpoint: "https://places.googleapis.com/v1/places:searchNearby",
            body: requestBody
        )
    }

    func textSearch(query: String, around coordinate: PlaceCoordinate) async throws -> [PlaceSummary] {
        let requestBody = TextSearchRequest(
            textQuery: query,
            locationBias: .init(circle: .init(center: coordinate, radius: 20_000)),
            maxResultCount: 20
        )

        return try await performSearch(
            endpoint: "https://places.googleapis.com/v1/places:searchText",
            body: requestBody
        )
    }

    private func performSearch<Request: Encodable>(
        endpoint: String,
        body: Request?
    ) async throws -> [PlaceSummary] {
        guard let url = URL(string: endpoint) else {
            throw URLError(.badURL)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(Secrets.googleMapsAPIKey, forHTTPHeaderField: "X-Goog-Api-Key")
        request.setValue(
            "places.id,places.displayName,places.formattedAddress,places.location,places.primaryType,places.types,places.rating,places.userRatingCount,places.businessStatus,places.currentOpeningHours.openNow,places.photos",
            forHTTPHeaderField: "X-Goog-FieldMask"
        )
        request.httpBody = try JSONEncoder().encode(body)

        let response: PlaceSearchResponse = try await network.perform(request: request)
        return (response.places ?? []).compactMap { $0.summary() }
    }
    
    private func performFetch(
        endpoint: String
    ) async throws -> PlaceDDetail {
        guard let url = URL(string: endpoint) else {
            throw URLError(.badURL)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(Secrets.googleMapsAPIKey, forHTTPHeaderField: "X-Goog-Api-Key")
        request.setValue(
            "id,displayName,formattedAddress,location,types,primaryTypeDisplayName,googleMapsUri,internationalPhoneNumber,websiteUri,regularOpeningHours,rating,userRatingCount,priceLevel,reviews,photos",
            forHTTPHeaderField: "X-Goog-FieldMask"
        )
        

        let response: PlaceDDetail = try await network.perform(request: request)
        return response
    }
    
    
    
    
}
