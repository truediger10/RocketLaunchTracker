//
//  LaunchCard.swift
//  RocketLaunchTracker
//

import SwiftUI

struct LaunchCard: View {
    let launch: Launch
    
    @State private var showShareSheet = false
    @State private var imageLoaded = false

    private enum Constants {
        static let imageHeight: CGFloat = 160
        static let cornerRadius: CGFloat = 16
        static let padding: CGFloat = 12
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            imageSection
            contentSection
        }
        .background(ThemeColors.spaceBlack)
        .cornerRadius(Constants.cornerRadius)
        .shadow(color: ThemeColors.darkGray.opacity(0.6), radius: 4, x: 0, y: 2)
        .padding(.horizontal, Constants.padding)
        .sheet(isPresented: $showShareSheet) {
            ShareSheet(activityItems: shareContent)
        }
    }

    private var imageSection: some View {
        ZStack(alignment: .topTrailing) {
            LaunchImageView(imageURL: launch.imageURL, height: Constants.imageHeight) {
                withAnimation(.easeOut(duration: 0.3)) {
                    imageLoaded = true
                }
            }
            // Share button in the top right corner
            Button(action: { showShareSheet = true }) {
                Image(systemName: "square.and.arrow.up")
                    .foregroundColor(.white)
                    .padding(8)
                    .background(ThemeColors.darkGray.opacity(0.7))
                    .clipShape(Circle())
            }
            .padding(Constants.padding)
        }
    }

    private var contentSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(launch.name)
                .font(.headline)
                .foregroundColor(ThemeColors.almostWhite)
                .lineLimit(2)
            
            Text(launch.provider)
                .font(.subheadline)
                .foregroundColor(ThemeColors.brightYellow)
            
            LaunchStatusTag(status: launch.status)
            
            HStack(spacing: 16) {
                DetailItem(label: "Date", value: launch.formattedDate, icon: "calendar")
                DetailItem(label: "Location", value: launch.location, icon: "mappin.and.ellipse")
            }
            
            Text("Time: \(launch.timeUntilLaunch)")
                .font(.footnote)
                .foregroundColor(ThemeColors.lightGray)
        }
        .padding(Constants.padding)
    }

    private var shareContent: [Any] {
        var items: [Any] = [
            "\(launch.name)\nDate: \(launch.formattedDate)\nProvider: \(launch.provider)"
        ]
        if let urlString = launch.imageURL, let url = URL(string: urlString) {
            items.append(url)
        }
        return items
    }
}
