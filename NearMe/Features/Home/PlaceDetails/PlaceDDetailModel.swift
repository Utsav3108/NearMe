//
//  PlaceDetail.swift
//  NearMe
//
//  Created by Utsav Hitendrabhai Pandya on 04/10/26.
//


import Foundation

// MARK: Place Detail

struct PlaceDDetail: Codable, Sendable, Identifiable {

    let id: String
    let displayName: PlaceDisplayName
    let formattedAddress: String?
    let location: PlaceLocation
    let photos: [PlaceDPhoto]
    let primaryTypeDisplayName: PlaceDisplayName?
    let rating: Double?
    let reviews: [PlaceReview]
    let types: [String]
    let userRatingCount: Int?
    let websiteURI: URL?

    var name: String {
        displayName.text
    }

    var category: String? {
        primaryTypeDisplayName?.text
    }
}


// MARK: Display Name

struct PlaceDisplayName: Codable, Sendable {

    let languageCode: String
    let text: String
}


// MARK: Location
struct PlaceLocation: Codable, Sendable {

    let latitude: Double
    let longitude: Double
}


// MARK: - Photo
struct PlaceDPhoto: Codable, Sendable, Identifiable {

    let name: String
    let widthPx: Int
    let heightPx: Int
    let authorAttributions: [PlaceAuthorAttribution]
    let googleMapsURI: URL?
    let flagContentURI: URL?

    var id: String {
        name
    }

    var aspectRatio: Double {
        guard heightPx > 0 else { return 1 }
        return Double(widthPx) / Double(heightPx)
    }
}


// MARK: Review

struct PlaceReview: Codable, Sendable, Identifiable {

    let name: String
    let authorAttribution: PlaceAuthorAttribution
    let originalText: PlaceLocalizedText?
    let text: PlaceLocalizedText?
    let publishTime: Date?
    let rating: Int?
    let relativePublishTimeDescription: String?
    let googleMapsURI: URL?
    let flagContentURI: URL?

    var id: String {
        name
    }
}


// MARK: Author Attribution

struct PlaceAuthorAttribution: Codable, Sendable {

    let displayName: String
    let photoURI: URL?
    let uri: URL?
}


// MARK: Localized Text

struct PlaceLocalizedText: Codable, Sendable {

    let languageCode: String
    let text: String
}
