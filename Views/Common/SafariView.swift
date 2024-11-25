//
//  SafariView.swift
//  RocketLaunchTracker
//
//  Created by Troy Ruediger on 11/25/24.
//

import Foundation
import SwiftUI
import SafariServices

struct SafariView: UIViewControllerRepresentable {
    let url: URL
    
    func makeUIViewController(context: Context) -> SFSafariViewController {
        return SFSafariViewController(url: url)
    }
    
    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {}
}
