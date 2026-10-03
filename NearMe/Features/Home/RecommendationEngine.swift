import Foundation

struct RecommendationEngine: Sendable {
    
    func rank(
        candidates: [PlaceSummary],
        context: RecommendationContext,
        popularPlaceIDs: Set<String> = []
    ) -> [RankedPlace] {
        let filtered = candidates.filter(\.isOperational)
        let scored = filtered.map { place in
            score(place, context: context, popularPlaceIDs: popularPlaceIDs)
        }

        return diversify(scored)
    }

    private func score(
        _ place: PlaceSummary,
        context: RecommendationContext,
        popularPlaceIDs: Set<String>
    ) -> RankedPlace {
        let distance = distanceInKilometers(from: context.coordinate, to: place.coordinate)
        let distanceScore = max(0, 1 - (distance / 15))
        let qualityScore = normalizedQuality(rating: place.rating, reviewCount: place.reviewCount)
        let preferenceScore = context.preferences.categoryAffinity[place.category, default: 0]
        let timeScore = context.timeOfDay.preferredCategories.contains(place.category) ? 1.0 : 0.25
        let openScore = place.isOpenNow == true ? 1.0 : place.isOpenNow == nil ? 0.5 : 0.0
        let popularityScore = popularPlaceIDs.contains(place.id) ? 1.0 : 0.0

        let score = (0.25 * preferenceScore)
            + (0.20 * timeScore)
            + (0.18 * distanceScore)
            + (0.14 * openScore)
            + (0.12 * qualityScore)
            + (0.06 * popularityScore)
            + 0.05

        var reasons: [RecommendationReason] = []
        if place.isOpenNow == true { reasons.append(.openNow) }
        if preferenceScore >= 0.5 { reasons.append(.matchesYourInterests) }
        if distance <= 3 { reasons.append(.nearby) }
        if popularityScore > 0 { reasons.append(.popularNearby) }
        if qualityScore >= 0.8 { reasons.append(.greatRating) }

        return RankedPlace(place: place, score: score, reasons: reasons)
    }

    private func diversify(_ places: [RankedPlace]) -> [RankedPlace] {
        places.sorted {
            if $0.score == $1.score {
                return $0.place.name.localizedCaseInsensitiveCompare($1.place.name) == .orderedAscending
            }
            return $0.score > $1.score
        }
    }

    private func normalizedQuality(rating: Double?, reviewCount: Int?) -> Double {
        let ratingScore = max(0, min((rating ?? 0) / 5, 1))
        let reviewConfidence = min(log10(Double((reviewCount ?? 0) + 1)) / 4, 1)
        return (ratingScore * 0.75) + (reviewConfidence * 0.25)
    }

    private func distanceInKilometers(from start: PlaceCoordinate, to end: PlaceCoordinate) -> Double {
        let earthRadius = 6_371.0
        let deltaLatitude = (end.latitude - start.latitude).degreesToRadians
        let deltaLongitude = (end.longitude - start.longitude).degreesToRadians
        let latitude1 = start.latitude.degreesToRadians
        let latitude2 = end.latitude.degreesToRadians
        let a = sin(deltaLatitude / 2) * sin(deltaLatitude / 2)
            + cos(latitude1) * cos(latitude2) * sin(deltaLongitude / 2) * sin(deltaLongitude / 2)
        return earthRadius * 2 * atan2(sqrt(a), sqrt(1 - a))
    }
}

private extension Double {
    var degreesToRadians: Double { self * .pi / 180 }
}
