import CoreLocation
import Foundation
import Observation
import SwiftData

enum HomeLoadState: Equatable {
    case idle
    case loading
    case loaded
    case locationRequired
    case failed(String)
}

@Observable
@MainActor
final class HomeVM {
    private let placeProvider: any PlacesRepository
    private let recommendationEngine: RecommendationEngine
    private let weatherProvider: any WeatherProviding
    private let locationService = CurrentLocationService()

    private var recorder: InteractionRecorder?
    private var currentCoordinate: PlaceCoordinate?
    private var selectedCategory: PlaceCategory = .all

    var trendingPlaces: [PlaceSummary] = []
    var recommendedPlaces: [RankedPlace] = []
    var searchResults: [PlaceSummary] = []
    var state: HomeLoadState = .idle

    
    init(
        placeProvider: any PlacesRepository,
        recommendationEngine: RecommendationEngine ,
        weatherProvider: any WeatherProviding
    ) {
        self.placeProvider = placeProvider
        self.recommendationEngine = recommendationEngine
        self.weatherProvider = weatherProvider

        locationService.onLocation = { [weak self] coordinate in
            self?.currentCoordinate = coordinate
            Task { await self?.reloadHome() }
        }
        locationService.onFailure = { [weak self] in
            self?.state = .locationRequired
        }
    }

    func configure(modelContext: ModelContext) {
        guard recorder == nil else { return }
        recorder = InteractionRecorder(modelContext: modelContext)
    }

    func start() {
        locationService.requestCurrentLocation()
    }

    func select(category: PlaceCategory) {
        guard selectedCategory != category else { return }
        selectedCategory = category
        Task { await reloadHome() }
    }

    func search(query: String) async {
        guard let currentCoordinate else {
            state = .locationRequired
            return
        }

        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedQuery.isEmpty else {
            searchResults = []
            return
        }

        state = .loading
        do {
            searchResults = try await placeProvider.textSearch(query: trimmedQuery, around: currentCoordinate)
            state = .loaded
        } catch {
            state = .failed("Unable to search places right now.")
        }
    }

    func reloadHome() async {
        guard let currentCoordinate else {
            state = .locationRequired
            return
        }

        state = .loading
        searchResults = []

        do {
            async let trendingRequest = placeProvider.nearbyPlaces(
                around: currentCoordinate,
                category: selectedCategory == .all ? nil : selectedCategory,
                rankPreference: .popularity
            )
            async let foodRequest = placeProvider.nearbyPlaces(
                around: currentCoordinate,
                category: .food,
                rankPreference: .popularity
            )
            async let cafesRequest = placeProvider.nearbyPlaces(
                around: currentCoordinate,
                category: .cafes,
                rankPreference: .popularity
            )
            async let parksRequest = placeProvider.nearbyPlaces(
                around: currentCoordinate,
                category: .parks,
                rankPreference: .popularity
            )
            async let attractionsRequest = placeProvider.nearbyPlaces(
                around: currentCoordinate,
                category: .attractions,
                rankPreference: .popularity
            )

            let (trending, food, cafes, parks, attractions) = try await (
                trendingRequest,
                foodRequest,
                cafesRequest,
                parksRequest,
                attractionsRequest
            )

            let candidates = deduplicate(food + cafes + parks + attractions)
            let weather = await weatherProvider.currentWeather(at: currentCoordinate)
            let context = await RecommendationContext(
                coordinate: currentCoordinate,
                selectedCategory: selectedCategory,
                timeOfDay: TimeOfDayBucket(),
                weather: weather,
                preferences: recorder?.preferenceProfile() ?? .empty
            )

            trendingPlaces = trending.filter { selectedCategory == .all || $0.category == selectedCategory }
            recommendedPlaces = recommendationEngine.rank(
                candidates: selectedCategory == .all
                    ? candidates
                    : candidates.filter { $0.category == selectedCategory },
                context: context,
                popularPlaceIDs: Set(trending.map { $0.id })
            )
            state = .loaded
        } catch {
            state = .failed("Unable to load places right now.")
        }
    }

    func recordImpression(place: PlaceSummary, section: HomeSection, position: Int) async {
        await recorder?.record(.impression, place: place, section: section, position: position)
    }

    func recordOpen(place: PlaceSummary, section: HomeSection, position: Int) async {
        await recorder?.record(.opened, place: place, section: section, position: position)
    }

    func distanceText(for place: PlaceSummary) -> String {
        guard let currentCoordinate else { return "Nearby" }

        let origin = CLLocation(latitude: currentCoordinate.latitude, longitude: currentCoordinate.longitude)
        let destination = CLLocation(latitude: place.coordinate.latitude, longitude: place.coordinate.longitude)
        let meters = origin.distance(from: destination)

        if meters < 1_000 {
            return "\(Int(meters.rounded())) m"
        }
        return String(format: "%.1f km", meters / 1_000)
    }

    private func deduplicate(_ places: [PlaceSummary]) -> [PlaceSummary] {
        var seen = Set<String>()
        return places.filter { seen.insert($0.id).inserted }
    }
}

@MainActor
private final class CurrentLocationService: NSObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()

    var onLocation: ((PlaceCoordinate) -> Void)?
    var onFailure: (() -> Void)?

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyKilometer
    }

    func requestCurrentLocation() {
        switch manager.authorizationStatus {
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        case .authorizedAlways, .authorizedWhenInUse:
            manager.requestLocation()
        default:
            onFailure?()
        }
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        guard manager.authorizationStatus == .authorizedAlways
                || manager.authorizationStatus == .authorizedWhenInUse else {
            if manager.authorizationStatus != .notDetermined {
                onFailure?()
            }
            return
        }
        manager.requestLocation()
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else {
            onFailure?()
            return
        }

        onLocation?(PlaceCoordinate(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude))
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        onFailure?()
    }
}
