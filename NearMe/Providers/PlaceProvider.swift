import Foundation


/// A thread-safe repository protocol defining operations for retrieving places from the Google Places API.
///
/// **Concurrency & Discipline:**
/// Conforms to `Sendable` so that repository references can be safely shared across tasks and injected
/// into `@MainActor` ViewModels without actor hopping or data race hazards.
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

    /// Retrieves a diverse mix of visual place items (cafes, mountains, parks, attractions both near and far).
    func explorePlaces(
        around coordinate: PlaceCoordinate
    ) async throws -> [ExploreItem]

    /// Searches for places matching a query and returns visual items for the Explore tab grid.
    func searchExplorePlaces(
        query: String,
        around coordinate: PlaceCoordinate
    ) async throws -> [ExploreItem]
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

    func exploreItems() -> [ExploreItem] {
        guard let displayName = displayName?.text,
              let photos, !photos.isEmpty else { return [] }

        return photos.prefix(2).enumerated().map { index, photo in
            let placePhoto = photo.makePhoto(id: id)
            let attribution = placePhoto.attributions.first ?? PhotoAttribution(displayName: displayName, uri: nil)
            return ExploreItem(
                id: "\(id)_\(index)_\(photo.name)",
                placeId: id,
                placeName: displayName,
                photo: placePhoto,
                attribution: attribution
            )
        }
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

/// Concrete implementation of `PlacesRepository` that interfaces with the Google Places API (New).
///
/// **Concurrency & Discipline:**
/// Designed as a `final class: Sendable` because all its state is immutable (`let network: Network`).
/// By avoiding mutable state, multiple callers can invoke its async methods concurrently across
/// different tasks and actors without contention or serialization overhead.
final class PlaceProvider: PlacesRepository, Sendable {
    private let network: Network

    nonisolated init(network: Network = Network()) {
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

        let response: PlaceSearchResponse = try await performSearch(
            endpoint: "https://places.googleapis.com/v1/places:searchNearby",
            body: requestBody
        )
        return (response.places ?? []).compactMap { $0.summary() }
    }

    func textSearch(query: String, around coordinate: PlaceCoordinate) async throws -> [PlaceSummary] {
        let requestBody = TextSearchRequest(
            textQuery: query,
            locationBias: .init(circle: .init(center: coordinate, radius: 20_000)),
            maxResultCount: 20
        )

        let response: PlaceSearchResponse = try await performSearch(
            endpoint: "https://places.googleapis.com/v1/places:searchText",
            body: requestBody
        )
        return (response.places ?? []).compactMap { $0.summary() }
    }

    func explorePlaces(
        around coordinate: PlaceCoordinate
    ) async throws -> [ExploreItem] {
        // Concurrently fetch diverse place buckets to guarantee a rich mix of:
        // 1. Nearby Cafes & Bakeries (0-8 km)
        // 2. Local Parks & Outdoor recreation (0-15 km)
        // 3. Mountains, Viewpoints & Hiking (far & near: 0-45 km)
        // 4. Regional Attractions & Cultural Landmarks (far & near: 0-50 km)
        async let cafesTask = fetchNearbyExploreItems(
            types: ["cafe", "coffee_shop", "bakery"],
            around: coordinate,
            radius: 8_000
        )
        async let parksTask = fetchNearbyExploreItems(
            types: ["park", "national_park", "campground"],
            around: coordinate,
            radius: 18_000
        )
        async let mountainsTask = fetchTextExploreItems(
            query: "mountains and scenic viewpoints",
            around: coordinate,
            radius: 45_000
        )
        async let attractionsTask = fetchTextExploreItems(
            query: "popular attractions and landmarks",
            around: coordinate,
            radius: 50_000
        )

        let (cafes, parks, mountains, attractions) = await (
            (try? cafesTask) ?? [],
            (try? parksTask) ?? [],
            (try? mountainsTask) ?? [],
            (try? attractionsTask) ?? []
        )

        return interleaveExploreItems(buckets: [mountains, cafes, parks, attractions])
    }

    func searchExplorePlaces(
        query: String,
        around coordinate: PlaceCoordinate
    ) async throws -> [ExploreItem] {
        return try await fetchTextExploreItems(
            query: query,
            around: coordinate,
            radius: 40_000
        )
    }

    private func fetchNearbyExploreItems(
        types: [String],
        around coordinate: PlaceCoordinate,
        radius: Double
    ) async throws -> [ExploreItem] {
        let requestBody = NearbyRequest(
            includedTypes: types,
            maxResultCount: 20,
            locationRestriction: .init(circle: .init(center: coordinate, radius: radius)),
            rankPreference: .popularity
        )
        let response: PlaceSearchResponse = try await performSearch(
            endpoint: "https://places.googleapis.com/v1/places:searchNearby",
            body: requestBody
        )
        return (response.places ?? []).flatMap { $0.exploreItems() }
    }

    private func fetchTextExploreItems(
        query: String,
        around coordinate: PlaceCoordinate,
        radius: Double
    ) async throws -> [ExploreItem] {
        let requestBody = TextSearchRequest(
            textQuery: query,
            locationBias: .init(circle: .init(center: coordinate, radius: radius)),
            maxResultCount: 20
        )
        let response: PlaceSearchResponse = try await performSearch(
            endpoint: "https://places.googleapis.com/v1/places:searchText",
            body: requestBody
        )
        return (response.places ?? []).flatMap { $0.exploreItems() }
    }

    private func interleaveExploreItems(buckets: [[ExploreItem]]) -> [ExploreItem] {
        var seenKeys = Set<String>()
        var queues = buckets
        var result: [ExploreItem] = []

        var hasMore = true
        while hasMore {
            hasMore = false
            for index in queues.indices {
                if !queues[index].isEmpty {
                    let item = queues[index].removeFirst()
                    let key = item.placeId + "_" + item.photo.resourceName
                    if seenKeys.insert(key).inserted {
                        result.append(item)
                    }
                    if !queues[index].isEmpty {
                        hasMore = true
                    }
                }
            }
        }

        return result
    }

    private func performSearch<Request: Encodable>(
        endpoint: String,
        body: Request?
    ) async throws -> PlaceSearchResponse {
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

        return try await network.perform(request: request)
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

        return try await network.perform(request: request)
    }
}
