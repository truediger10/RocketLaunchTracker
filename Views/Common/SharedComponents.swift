//
//  SharedComponents.swift
//  RocketLaunchTracker
//
//  Created by Troy Ruediger on 11/25/24.
//

import Foundation
import SwiftUI

// MARK: - Launch Status Components
struct LaunchStatusTag: View {
    let status: LaunchStatus
    
    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(statusColor)
                .frame(width: 8, height: 8)
            Text(status.displayText)
                .font(.caption)
                .foregroundColor(ThemeColors.almostWhite)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(ThemeColors.darkGray.opacity(0.8))
        .cornerRadius(12)
    }
    
    private var statusColor: Color {
        switch status {
        case .successful:
            return ThemeColors.brightyellow
        case .upcoming:
            return .blue
        case .launching:
            return .green
        case .failed:
            return .red
        case .delayed:
            return .orange
        case .cancelled:
            return .gray
        }
    }
}

struct DetailItem: View {
    let title: String
    let icon: String
    let text: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(ThemeColors.brightyellow)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(ThemeColors.lightGray)
                Text(text)
                    .foregroundColor(ThemeColors.almostWhite)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

struct LaunchDetailRow: View {
    let label: String
    let value: String
    let icon: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(ThemeColors.brightyellow)
                .frame(width: 20)
            
            Text(value)
                .font(.subheadline)
                .foregroundColor(ThemeColors.lightGray)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
