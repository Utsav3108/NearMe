//
//  Home.swift
//  MyApp
//
//  Created by Utsav Hitendrabhai Pandya on 30/09/26.
//

import SwiftUI

struct CategoryItem {
    let name: String
    let icon: String
}

struct Place: Identifiable {
    let id = UUID()
    let title: String
    let category: String
    var rating: String? = nil
    let distance: String
    let dummySymbol: String
    let gradientColors: [Color]
    let image : String = ""
    let name : String = ""
    var location : String = ""
}


struct Home: View {
    
    // MARK: - Environment
    @Environment(AppRouter.self) private var router
    
    // MARK: - State
    @State private var searchText: String = ""
    @State private var selectedCategory: String = "All"
    
    // MARK: - Constants
    private let appOrange = Color(red: 254 / 255, green: 98 / 255, blue: 34 / 255)
    
    // MARK: - Dummy UI Data
    
    private var categories: [CategoryItem] {
        [
            CategoryItem(name: "All", icon: "fork.knife"),
            CategoryItem(name: "Food", icon: "fork.knife"),
            CategoryItem(name: "Cafes", icon: "cup.and.saucer.fill"),
            CategoryItem(name: "Parks", icon: "tree.fill"),
            CategoryItem(name: "Attractions", icon: "binoculars.fill")
        ]
    }
    
    private var trendingPlaces: [Place] {
        [
            Place(
                title: "Sabarmati Riverfront",
                category: "Attraction",
                rating: "4.7 (328)",
                distance: "1.2 km",
                dummySymbol: "bridge",
                gradientColors: [
                    Color(red: 0.95, green: 0.55, blue: 0.25),
                    Color(red: 0.85, green: 0.35, blue: 0.40),
                    Color(red: 0.25, green: 0.30, blue: 0.55)
                ]
            ),
            Place(
                title: "The Good Food Co.",
                category: "Restaurant",
                rating: "4.5 (1.2K)",
                distance: "500 m",
                dummySymbol: "cup.and.saucer.fill",
                gradientColors: [
                    Color(red: 0.82, green: 0.62, blue: 0.45),
                    Color(red: 0.55, green: 0.35, blue: 0.22),
                    Color(red: 0.30, green: 0.20, blue: 0.15)
                ]
            ),
            Place(
                title: "Kankaria Lake",
                category: "Park & Lake",
                rating: "4.4 (850)",
                distance: "3.4 km",
                dummySymbol: "water.waves",
                gradientColors: [
                    Color(red: 0.25, green: 0.65, blue: 0.75),
                    Color(red: 0.15, green: 0.45, blue: 0.60),
                    Color(red: 0.10, green: 0.25, blue: 0.40)
                ]
            )
        ]
    }
    
    // MARK: - View
    var body: some View {
        ZStack {
            Color(uiColor: .systemGroupedBackground)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 20) {
                        headerSection
                        
                        searchBarSection
                        
                        CategorySelector(
                            categories: categories,
                            selectedCategory: $selectedCategory,
                            appOrange: appOrange
                        )
                        
                        HorizontalPlaceSection(
                            title: "Trending near you",
                            actionTitle: "See all",
                            action: { _ in
                                
                            }
                        ) {
                            ForEach(trendingPlaces) { place in
                                TrendingPlaceCard(place: place)
                            }
                        }
                        
                        HorizontalPlaceSection(
                            title: "Recommended for you",
                            actionTitle: "See all",
                            action: { _ in
                                
                            }
                        ) {
                            ForEach(trendingPlaces) { place in
                                TrendingPlaceCard(place: place)
                            }
                        }
                    }
                    .padding(.top, 12)
                    .padding(.bottom, 24)
                }
                
            }
        }
        .toolbar(.hidden, for: .navigationBar)
    }
    
    // MARK: 1. Header Section
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
            
            Button {
                // Profile action
            } label: {
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
    
    // MARK: 2. Search Bar Section
    private var searchBarSection: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 17, weight: .medium))
                .foregroundStyle(.secondary)
            
            TextField("", text: $searchText, prompt: Text("Search places, cities or users...").foregroundColor(.secondary.opacity(0.8)))
                .font(.subheadline)
                .foregroundStyle(.primary)
                .autocorrectionDisabled()
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
}
