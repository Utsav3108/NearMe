//
//  ExploreModels.swift
//  NearMe
//
//  Created by Utsav Hitendrabhai Pandya on 06/10/26.
//

import Foundation

/// Represents the high-level loading and state status of the Explore feed.
/// Conforms to `Equatable` for state transitions and `Sendable` for thread-safe passage.
enum ExploreLoadState: Equatable, Sendable {
    case idle
    case loading
    case loaded
    case empty
    case locationRequired
    case failed(String)
}

/// A lightweight, immutable, and thread-safe (`Sendable`) model representing a visual item in the Explore grid.
///
/// In compliance with Google Places API policies, each photo item retains both the underlying
/// Google Places photo resource reference and its original author attribution.
///
/// Tapping this item in the grid triggers retrieval of the full `PlaceDDetail` corresponding
/// to `placeId`, which is then presented in presentation mode (sheet).
struct ExploreItem: Identifiable, Hashable, Sendable {
    /// Unique identifier for SwiftUI list/grid reconciliation.
    let id: String

    /// The unique Google Place ID of the venue this photo belongs to.
    let placeId: String

    /// The human-readable name of the venue (used for accessibility and title fallbacks).
    let placeName: String

    /// The Google Places photo payload, used by `PlacePhotoLoader` to fetch image bytes.
    let photo: PlacePhoto

    /// The mandatory author attribution required by Google Places API terms of service.
    let attribution: PhotoAttribution?

    /// Initializes a new explore item with explicit metadata.
    init(
        id: String,
        placeId: String,
        placeName: String,
        photo: PlacePhoto,
        attribution: PhotoAttribution? = nil
    ) {
        self.id = id
        self.placeId = placeId
        self.placeName = placeName
        self.photo = photo
        self.attribution = attribution ?? photo.attributions.first
    }
}
