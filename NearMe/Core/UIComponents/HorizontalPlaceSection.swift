//
//  HorizontalPlaceSection.swift
//  NearMe
//
//  Created by Utsav Hitendrabhai Pandya on 01/10/26.
//
import SwiftUI

struct HorizontalPlaceSection<Content: View>: View {

    let title: String
    let actionTitle: String?
    let action: ((String) -> Void)?
    let content: () -> Content

    var appOrange: Color = .orange

    init(
        title: String,
        actionTitle: String? = nil,
        action: ((String) -> Void)? = nil,
        appOrange: Color = .orange,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.title = title
        self.actionTitle = actionTitle
        self.action = action
        self.appOrange = appOrange
        self.content = content
    }

    var body: some View {

        VStack(spacing: 4) {

            // MARK: - Header
            HStack {

                Text(title)
                    .font(.title3.bold())
                    .foregroundStyle(.primary)

                Spacer()

                if let actionTitle {
                    Button {
                        action?("")
                    } label: {
                        Text(actionTitle)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(appOrange)
                    }
                }
            }
            .padding(.horizontal, 20)

            // MARK: - Content
            ScrollView(.horizontal, showsIndicators: false) {

                HStack(spacing: 16) {
                    content()
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 4)
            }
        }
    }
}

