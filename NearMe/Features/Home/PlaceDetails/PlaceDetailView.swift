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
    
    @State private var isSaved = false
    
    @State private var currentOptionSelectedIndex : Int = 0

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
                    PlaceImage(
                        photo: photo.makePhoto(
                            id: "\(place.id)\(index)"
                        )
                    )
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

            OptionTag(
                title: "Directions",
                icon: "arrow.triangle.turn.up.right.diamond.fill",
                isPrimary: currentOptionSelectedIndex == 0
            ) {
                currentOptionSelectedIndex = 0
                openInAppleMaps()
            }

            OptionTag(
                title: "Call",
                icon: "phone.fill",
                isPrimary: currentOptionSelectedIndex == 1
            ) {
                currentOptionSelectedIndex = 1
                callPlace()
            }

            OptionTag(
                title: "Save",
                icon: "bookmark",
                activeIcon: "bookmark.fill",
                isPrimary: currentOptionSelectedIndex == 2
            ) {
                currentOptionSelectedIndex = 2
                toggleSave()
            }

            moreMenu
        }
        .padding(.horizontal, 20)
    }
    
    private func callPlace() {
        guard let phoneNumber = .some("3453333333333") else {
            return
        }

        let digits = phoneNumber.filter {
            $0.isNumber || $0 == "+"
        }

        guard let url = URL(string: "tel://\(digits)") else {
            return
        }

        UIApplication.shared.open(url)
    }

    private func toggleSave() {
        if isSaved {
            //savedPlaces.remove(place.id)
        } else {
            //savedPlaces.insert(place.id)
        }

        isSaved.toggle()
    }
    
    private var moreMenu: some View {
        Menu {
            Button {
                sharePlace()
            } label: {
                Label("Share Place", systemImage: "square.and.arrow.up")
            }

            Button {
                openInAppleMaps()
            } label: {
                Label("Open in Apple Maps", systemImage: "map")
            }

            Divider()

            Button {
                //reportPlace()
            } label: {
                Label("Report an Issue", systemImage: "exclamationmark.bubble")
            }

        } label: {
            VStack(spacing: 7) {
                Image(systemName: "ellipsis")
                    .font(.headline)

                Text("More")
                    .font(.caption.weight(.medium))
            }
            .foregroundStyle(Color.accentColor)
            .frame(maxWidth: .infinity)
            .frame(height: 72)
            .background(
                Color(uiColor: .secondarySystemBackground),
                in: RoundedRectangle(cornerRadius: 18)
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
