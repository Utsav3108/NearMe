import Foundation

actor PlacePhotoLoader {
    static let shared = PlacePhotoLoader()

    private let session: URLSession

    init() {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.urlCache = nil
        configuration.requestCachePolicy = .reloadIgnoringLocalCacheData
        session = URLSession(configuration: configuration)
    }

    func imageData(for photo: PlacePhoto, maxWidth: Int = 420, maxHeight: Int = 280) async throws -> Data {
        guard let baseURL = URL(string: "https://places.googleapis.com/v1/\(photo.resourceName)/media") else {
            throw URLError(.badURL)
        }

        var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false)
        components?.queryItems = await [
            URLQueryItem(name: "maxWidthPx", value: String(maxWidth)),
            URLQueryItem(name: "maxHeightPx", value: String(maxHeight)),
            URLQueryItem(name: "key", value: Secrets.googleMapsAPIKey)
        ]

        guard let url = components?.url else {
            throw URLError(.badURL)
        }

        var request = URLRequest(url: url)
        request.cachePolicy = .reloadIgnoringLocalCacheData
        let (data, response) = try await session.data(for: request)

        guard let response = response as? HTTPURLResponse,
              (200...299).contains(response.statusCode) else {
            throw URLError(.badServerResponse)
        }

        return data
    }
}
