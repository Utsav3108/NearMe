//
//  InstagramExploreGrid.swift
//  NearMe
//
//  Created by Utsav Hitendrabhai Pandya on 07/10/26.
//

import SwiftUI

/// An Instagram Explore-style mosaic grid displaying alternating 2x2 featured tiles
/// and 1x1 standard tiles across 3 columns with tight 2pt spacing.
struct InstagramExploreGrid: View {

    let items: [ExploreItem]
    let totalWidth: CGFloat
    let loadingItemId: String?
    let onSelect: (ExploreItem) -> Void

    private let spacing: CGFloat = 2

    private var smallSize: CGFloat {
        max(1, (totalWidth - 2 * spacing) / 3)
    }

    private var largeSize: CGFloat {
        2 * smallSize + spacing
    }

    private var blocks: [[ExploreItem]] {
        stride(from: 0, to: items.count, by: 6).map { startIndex in
            let endIndex = min(startIndex + 6, items.count)
            return Array(items[startIndex..<endIndex])
        }
    }

    var body: some View {
        LazyVStack(spacing: spacing) {
            ForEach(Array(blocks.enumerated()), id: \.offset) { blockIndex, block in
                renderBlock(block, isEven: blockIndex % 2 == 0)
            }
        }
    }

    // MARK: - Block Rendering

    @ViewBuilder
    private func renderBlock(_ block: [ExploreItem], isEven: Bool) -> some View {
        if block.count >= 6 {
            if isEven {
                compositeRowLeftLarge(first: block[0], second: block[1], third: block[2])
                threeColumnRow(items: Array(block[3..<6]))
            } else {
                compositeRowRightLarge(first: block[0], second: block[1], third: block[2])
                threeColumnRow(items: Array(block[3..<6]))
            }
        } else if block.count >= 3 {
            if isEven {
                compositeRowLeftLarge(first: block[0], second: block[1], third: block[2])
            } else {
                compositeRowRightLarge(first: block[0], second: block[1], third: block[2])
            }
            if block.count > 3 {
                threeColumnRow(items: Array(block[3..<block.count]))
            }
        } else {
            HStack(spacing: spacing) {
                ForEach(block) { item in
                    cell(item, width: smallSize, height: smallSize)
                }
                Spacer(minLength: 0)
            }
        }
    }

    // Pattern A: Large tile on LEFT, 2 stacked small tiles on RIGHT
    private func compositeRowLeftLarge(first: ExploreItem, second: ExploreItem, third: ExploreItem) -> some View {
        HStack(spacing: spacing) {
            cell(first, width: largeSize, height: largeSize)

            VStack(spacing: spacing) {
                cell(second, width: smallSize, height: smallSize)
                cell(third, width: smallSize, height: smallSize)
            }
        }
    }

    // Pattern B: 2 stacked small tiles on LEFT, Large tile on RIGHT
    private func compositeRowRightLarge(first: ExploreItem, second: ExploreItem, third: ExploreItem) -> some View {
        HStack(spacing: spacing) {
            VStack(spacing: spacing) {
                cell(first, width: smallSize, height: smallSize)
                cell(second, width: smallSize, height: smallSize)
            }

            cell(third, width: largeSize, height: largeSize)
        }
    }

    // Standard 3-column row
    private func threeColumnRow(items: [ExploreItem]) -> some View {
        HStack(spacing: spacing) {
            ForEach(items) { item in
                cell(item, width: smallSize, height: smallSize)
            }
            if items.count < 3 {
                Spacer(minLength: 0)
            }
        }
    }

    private func cell(_ item: ExploreItem, width: CGFloat, height: CGFloat) -> some View {
        ExploreGridItemView(
            item: item,
            isLoadingDetail: loadingItemId == item.id,
            width: width,
            height: height,
            onTap: { onSelect(item) }
        )
    }
}
