import SwiftUI

struct TrendingPlaceCard: View {
    let place: PlaceSummary
    let distanceText: String
    let recommendationReason: RecommendationReason?
    let onOpen: () -> Void

    @State private var photoImage: Image?
    @State private var photoLoadFailed = false

    var body: some View {
        Button(action: onOpen) {
            VStack(alignment: .leading, spacing: 0) {
                photoArea

                VStack(alignment: .leading, spacing: 8) {
                    Text(place.name)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(.primary)
                        .lineLimit(1)

                    Text(recommendationReason?.displayText ?? place.category.title)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(Color(uiColor: .systemGray6))
                        )
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .frame(width: 210, alignment: .leading)
                .background(Color(uiColor: .systemBackground))
            }
            .frame(width: 210)
            .background(Color(uiColor: .systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(Color(uiColor: .systemGray5).opacity(0.6), lineWidth: 0.8)
            )
        }
        .buttonStyle(.plain)
        .task(id: place.primaryPhoto?.resourceName) {
            await loadPhoto()
        }
    }

    private var photoArea: some View {
        ZStack(alignment: .bottomLeading) {
            Group {
                if let photoImage {
                    photoImage
                        .resizable()
                        .scaledToFill()
                } else {
                    LinearGradient(
                        colors: [
                            Color.orange.opacity(0.8),
                            Color.pink.opacity(0.55),
                            Color.indigo.opacity(0.75)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .overlay {
                        if photoLoadFailed {
                            Image(systemName: "photo")
                                .font(.system(size: 34, weight: .light))
                                .foregroundStyle(.white.opacity(0.85))
                        } else {
                            ProgressView()
                                .tint(.white)
                        }
                    }
                }
            }
            .frame(width: 210, height: 140)
            .clipped()

            HStack(spacing: 6) {
                if let rating = place.rating {
                    badge(icon: "star.fill", text: ratingText(rating), iconColor: .yellow)
                }
                badge(icon: "mappin", text: distanceText, iconColor: .white)
            }
            .padding(10)

            if let attribution = place.primaryPhoto?.attributions.first {
                photoAttribution(attribution)
                    .padding(8)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
            }
        }
        .clipShape(
            UnevenRoundedRectangle(
                topLeadingRadius: 18,
                bottomLeadingRadius: 0,
                bottomTrailingRadius: 0,
                topTrailingRadius: 18,
                style: .continuous
            )
        )
    }

    private func badge(icon: String, text: String, iconColor: Color) -> some View {
        HStack(spacing: 3) {
            Image(systemName: icon)
                .font(.system(size: 10))
                .foregroundStyle(iconColor)
            Text(text)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.white)
        }
        .padding(.horizontal, 7)
        .padding(.vertical, 4)
        .background(Capsule().fill(.black.opacity(0.45)))
    }

    @ViewBuilder
    private func photoAttribution(_ attribution: PhotoAttribution) -> some View {
        if let uri = attribution.uri {
            Link(attribution.displayName, destination: uri)
                .font(.caption2.weight(.medium))
                .foregroundStyle(.white)
                .lineLimit(1)
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(Capsule().fill(.black.opacity(0.45)))
        } else {
            Text(attribution.displayName)
                .font(.caption2.weight(.medium))
                .foregroundStyle(.white)
                .lineLimit(1)
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(Capsule().fill(.black.opacity(0.45)))
        }
    }

    private func ratingText(_ rating: Double) -> String {
        String(format: "%.1f", rating)
    }

    private func loadPhoto() async {
        guard let photo = place.primaryPhoto else {
            photoLoadFailed = true
            return
        }

        do {
            let data = try await PlacePhotoLoader.shared.imageData(for: photo)
            guard !Task.isCancelled, let image = UIImage(data: data) else {
                photoLoadFailed = true
                return
            }
            photoImage = Image(uiImage: image)
        } catch is CancellationError {
            return
        } catch {
            photoLoadFailed = true
        }
    }
}
