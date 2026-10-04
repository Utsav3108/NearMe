import SwiftData
import SwiftUI

struct CategoryItem {
    let name: String
    let icon: String
}

struct Home: View {
    @Environment(AppRouter.self) private var router
    @Environment(\.modelContext) private var modelContext

    @State private var searchText = ""
    @State private var selectedCategory = PlaceCategory.all
    @State private var homeVM = HomeVM(
        placeProvider: PlaceProvider(), recommendationEngine: RecommendationEngine(), weatherProvider: UnavailableWeatherProvider()
    )

    private let appOrange = Color(red: 254 / 255, green: 98 / 255, blue: 34 / 255)

    private var categories: [CategoryItem] {
        [
            CategoryItem(name: "All", icon: "fork.knife"),
            CategoryItem(name: "Food", icon: "fork.knife"),
            CategoryItem(name: "Cafes", icon: "cup.and.saucer.fill"),
            CategoryItem(name: "Parks", icon: "tree.fill"),
            CategoryItem(name: "Attractions", icon: "binoculars.fill")
        ]
    }
    
    @State private var selectedPlaceDetail : PlaceDDetail? = nil

    var body: some View {
        ZStack {
            Color(uiColor: .systemGroupedBackground)
                .ignoresSafeArea()

            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {
                    headerSection
                    searchBarSection

                    CategorySelector(
                        categories: categories,
                        selectedCategory: categoryBinding,
                        appOrange: appOrange
                    )

                    loadStateMessage

                    if !homeVM.searchResults.isEmpty {
                        placeSection(
                            title: "Search results",
                            places: homeVM.searchResults,
                            section: .search
                        )
                    } else {
                        placeSection(
                            title: "Trending near you",
                            places: homeVM.trendingPlaces,
                            section: .trending
                        )

                        recommendedSection
                    }
                }
                .padding(.top, 12)
                .padding(.bottom, 24)
            }
            
        }
        .toolbar(.hidden, for: .navigationBar)
        .task {
            homeVM.configure(modelContext: modelContext)
            homeVM.start()
        }
        .onChange(of: selectedCategory) { _, category in
            homeVM.select(category: category)
        }
        .sheet(item: $selectedPlaceDetail) { place in
            PlaceDetailView(place: place)
        }
        
        
    }

    private var categoryBinding: Binding<String> {
        Binding(
            get: { selectedCategory.title },
            set: { title in
                selectedCategory = PlaceCategory.allCases.first { $0.title == title } ?? .all
            }
        )
    }

    @ViewBuilder
    private var loadStateMessage: some View {
        switch homeVM.state {
        case .locationRequired:
            Label("Allow location access to discover places near you.", systemImage: "location.slash")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 20)
        case .failed(let message):
            Label(message, systemImage: "exclamationmark.triangle")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 20)
        default:
            EmptyView()
        }
    }

    private var recommendedSection: some View {
        HorizontalPlaceSection(
            title: "Recommended for you",
            actionTitle: "See all",
            action: { _ in }
        ) {
            ForEach(Array(homeVM.recommendedPlaces.enumerated()), id: \.element.id) { index, rankedPlace in
                TrendingPlaceCard(
                    place: rankedPlace.place,
                    distanceText: homeVM.distanceText(for: rankedPlace.place),
                    recommendationReason: rankedPlace.reasons.first,
                    onOpen: {
                        Task {
                            await homeVM.recordOpen(
                                place: rankedPlace.place,
                                section: .recommended,
                                position: index
                            )
                        }
                    }
                )
                .onAppear {
                    Task {
                        await homeVM.recordImpression(
                            place: rankedPlace.place,
                            section: .recommended,
                            position: index
                        )
                    }
                }
            }
        }
    }

    private func placeSection(
        title: String,
        places: [PlaceSummary],
        section: HomeSection
    ) -> some View {
        HorizontalPlaceSection(
            title: title,
            actionTitle: "See all",
            action: { _ in }
        ) {
            ForEach(Array(places.enumerated()), id: \.element.id) { index, place in
                TrendingPlaceCard(
                    place: place,
                    distanceText: homeVM.distanceText(for: place),
                    recommendationReason: nil,
                    onOpen: {
                        
                        Task {
                            print("details are coming for \(place.id)....")
                            selectedPlaceDetail = await homeVM.getDetails(id: place.id)
                            
                            print("selected place detail: ", selectedPlaceDetail?.name ?? "----")
                        }
                        
                        Task {
                            await homeVM.recordOpen(place: place, section: section, position: index)
                        }
                    }
                )
                .onAppear {
                    Task {
                        await homeVM.recordImpression(place: place, section: section, position: index)
                    }
                }
                

            }
        }
    }

    private var headerSection: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Hello,")
                    .font(.footnote)
                    .foregroundStyle(.secondary)

                HStack(spacing: 4) {
                    Text("Utsav")
                        .font(.title2.bold())
                        .foregroundStyle(.primary)
                    Text("👋")
                        .font(.title3)
                }
            }

            Spacer()

            Button {} label: {
                Image(.person)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 44, height: 44)
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(Color(uiColor: .systemGray5), lineWidth: 1.5)
                    )
                    .shadow(color: .black.opacity(0.08), radius: 4, x: 0, y: 2)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 20)
    }

    private var searchBarSection: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 17, weight: .medium))
                .foregroundStyle(.secondary)

            TextField(
                "",
                text: $searchText,
                prompt: Text("Search places, cities or users...")
                    .foregroundColor(.secondary.opacity(0.8))
            )
            .font(.subheadline)
            .foregroundStyle(.primary)
            .autocorrectionDisabled()
            .submitLabel(.search)
            .onSubmit {
                Task { await homeVM.search(query: searchText) }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(uiColor: .systemBackground))
                .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 3)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color(uiColor: .systemGray5).opacity(0.6), lineWidth: 0.5)
        )
        .padding(.horizontal, 20)
    }
}

#Preview {
    Home()
        .environment(AppRouter())
        .modelContainer(for: [PlaceInteraction.self, SavedPlace.self], inMemory: true)
}
