//
//  CategorySelector.swift
//  NearMe
//
//  Created by Utsav Hitendrabhai Pandya on 01/10/26.
//
import SwiftUI
import Foundation

struct CategorySelector: View {

    let categories: [CategoryItem]
    @Binding var selectedCategory: String

    var appOrange: Color = .orange

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 14) {

                ForEach(categories, id: \.name) { category in

                    let isSelected = selectedCategory == category.name

                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedCategory = category.name
                        }
                    } label: {

                        VStack(spacing: 8) {

                            Image(systemName: category.icon)
                                .font(
                                    .system(
                                        size: 19,
                                        weight: isSelected ? .semibold : .regular
                                    )
                                )
                                .foregroundStyle(
                                    isSelected
                                    ? .white
                                    : .primary.opacity(0.85)
                                )

                            Text(category.name)
                                .font(
                                    .system(
                                        size: 11,
                                        weight: isSelected ? .semibold : .medium
                                    )
                                )
                                .foregroundStyle(
                                    isSelected
                                    ? .white
                                    : .secondary
                                )
                        }
                        .frame(width: 64, height: 72)
                        .background(
                            RoundedRectangle(
                                cornerRadius: 16,
                                style: .continuous
                            )
                            .fill(
                                isSelected
                                ? appOrange
                                : Color(uiColor: .systemBackground)
                            )
                            
                        )
                        
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 4)
        }
    }
}
