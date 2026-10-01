//
//  HomeVM.swift
//  NearMe
//
//  Created by Utsav Hitendrabhai Pandya on 02/10/26.
//

import Observation
import Foundation

@Observable
@MainActor
class HomeVM {
    
    let placeProvider = PlaceProvider()
    
    func fetchPlaceDetails(placeAddress: String) async {

        do {
            let places = try await placeProvider.fetchPlaceDetails(
                query: "Kankaria Lake, Ahmedabad"
            )
            
            if let lake = places.first {
                print("Name: \(lake.displayName?.text ?? "N/A")")
                print("Address: \(lake.formattedAddress ?? "N/A")")
                print("Rating: \(lake.rating ?? 0.0)")
                if let loc = lake.location {
                    print("Coordinates: \(loc.latitude), \(loc.longitude)")
                }
            } else {
                print("No matching place found.")
            }
        } catch {
            print("Error fetching place: \(error.localizedDescription)")
        }
    }
    
    
    
}
