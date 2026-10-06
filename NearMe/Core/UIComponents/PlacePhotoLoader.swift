import Foundation

/// A thread-safe image fetcher that downloads and caches Google Places photos.
///
/// **Concurrency & Discipline:**
/// Implemented as an `actor` because it coordinates concurrent asynchronous image downloading tasks
/// across multiple views (Explore grid cells, Home trending cards, Detail hero carousels).
/// Actor isolation protects its network session and internal coordination state from data races.
actor PlacePhotoLoader {
    static let shared = PlacePhotoLoader()

    private let cache = PhotoCache()
    private let session: URLSession

    init() {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.urlCache = nil
        configuration.requestCachePolicy = .reloadIgnoringLocalCacheData
        session = URLSession(configuration: configuration)
    }

    /// Fetches image data for a given `PlacePhoto`, returning cached data if available.
    ///
    /// - Parameters:
    ///   - photo: The `PlacePhoto` describing the Google Places photo resource.
    ///   - maxWidth: Maximum pixel width requested from Google Places Media API.
    ///   - maxHeight: Maximum pixel height requested from Google Places Media API.
    /// - Returns: Raw image `Data`.
    func imageData(for photo: PlacePhoto, maxWidth: Int = 600, maxHeight: Int = 600) async throws -> Data {
        let cacheKey = photo.resourceName.isEmpty ? photo.placeId : photo.resourceName
        
        if let cacheData = await cache.get(key: cacheKey) {
            return cacheData
        }

        guard let baseURL = URL(string: "https://places.googleapis.com/v1/\(photo.resourceName)/media") else {
            throw URLError(.badURL)
        }

        var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false)
        components?.queryItems = [
            URLQueryItem(name: "maxWidthPx", value: String(maxWidth)),
            URLQueryItem(name: "maxHeightPx", value: String(maxHeight)),
            URLQueryItem(name: "key", value: Secrets.googleMapsAPIKey)
        ]

        guard let url = components?.url else {
            throw URLError(.badURL)
        }

        var request = URLRequest(url: url)
        request.cachePolicy = .returnCacheDataElseLoad
        let (data, response) = try await session.data(for: request)

        guard let response = response as? HTTPURLResponse,
              (200...299).contains(response.statusCode) else {
            throw URLError(.badServerResponse)
        }

        Task {
            await cache.set(key: cacheKey, data: data)
        }
        
        return data
    }
}

/// An in-memory cache for downloaded photo bytes.
///
/// **Concurrency & Discipline:**
/// Implemented as an `actor` to guarantee serialized, thread-safe access to the underlying `NSCache`
/// across concurrent download tasks without needing manual locks or synchronization primitives.
actor PhotoCache {
    private let cacheDict: NSCache<NSString, NSData>

    init() {
        let cache = NSCache<NSString, NSData>()
        cache.countLimit = 300
        cache.totalCostLimit = 100 * 1024 * 1024 // 100 MB
        self.cacheDict = cache
    }

    func set(key: String, data: Data) {
        let nsData = data as NSData
        let nsKey = key as NSString
        cacheDict.setObject(nsData, forKey: nsKey, cost: data.count)
    }

    func get(key: String) -> Data? {
        let nsData = cacheDict.object(forKey: key as NSString)
        return nsData as Data?
    }
}
