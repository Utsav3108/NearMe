import Foundation
import SwiftData

@Model
final class PlaceInteraction {
    @Attribute(.unique) var id: UUID
    var placeID: String
    var categoryRawValue: String
    var actionRawValue: String
    var sectionRawValue: String
    var position: Int
    var timestamp: Date

    init(
        placeID: String,
        category: PlaceCategory,
        action: PlaceInteractionAction,
        section: HomeSection,
        position: Int,
        timestamp: Date = .now
    ) {
        self.id = UUID()
        self.placeID = placeID
        self.categoryRawValue = category.rawValue
        self.actionRawValue = action.rawValue
        self.sectionRawValue = section.rawValue
        self.position = position
        self.timestamp = timestamp
    }
}

@Model
final class SavedPlace {
    @Attribute(.unique) var placeID: String
    var savedAt: Date
    var note: String?

    init(placeID: String, note: String? = nil, savedAt: Date = .now) {
        self.placeID = placeID
        self.note = note
        self.savedAt = savedAt
    }
}

enum PlaceInteractionAction: String, Sendable {
    case impression
    case opened
    case saved
    case visited
    case dismissed

    nonisolated var preferenceWeight: Double {
        switch self {
        case .impression: 0
        case .opened: 0.25
        case .saved: 1
        case .visited: 1.25
        case .dismissed: -0.75
        }
    }
}

enum HomeSection: String {
    case trending
    case recommended
    case search
}

actor InteractionRecorder {
    private let modelContext: ModelContext
    private var recordedImpressions = Set<String>()

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func record(
        _ action: PlaceInteractionAction,
        place: PlaceSummary,
        section: HomeSection,
        position: Int
    ) {
        let impressionKey = "\(section.rawValue)-\(place.id)"
        guard action != .impression || recordedImpressions.insert(impressionKey).inserted else {
            return
        }

        modelContext.insert(
            PlaceInteraction(
                placeID: place.id,
                category: place.category,
                action: action,
                section: section,
                position: position
            )
        )
        try? modelContext.save()
    }

    func preferenceProfile() -> UserPreferenceProfile {
        let descriptor = FetchDescriptor<PlaceInteraction>(
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )
        let events = (try? modelContext.fetch(descriptor)) ?? []
        let now = Date.now

        var affinity: [PlaceCategory: Double] = [:]
        for event in events {
            guard let category = PlaceCategory(rawValue: event.categoryRawValue),
                  let action = PlaceInteractionAction(rawValue: event.actionRawValue) else {
                continue
            }

            let ageInDays = max(0, now.timeIntervalSince(event.timestamp) / 86_400)
            let decay = exp(-ageInDays / 30)
            affinity[category, default: 0] += action.preferenceWeight * decay
        }

        let normalized = affinity.mapValues { max(0, min($0 / 3, 1)) }
        return UserPreferenceProfile(categoryAffinity: normalized)
    }
}
