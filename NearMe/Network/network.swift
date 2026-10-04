//
//  apikey.swift
//  NearMe
//
//  Created by Utsav Hitendrabhai Pandya on 01/10/26.
//

let mapsAPI = Secrets.googleMapsAPIKey

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
        
        let datajson = try? JSONSerialization.jsonObject(with: data)
        
        print("response json: ", datajson)
        
        return try JSONDecoder().decode(T.self, from: data)
    }

}
