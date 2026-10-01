//
//  apikey.swift
//  NearMe
//
//  Created by Utsav Hitendrabhai Pandya on 01/10/26.
//

let mapsAPI = "GOOGLE_PLACE_API"

import Foundation

class Network {
    
    var session: URLSession
    
    init() {
        self.session = URLSession(configuration: .ephemeral)
    }
    
    func perform<T: Decodable>(request: URLRequest) async throws -> T {
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            let errorText = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw URLError(.badServerResponse, userInfo: [NSLocalizedDescriptionKey: errorText])
        }
        
        return try JSONDecoder().decode(T.self, from: data)
    }
    
    // MARK: Places API Request
    func fetchPlaceDetails(query: String, apiKey: String) async throws -> [PlaceGMS] {
        guard let url = URL(string: "https://places.googleapis.com/v1/places:searchText") else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Authenticate via header
        request.setValue(apiKey, forHTTPHeaderField: "X-Goog-Api-Key")
        
        // FieldMask controls what data is returned and determines your billing SKU
        request.setValue(
            "places.id,places.displayName,places.formattedAddress,places.location,places.rating",
            forHTTPHeaderField: "X-Goog-FieldMask"
        )
        
        let body: [String: Any] = [
            "textQuery": query
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let result: PlaceSearchResponse = try await perform(request: request)
        return result.places ?? []
    }
}

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
