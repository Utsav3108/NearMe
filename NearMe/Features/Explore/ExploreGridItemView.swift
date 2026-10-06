//
//  ExploreGridItemView.swift
//  NearMe
//
//  Created by Utsav Hitendrabhai Pandya on 06/10/26.
//

import SwiftUI

/// An Instagram Explore-style tile displaying full-bleed imagery and minimal attribution.
///
/// **Design:**
/// - Edge-to-edge photo filling the exact frame specified by the layout grid.
/// - In compliance with Google Places API policies, author attribution is clearly visible
///   at the bottom of each tile with a delicate gradient backing.
/// - Tactile loading feedback when the venue details are being fetched for presentation mode.
struct ExploreGridItemView: View {

    let item: ExploreItem
    let isLoadingDetail: Bool
    let width: CGFloat
    let height: CGFloat
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            ZStack(alignment: .bottomLeading) {
                // Background placeholder
                Color(uiColor: .secondarySystemBackground)

                // Main venue image
                PlaceImage(photo: item.photo)
                    .frame(width: width, height: height)
                    .clipped()

                // Subtle bottom vignette for text contrast
                LinearGradient(
                    colors: [
                        .clear,
                        .black.opacity(0.12),
                        .black.opacity(0.65)
                    ],
                    startPoint: .center,
                    endPoint: .bottom
                )
                .frame(width: width, height: height)
                .allowsHitTesting(false)

                // Mandatory Google Places photo attribution badge
                if let attribution = item.attribution {
                    HStack(spacing: 3) {
                        Image(systemName: "camera.fill")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundStyle(.white.opacity(0.9))

                        Text(attribution.displayName)
                            .font(.system(size: 9.5, weight: .semibold))
                            .foregroundStyle(.white)
                            .lineLimit(1)
                            .shadow(color: .black.opacity(0.6), radius: 2, x: 0, y: 1)
                    }
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3.5)
                    .background(
                        Capsule()
                            .fill(.black.opacity(0.35))
                    )
                    .padding(6)
                }

                // Loading feedback spinner upon tap
                if isLoadingDetail {
                    ZStack {
                        Color.black.opacity(0.40)
                        ProgressView()
                            .tint(.white)
                    }
                    .frame(width: width, height: height)
                    .transition(.opacity)
                }
            }
            .frame(width: width, height: height)
            .clipped()
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
