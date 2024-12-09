import SwiftUI
import SafariServices

/// A SwiftUI wrapper for SFSafariViewController
/// Provides in-app web browsing functionality
struct SafariView: UIViewControllerRepresentable {
    // MARK: - Properties
    let url: URL
    var configuration: SFSafariViewController.Configuration = {
        let config = SFSafariViewController.Configuration()
        config.entersReaderIfAvailable = false
        config.barCollapsingEnabled = true
        return config
    }()
    
    // MARK: - UIViewControllerRepresentable
    func makeUIViewController(context: Context) -> SFSafariViewController {
        let controller = SFSafariViewController(url: url, configuration: configuration)
        controller.preferredControlTintColor = UIColor(ThemeColors.brightyellow)
        controller.dismissButtonStyle = .close
        return controller
    }
    
    func updateUIViewController(_ controller: SFSafariViewController, context: Context) {}
}

// MARK: - Preview Provider
struct SafariView_Previews: PreviewProvider {
    static var previews: some View {
        SafariView(url: URL(string: "https://www.example.com")!)
            .ignoresSafeArea()
    }
}
