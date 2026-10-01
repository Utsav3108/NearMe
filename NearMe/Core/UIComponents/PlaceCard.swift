//
//  TrendingPlaceCard.swift
//  NearMe
//
//  Created by Utsav Hitendrabhai Pandya on 01/10/26.
//

import SwiftUI

struct TrendingPlaceCard: View {

    let place: Place
    var appOrange: Color = .orange

    var body: some View {

        VStack(alignment: .leading, spacing: 0) {
            // Card Image Area with dummy icon & badges
            ZStack(alignment: .bottomLeading) {
                ZStack {
                    LinearGradient(
                        colors: place.gradientColors,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    
                    VStack {
                        Image(systemName: place.dummySymbol)
                            .font(.system(size: 40, weight: .light))
                            .foregroundStyle(.white.opacity(0.85))
                            .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
                    }
                }
                .frame(width: 210, height: 140)
                
                // Overlay Badges (Rating & Distance)
                HStack(spacing: 6) {
                    // Rating Pill
                    HStack(spacing: 3) {
                        Image(systemName: "star.fill")
                            .font(.system(size: 10))
                            .foregroundStyle(.yellow)
                        Text(place.rating ?? "-")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(.white)
                    }
                    .padding(.horizontal, 7)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(Color.black.opacity(0.45))
                    )
                    
                    // Distance Pill
                    HStack(spacing: 3) {
                        Image(systemName: "mappin")
                            .font(.system(size: 10))
                            .foregroundStyle(.white)
                        Text(place.distance)
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(.white)
                    }
                    .padding(.horizontal, 7)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(Color.black.opacity(0.45))
                    )
                }
                .padding(10)
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
            
            // Bottom Info Area
            VStack(alignment: .leading, spacing: 8) {
                Text(place.title)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                
                Text(place.category)
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
            .clipShape(
                UnevenRoundedRectangle(
                    topLeadingRadius: 0,
                    bottomLeadingRadius: 18,
                    bottomTrailingRadius: 18,
                    topTrailingRadius: 0,
                    style: .continuous
                )
            )
        }
        .frame(width: 210)
        .background(Color(uiColor: .systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color(uiColor: .systemGray5).opacity(0.6), lineWidth: 0.8)
        )
        
    }
}

