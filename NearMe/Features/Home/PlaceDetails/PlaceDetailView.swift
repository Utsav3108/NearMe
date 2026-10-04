//
//  PlaceDetailView.swift
//  NearMe
//
//  Created by Utsav Hitendrabhai Pandya on 04/10/26.
//


import SwiftUI
import MapKit

struct PlaceDetailView: View {

    let place: PlaceDDetail

    @Environment(\.dismiss) private var dismiss

    @State private var selectedPhotoIndex = 0

    private var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(
            latitude: place.location.latitude,
            longitude: place.location.longitude
        )
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {

                heroSection

                VStack(alignment: .leading, spacing: 28) {
                    overviewSection
                    actionSection
                    locationSection
                    photosSection
                    reviewsSection
                }
                .padding(.top, 24)
            }
        }
        .background(Color(uiColor: .systemGroupedBackground))
        .ignoresSafeArea(edges: .top)
        .toolbar(.hidden, for: .navigationBar)
        .onAppear {
            Task {
                
            }
        }
    }
}

// MARK: - Hero

private extension PlaceDetailView {

    var heroSection: some View {
        ZStack(alignment: .top) {

            TabView(selection: $selectedPhotoIndex) {
                ForEach(
                    Array(place.photos.enumerated()),
                    id: \.element.id
                ) { index, photo in

                    // Replace this with your Google Places photo URL builder.
                    Color(uiColor: .secondarySystemBackground)
                        .overlay {
                            Image(systemName: "photo")
                                .font(.largeTitle)
                                .foregroundStyle(.secondary)
                        }
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .frame(height: 390)

            LinearGradient(
                colors: [
                    .black.opacity(0.30),
                    .clear,
                    .black.opacity(0.12)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 390)
            .allowsHitTesting(false)

            HStack {
                circularButton("chevron.left") {
                    dismiss()
                }

                Spacer()

                circularButton("square.and.arrow.up") {
                    sharePlace()
                }

                circularButton("ellipsis") {
                    // More actions
                }
            }
            .padding(.horizontal, 18)
            .padding(.top, 54)

            if place.photos.count > 1 {
                Text(
                    "\(selectedPhotoIndex + 1) / \(place.photos.count)"
                )
                .font(.caption.weight(.semibold))
                .foregroundStyle(.white)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(.black.opacity(0.55))
                .clipShape(Capsule())
                .frame(
                    maxWidth: .infinity,
                    alignment: .trailing
                )
                .padding(.horizontal, 18)
                .padding(.top, 350)
            }
        }
    }

    func circularButton(
        _ systemImage: String,
        action: @escaping () -> Void
    ) -> some View {

        Button(action: action) {
            Image(systemName: systemImage)
                .font(.headline.weight(.semibold))
                .foregroundStyle(.primary)
                .frame(width: 42, height: 42)
                .background(.ultraThinMaterial)
                .clipShape(Circle())
        }
    }
}

// MARK: - Overview

private extension PlaceDetailView {

    var overviewSection: some View {
        VStack(alignment: .leading, spacing: 8) {

            Text(place.name)
                .font(.system(size: 30, weight: .bold))
                .foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 7) {

                if let category = place.category {
                    Text(category)
                        .foregroundStyle(.secondary)
                }

                Text("•")
                    .foregroundStyle(.tertiary)

                ratingView
            }
            .font(.subheadline)
        }
        .padding(.horizontal, 20)
    }

    var ratingView: some View {
        HStack(spacing: 4) {

            Image(systemName: "star.fill")
                .foregroundStyle(.yellow)

            if let rating = place.rating {
                Text(String(format: "%.1f", rating))
                    .foregroundStyle(.primary)
            }

            if let count = place.userRatingCount {
                Text("(\(count.formatted()))")
                    .foregroundStyle(.secondary)
            }
        }
    }
}

// MARK: - Actions

private extension PlaceDetailView {

    var actionSection: some View {
        HStack(spacing: 12) {

            actionButton(
                title: "Directions",
                icon: "arrow.triangle.turn.up.right.diamond.fill",
                primary: true
            ) {
                openInAppleMaps()
            }

            actionButton(
                title: "Call",
                icon: "phone.fill"
            ) {
                // Phone number isn't present in this API response.
            }

            actionButton(
                title: "Save",
                icon: "bookmark"
            ) {
                // Save action
            }

            actionButton(
                title: "More",
                icon: "ellipsis"
            ) {
                // More actions
            }
        }
        .padding(.horizontal, 20)
    }

    func actionButton(
        title: String,
        icon: String,
        primary: Bool = false,
        action: @escaping () -> Void
    ) -> some View {

        Button(action: action) {
            VStack(spacing: 7) {

                Image(systemName: icon)
                    .font(.headline)

                Text(title)
                    .font(.caption.weight(.medium))
            }
            .foregroundStyle(
                primary
                    ? Color.white
                    : Color.accentColor
            )
            .frame(maxWidth: .infinity)
            .frame(height: 72)
            .background(
                primary
                    ? Color.accentColor
                    : Color(uiColor: .secondarySystemBackground)
            )
            .clipShape(
                RoundedRectangle(cornerRadius: 18)
            )
        }
    }
}

// MARK: - Location

private extension PlaceDetailView {

    var locationSection: some View {
        VStack(alignment: .leading, spacing: 14) {

            sectionHeader(
                title: "Location",
                icon: "mappin.and.ellipse"
            )

            Text(place.formattedAddress ?? "Address unavailable")
                .font(.body)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            appleMapPreview
        }
        .padding(.horizontal, 20)
    }

    var appleMapPreview: some View {
        Button {
            openInAppleMaps()
        } label: {

            ZStack(alignment: .bottomTrailing) {

                Map(
                    initialPosition: .region(
                        MKCoordinateRegion(
                            center: coordinate,
                            latitudinalMeters: 900,
                            longitudinalMeters: 900
                        )
                    )
                ) {
                    Marker(
                        place.name,
                        coordinate: coordinate
                    )
                    .tint(.red)
                }
                .mapStyle(.standard)
                .allowsHitTesting(false)

                HStack(spacing: 6) {
                    Image(systemName: "arrow.up.right")
                    Text("Open in Maps")
                }
                .font(.caption.weight(.semibold))
                .foregroundStyle(.primary)
                .padding(.horizontal, 12)
                .padding(.vertical, 9)
                .background(.regularMaterial)
                .clipShape(Capsule())
                .padding(12)
            }
            .frame(height: 210)
            .clipShape(
                RoundedRectangle(cornerRadius: 20)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Photos

private extension PlaceDetailView {

    var photosSection: some View {
        VStack(alignment: .leading, spacing: 14) {

            sectionHeader(
                title: "Photos",
                icon: "photo.on.rectangle"
            )

            ScrollView(
                .horizontal,
                showsIndicators: false
            ) {
                HStack(spacing: 10) {

                    ForEach(
                        Array(place.photos.enumerated()),
                        id: \.element.id
                    ) { _, photo in

                        photoPlaceholder(photo)
                    }
                }
            }
        }
        .padding(.horizontal, 20)
    }

    @ViewBuilder
    func photoPlaceholder(
        _ photo: PlaceDPhoto
    ) -> some View {

        // Plug your Google Places photo URL here.
        Rectangle()
            .fill(Color(uiColor: .secondarySystemBackground))
            .frame(width: 150, height: 115)
            .overlay {
                Image(systemName: "photo")
                    .foregroundStyle(.secondary)
            }
            .clipShape(
                RoundedRectangle(cornerRadius: 16)
            )
    }
}

// MARK: - Reviews

private extension PlaceDetailView {

    var reviewsSection: some View {
        VStack(alignment: .leading, spacing: 18) {

            HStack {
                sectionHeader(
                    title: "Reviews",
                    icon: "star.bubble"
                )

                Spacer()

                if let count = place.userRatingCount {
                    Text("\(count.formatted()) reviews")
                        .font(.subheadline)
                        .foregroundStyle(.blue)
                }
            }

            if let rating = place.rating {
                HStack(spacing: 10) {

                    Text(String(format: "%.1f", rating))
                        .font(.system(size: 36, weight: .bold))

                    VStack(alignment: .leading, spacing: 3) {

                        HStack(spacing: 2) {
                            ForEach(0..<5, id: \.self) { _ in
                                Image(systemName: "star.fill")
                                    .font(.caption)
                                    .foregroundStyle(.yellow)
                            }
                        }

                        Text("Based on \(place.userRatingCount ?? 0) ratings")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            ForEach(
                place.reviews.prefix(3)
            ) { review in

                reviewRow(review)
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 32)
    }

    func reviewRow(
        _ review: PlaceReview
    ) -> some View {

        VStack(alignment: .leading, spacing: 10) {

            HStack {

                Text(review.authorAttribution.displayName)
                    .font(.subheadline.weight(.semibold))

                Spacer()

                if let rating = review.rating {
                    HStack(spacing: 3) {
                        Image(systemName: "star.fill")
                        Text("\(rating)")
                    }
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
                }
            }

            if let text = review.text?.text {
                Text(text)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(4)
            }

            if let date = review.relativePublishTimeDescription {
                Text(date)
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Helpers

private extension PlaceDetailView {

    func sectionHeader(
        title: String,
        icon: String
    ) -> some View {

        HStack(spacing: 9) {
            Image(systemName: icon)
                .foregroundStyle(.blue)

            Text(title)
                .font(.headline)
        }
    }

    func openInAppleMaps() {

        let item = MKMapItem(
            placemark: MKPlacemark(
                coordinate: coordinate
            )
        )

        item.name = place.name

        item.openInMaps(
            launchOptions: [
                MKLaunchOptionsDirectionsModeKey:
                    MKLaunchOptionsDirectionsModeDriving
            ]
        )
    }

    func sharePlace() {
        // Connect to your share sheet.
    }
}
