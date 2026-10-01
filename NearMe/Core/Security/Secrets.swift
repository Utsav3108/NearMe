//
//  Secrets.swift
//  NearMe
//
//  Created by Utsav Hitendrabhai Pandya on 02/10/26.
//


import Foundation

enum Secrets {

    private static let plist: [String: Any] = {
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
              ) as? [String: Any] else {
            fatalError("Could not read Secrets.plist")
        }

        return plist
    }()

    static var googleMapsAPIKey: String {
        guard let value = plist["GoogleMapsAPIKey"] as? String else {
            fatalError("GoogleMapsAPIKey missing from Secrets.plist")
        }

        return value
    }

}
