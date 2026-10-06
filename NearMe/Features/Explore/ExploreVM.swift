//
//  ExploreVM.swift
//  NearMe
//
//  Created by Utsav Hitendrabhai Pandya on 06/10/26.
//

import CoreLocation
import Foundation
import Observation

/// The presentation logic and state coordinator for the Explore feature.
///
/// **Why a `class`?**
/// SwiftUI's `@Observable` macro requires reference semantics (`class`) so that views can observe
/// identity-stable state across re-renders and view hierarchy invalidations.
///
/// **Why `@MainActor`?**
/// All published properties (`items`, `state`, `selectedPlaceDetail`, etc.) directly drive the SwiftUI
/// rendering tree. Isolating this class to `@MainActor` guarantees that state mutations occur exclusively
/// on the main actor / UI thread, strictly preventing Swift concurrency data races.
///
/// **Separation of Concerns:**
/// The ViewModel contains zero UI rendering code and zero networking serialization logic.
/// It delegates device location to `CurrentLocationService`, data fetching to `any PlacesRepository`,
/// and exposes pure state models to the SwiftUI View layer.
@Observable
@MainActor
final class ExploreVM {

    // MARK: - Dependencies

    private let placeProvider: any PlacesRepository
    private let locationService = CurrentLocationService()

    // MARK: - Private State

    private var currentCoordinate: PlaceCoordinate?

    // MARK: - Observable State

    /// The visual photo items displayed in the explore grid.
    var items: [ExploreItem] = []

    /// Current lifecycle and loading status of the grid feed.
    var state: ExploreLoadState = .idle

    /// Current text query entered into the search field.
    var searchText: String = ""

    /// Populated with a full `PlaceDDetail` when a user taps an item, triggering presentation mode.
    var selectedPlaceDetail: PlaceDDetail?

    /// The ID of the `ExploreItem` currently fetching details, providing immediate tactile loading feedback.
    var loadingItemId: String?

    /// An optional error message to present if detail fetching fails.
    var detailLoadError: String?

    // MARK: - Initialization

    /// Creates an instance of `ExploreVM` with default repository dependencies.
    convenience init() {
        self.init(placeProvider: PlaceProvider())
    }

    /// Creates an instance of `ExploreVM` with an injected repository.
    /// - Parameter placeProvider: The repository conforming to `PlacesRepository`.
    init(placeProvider: any PlacesRepository) {
        self.placeProvider = placeProvider

        locationService.onLocation = { [weak self] coordinate in
            guard let self else { return }
            self.currentCoordinate = coordinate
            Task {
                await self.loadExplorePlaces()
            }
        }

        locationService.onFailure = { [weak self] in
            guard let self else { return }
            self.state = .locationRequired
        }
    }

    // MARK: - Intent Methods

    /// Starts location acquisition and initiates the explore data feed.
    func start() {
        if currentCoordinate != nil {
            Task {
                await self.loadExplorePlaces()
            }
        } else {
            locationService.requestCurrentLocation()
        }
    }

    /// Searches for places matching the query string.
    /// - Parameter query: The search text query.
    func search(query: String) async {
        guard let currentCoordinate else {
            state = .locationRequired
            return
        }

        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            await loadExplorePlaces()
            return
        }

        state = .loading
        do {
            let fetched = try await placeProvider.searchExplorePlaces(query: trimmed, around: currentCoordinate)
            items = fetched
            state = fetched.isEmpty ? .empty : .loaded
        } catch {
            state = .failed("Unable to search explore places right now.")
        }
    }

    /// Asynchronously reloads places for pull-to-refresh interactions.
    func refresh() async {
        if !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            await search(query: searchText)
        } else {
            await loadExplorePlaces()
        }
    }

    /// Invoked when a user taps an item in the Explore grid.
    /// Asynchronously fetches that place's details and triggers modal presentation mode.
    /// - Parameter item: The selected `ExploreItem`.
    func didSelect(item: ExploreItem) async {
        guard loadingItemId == nil else { return }
        loadingItemId = item.id
        detailLoadError = nil

        do {
            let detail = try await placeProvider.getPlaceDetails(id: item.placeId)
            self.selectedPlaceDetail = detail
        } catch {
            self.detailLoadError = "Unable to load details for \(item.placeName). Please try again."
        }

        self.loadingItemId = nil
    }

    /// Clears the currently presented detail sheet.
    func dismissDetail() {
        selectedPlaceDetail = nil
        detailLoadError = nil
    }

    // MARK: - Private Helpers

    /// Loads nearby and regional places combining cafes, mountains, parks, and viewpoints.
    private func loadExplorePlaces() async {
        guard let currentCoordinate else {
            state = .locationRequired
            return
        }

        state = .loading
        do {
            let fetched = try await placeProvider.explorePlaces(around: currentCoordinate)
            items = fetched
            state = fetched.isEmpty ? .empty : .loaded
        } catch {
            state = .failed("Unable to load explore places right now.")
        }
    }
}
