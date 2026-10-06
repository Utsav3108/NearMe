//
//  Secrets.swift
//  NearMe
//
//  Created by Utsav Hitendrabhai Pandya on 02/10/26.
//


import Foundation

/// Thread-safe provider for bundled application secrets.
enum Secrets: Sendable {

    nonisolated private static let apiKey: String = {
        guard let url = Bundle.main.url(
            forResource: "Secrets",
            withExtension: "plist"
        ) else {
            fatalError("Secrets.plist not found")
        }

        guard let data = try? Data(contentsOf: url),
              let plist = try? PropertyListSerialization.propertyList(
                from: data,
                format: nil
              ) as? [String: Any],
              let key = plist["GoogleMapsAPIKey"] as? String else {
            fatalError("GoogleMapsAPIKey missing or unreadable in Secrets.plist")
        }

        return key
    }()

    nonisolated static var googleMapsAPIKey: String {
        apiKey
    }
}
