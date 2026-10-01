//
//  PlaceProvider.swift
//  NearMe
//
//  Created by Utsav Hitendrabhai Pandya on 02/10/26.
//
import Foundation

struct PlaceSearchResponse: Decodable {
    let places: [PlaceGMS]?
}

struct PlaceGMS: Decodable {
    let id: String?
    let displayName: DisplayName?
    let formattedAddress: String?
    let location: LatLng?
    let rating: Double?
}

struct DisplayName: Decodable {
    let text: String
    let languageCode: String?
}

struct LatLng: Decodable {
    let latitude: Double
    let longitude: Double
}



class PlaceProvider {
    
    let network = Network()
    
    // MARK: Places API Request
    func fetchPlaceDetails(query: String) async throws -> [PlaceGMS] {
        guard let url = URL(string: "https://places.googleapis.com/v1/places:searchText") else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Authenticate via header
        request.setValue(Secrets.googleMapsAPIKey, forHTTPHeaderField: "X-Goog-Api-Key")
        
        // FieldMask controls what data is returned and determines your billing SKU
        request.setValue(
            "places.id,places.displayName,places.formattedAddress,places.location,places.rating",
            forHTTPHeaderField: "X-Goog-FieldMask"
        )
        
        let body: [String: Any] = [
            "textQuery": query
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let result: PlaceSearchResponse = try await network.perform(request: request)
        return result.places ?? []
    }
}
