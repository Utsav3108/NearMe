//
//  PlaceImage.swift
//  NearMe
//
//  Created by Utsav Hitendrabhai Pandya on 05/10/26.
//


import SwiftUI

struct PlaceImage: View {
    let photo: PlacePhoto?

    @State private var image: UIImage?
    @State private var isLoading = false
    @State private var hasFailed = false

    var body: some View {
        Group {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else if isLoading {
                loadingView
            } else if hasFailed {
                errorView
            } else {
                placeholderView
            }
        }
        .task(id: photo?.resourceName) {
            await loadImage()
        }
    }

    private var loadingView: some View {
        ProgressView()
    }

    private var errorView: some View {
        Image(systemName: "photo")
            .font(.title2)
            .foregroundStyle(.secondary)
    }

    private var placeholderView: some View {
        Color.secondary.opacity(0.1)
    }

    private func loadImage() async {
        guard let photo else {
            hasFailed = true
            return
        }

        isLoading = true
        hasFailed = false

        defer {
            isLoading = false
        }

        do {
            let data = try await PlacePhotoLoader.shared.imageData(for: photo)

            guard !Task.isCancelled else {
                return
            }

            guard let image = UIImage(data: data) else {
                hasFailed = true
                return
            }

            self.image = image
        } catch is CancellationError {
            // Task cancellation is not a loading failure.
        } catch {
            guard !Task.isCancelled else {
                return
            }

            hasFailed = true
        }
    }
}
