//
//  apikey.swift
//  NearMe
//
//  Created by Utsav Hitendrabhai Pandya on 01/10/26.
//

import Foundation

/// An HTTP client responsible for executing network requests and decoding responses.
///
/// **Concurrency & Discipline:**
/// Implemented as a `final class: Sendable` because its dependencies (`URLSession`) are immutable
/// (`let session`) and inherently thread-safe. Being `Sendable` allows it to be injected safely into
/// repositories and providers across concurrent tasks without introducing actor serialization bottlenecks.
final class Network: Sendable {
    
    let session: URLSession
    
    nonisolated init() {
        let configuration = URLSessionConfiguration.default

        let cache = URLCache(
            memoryCapacity: 50 * 1024 * 1024,      // 50 MB
            diskCapacity: 200 * 1024 * 1024,       // 200 MB
            diskPath: "network-cache"
        )

        configuration.urlCache = cache
        configuration.requestCachePolicy = .returnCacheDataElseLoad

        self.session = URLSession(configuration: configuration)
    }
    
    func perform<T: Decodable>(request: URLRequest) async throws -> T {
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            let errorText = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw URLError(.badServerResponse, userInfo: [NSLocalizedDescriptionKey: errorText])
        }
        
        let datajson = try? JSONSerialization.jsonObject(with: data)
        
        print("response json: ", datajson as Any)
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        let result = try decoder.decode(T.self, from: data)
        
        return result
    }
}
