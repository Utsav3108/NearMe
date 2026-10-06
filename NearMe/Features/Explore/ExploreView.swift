//
//  ExploreView.swift
//  NearMe
//
//  Created by Utsav Hitendrabhai Pandya on 06/10/26.
//

import SwiftUI

/// The root view for the Explore tab, presenting an Instagram Explore-style visual grid.
///
/// **Separation of Concerns:**
/// This view contains strictly declarative layout and user interaction bindings.
/// All data queries, location updates, and state changes are managed by `ExploreVM`.
///
/// **Design:**
/// - Instagram-style seamless 3-column mosaic grid with alternating 2x2 featured tiles and 1x1 tiles.
/// - Unfiltered, diverse mix of cafes, mountains, parks, and regional viewpoints (near and far).
/// - Top search bar matching Home styling with `appOrange` accents.
/// - Tapping an image presents the location details in presentation mode (`PlaceDetailView`).
struct ExploreView: View {

    @State private var exploreVM = ExploreVM()

    private let appOrange = Color(red: 254 / 255, green: 98 / 255, blue: 34 / 255)

    var body: some View {
        GeometryReader { proxy in
            let screenWidth = proxy.size.width

            ZStack(alignment: .top) {
                Color(uiColor: .systemBackground)
                    .ignoresSafeArea()

                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 0) {
                        searchBarSection
                            .padding(.horizontal, 16)
                            .padding(.top, 10)
                            .padding(.bottom, 12)

                        statusBannerSection
                            .padding(.horizontal, 16)
                            .padding(.bottom, 8)

                        gridSection(width: screenWidth)
                    }
                    .padding(.bottom, 32)
                }
                .refreshable {
                    await exploreVM.refresh()
                }
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .task {
            exploreVM.start()
        }
        .sheet(item: $exploreVM.selectedPlaceDetail) { detail in
            PlaceDetailView(place: detail)
        }
        .alert("Unable to Load Place", isPresented: Binding(
            get: { exploreVM.detailLoadError != nil },
            set: { if !$0 { exploreVM.detailLoadError = nil } }
        )) {
            Button("OK", role: .cancel) {
                exploreVM.detailLoadError = nil
            }
        } message: {
            if let error = exploreVM.detailLoadError {
                Text(error)
            }
        }
    }

    // MARK: - Search Bar Section

    private var searchBarSection: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(.secondary)

            TextField(
                "",
                text: $exploreVM.searchText,
                prompt: Text("Search places, mountains, cafes, parks...")
                    .foregroundColor(.secondary.opacity(0.8))
            )
            .font(.subheadline)
            .foregroundStyle(.primary)
            .autocorrectionDisabled()
            .submitLabel(.search)
            .onSubmit {
                Task {
                    await exploreVM.search(query: exploreVM.searchText)
                }
            }

            if !exploreVM.searchText.isEmpty {
                Button {
                    exploreVM.searchText = ""
                    Task {
                        await exploreVM.search(query: "")
                    }
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 11)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color(uiColor: .secondarySystemBackground))
        )
    }

    // MARK: - Status Banner Section

    @ViewBuilder
    private var statusBannerSection: some View {
        switch exploreVM.state {
        case .locationRequired:
            Label("Allow location access to discover places near and far.", systemImage: "location.slash")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)

        case .failed(let message):
            HStack {
                Label(message, systemImage: "exclamationmark.triangle")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                Spacer()
                Button("Retry") {
                    exploreVM.start()
                }
                .font(.footnote.weight(.semibold))
                .tint(appOrange)
            }

        default:
            EmptyView()
        }
    }

    // MARK: - Grid Section

    @ViewBuilder
    private func gridSection(width: CGFloat) -> some View {
        switch exploreVM.state {
        case .loading where exploreVM.items.isEmpty:
            loadingSkeleton(width: width)

        case .empty:
            ContentUnavailableView(
                "No Places Found",
                systemImage: "photo.on.rectangle.angled",
                description: Text("Try searching for something else or pull down to refresh.")
            )
            .padding(.top, 60)

        default:
            InstagramExploreGrid(
                items: exploreVM.items,
                totalWidth: width,
                loadingItemId: exploreVM.loadingItemId,
                onSelect: { item in
                    Task {
                        await exploreVM.didSelect(item: item)
                    }
                }
            )
        }
    }

    // MARK: - Loading Skeleton

    private func loadingSkeleton(width: CGFloat) -> some View {
        let spacing: CGFloat = 2
        let smallSize = (width - 2 * spacing) / 3
        let largeSize = 2 * smallSize + spacing

        return VStack(spacing: spacing) {
            HStack(spacing: spacing) {
                RoundedRectangle(cornerRadius: 0)
                    .fill(Color(uiColor: .secondarySystemBackground))
                    .frame(width: largeSize, height: largeSize)
                VStack(spacing: spacing) {
                    RoundedRectangle(cornerRadius: 0)
                        .fill(Color(uiColor: .secondarySystemBackground))
                        .frame(width: smallSize, height: smallSize)
                    RoundedRectangle(cornerRadius: 0)
                        .fill(Color(uiColor: .secondarySystemBackground))
                        .frame(width: smallSize, height: smallSize)
                }
            }
            HStack(spacing: spacing) {
                ForEach(0..<3, id: \.self) { _ in
                    RoundedRectangle(cornerRadius: 0)
                        .fill(Color(uiColor: .secondarySystemBackground))
                        .frame(width: smallSize, height: smallSize)
                }
            }
        }
        .overlay(
            ProgressView()
                .tint(.secondary)
        )
    }
}

#Preview {
    ExploreView()
}
