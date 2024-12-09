import SwiftUI
import SafariServices
import WebKit

// MARK: - TweetButtonView

/// A UIViewRepresentable that displays a Twitter share button using WKWebView.
struct TweetButtonView: UIViewRepresentable {
    let url: URL
    let text: String
    let showCount: Bool

    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.isOpaque = false
        webView.backgroundColor = UIColor.clear

        let count = showCount ? "true" : "false"
        // Scale the tweet button using CSS transform: scale is set to 5 for better visibility
        let htmlString = """
        <!DOCTYPE html>
        <html>
        <head>
        <meta name="twitter:widgets:csp" content="on">
        <style>
            body {
                margin:0;
                padding:0;
                background:transparent;
                transform: scale(5);
                transform-origin: top left;
            }
        </style>
        </head>
        <body>
        <a href="https://twitter.com/share" class="twitter-share-button"
           data-text="\(text)"
           data-url="\(url.absoluteString)"
           data-show-count="\(count)">Share Launch</a>
        <script async src="https://platform.twitter.com/widgets.js" charset="utf-8"></script>
        </body>
        </html>
        """

        webView.loadHTMLString(htmlString, baseURL: nil)
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        // No dynamic updates needed for this view
    }
}

// MARK: - LaunchDetailView

/// A SwiftUI view that displays detailed information about a rocket launch.
struct LaunchDetailView: View {
    // MARK: - Constants
    private enum Constants {
        static let padding: CGFloat = 16
        static let spacing: CGFloat = 16
        static let imageAspectRatio: CGFloat = 0.75
        static let closeButtonSize: CGFloat = 16
        static let descriptionLineLimit = 2
        static let cornerRadius: CGFloat = 8
    }

    // MARK: - Properties
    let launch: Launch
    @Environment(\.dismiss) private var dismiss

    // MARK: - State
    @State private var showSafariView = false
    @State private var safariURL: URL?
    @State private var showFullMissionOverview = false
    @State private var imageLoaded = false

    // MARK: - Body
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                heroSection
                contentSection
            }
        }
        .background(ThemeColors.spaceBlack)
        .ignoresSafeArea(edges: .top)
        .overlay(alignment: .topTrailing) { closeButton }
        .sheet(isPresented: $showSafariView) {
            if let safariURL = safariURL {
                SafariView(url: safariURL)
            }
        }
    }

    // MARK: - Content Sections

    /// The main content section containing title, details, mission overview, and share buttons.
    private var contentSection: some View {
        VStack(alignment: .leading, spacing: Constants.spacing) {
            titleSection
            contentDivider

            detailsSection
            contentDivider

            missionOverviewSection

            if hasLearnMore {
                contentDivider
                learnMoreButton

                if let twitterURLString = launch.twitterURL,
                   let validTwitterURL = URL(string: twitterURLString) {
                    shareSection(url: validTwitterURL)
                }
            }
        }
        .padding(.horizontal, Constants.padding)
        .padding(.vertical, Constants.padding)
    }

    /// The hero section displaying the launch image with a gradient and overlay content.
    private var heroSection: some View {
        ZStack(alignment: .topLeading) {
            launchImage
            imageGradient
            heroOverlayContent
        }
    }

    /// Asynchronously loads and displays the launch image.
    private var launchImage: some View {
        GeometryReader { geometry in
            AsyncImage(url: URL(string: launch.imageURL ?? "")) { phase in
                switch phase {
                case .empty:
                    loadingPlaceholder
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .clipped()
                        .onAppear { imageLoaded = true }
                        .transition(.opacity)
                case .failure:
                    errorPlaceholder
                @unknown default:
                    EmptyView()
                }
            }
        }
        .frame(height: UIScreen.main.bounds.width * Constants.imageAspectRatio)
    }

    /// A gradient overlay for the launch image to enhance text readability.
    private var imageGradient: some View {
        LinearGradient(
            gradient: Gradient(colors: [
                .clear,
                ThemeColors.spaceBlack.opacity(0.3),
                ThemeColors.spaceBlack.opacity(0.6),
                ThemeColors.spaceBlack
            ]),
            startPoint: .top,
            endPoint: .bottom
        )
        .frame(height: UIScreen.main.bounds.width * Constants.imageAspectRatio)
    }

    /// Overlay content on the hero section, including provider, status tag, and time until launch.
    private var heroOverlayContent: some View {
        VStack(alignment: .leading) {
            Text(launch.provider)
                .font(.headline)
                .foregroundColor(ThemeColors.brightyellow)
                .lineLimit(2)
                .padding([.leading, .top], Constants.padding)

            LaunchStatusTag(status: launch.status)
                .padding(.leading, Constants.padding)

            Spacer()

            Text(launch.timeUntilLaunch)
                .font(.subheadline)
                .foregroundColor(ThemeColors.almostWhite)
                .padding([.leading, .bottom], Constants.padding)
        }
    }

    /// The title section displaying the launch name.
    private var titleSection: some View {
        Text(launch.name)
            .font(.title2.bold())
            .foregroundColor(ThemeColors.almostWhite)
            .fixedSize(horizontal: false, vertical: true)
    }

    /// The details section displaying various launch details.
    private var detailsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            DetailItem(label: "Launch Date", value: launch.formattedDate, icon: "calendar")
            DetailItem(label: "Location", value: launch.location, icon: "mappin.and.ellipse")
            DetailItem(label: "Rocket", value: launch.rocketName, icon: "airplane")
            if let orbit = launch.orbit {
                DetailItem(label: "Orbit", value: orbit, icon: "circle.dashed")
            }
            DetailItem(label: "Time Until Launch", value: launch.timeUntilLaunch, icon: "clock")
        }
    }

    /// The mission overview section with expandable text.
    private var missionOverviewSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            missionOverviewHeader

            Text(launch.detailedDescription)
                .foregroundColor(ThemeColors.lightGray)
                .fixedSize(horizontal: false, vertical: true)
                .lineLimit(showFullMissionOverview ? nil : Constants.descriptionLineLimit)
                .animation(.easeInOut, value: showFullMissionOverview)
        }
    }

    /// The header for the mission overview section, including a toggle button.
    private var missionOverviewHeader: some View {
        HStack {
            Text("Mission Overview")
                .font(.headline)
                .foregroundColor(ThemeColors.almostWhite)

            Spacer()

            Button {
                withAnimation(.easeInOut) {
                    showFullMissionOverview.toggle()
                }
            } label: {
                HStack(spacing: 4) {
                    Text(showFullMissionOverview ? "Show Less" : "Show More")
                        .font(.caption)
                    Image(systemName: showFullMissionOverview ? "chevron.up" : "chevron.down")
                        .font(.caption)
                }
                .foregroundColor(ThemeColors.brightyellow)
            }
        }
    }

    /// A divider used between content sections.
    private var contentDivider: some View {
        Divider()
            .background(ThemeColors.darkGray.opacity(0.6))
    }

    /// The learn more button that opens a Safari view with the provided wiki URL.
    private var learnMoreButton: some View {
        Group {
            if let wikiURL = launch.wikiURL, let url = URL(string: wikiURL) {
                Button {
                    safariURL = url
                    showSafariView = true
                } label: {
                    HStack {
                        Image(systemName: "book.fill")
                            .font(.caption)
                        Text("Learn More")
                            .font(.caption)
                    }
                    .padding(8)
                    .frame(maxWidth: .infinity)
                    .background(ThemeColors.brightyellow)
                    .foregroundColor(ThemeColors.spaceBlack)
                    .cornerRadius(Constants.cornerRadius)
                }
            }
        }
    }

    /// The share section containing the Tweet button.
    @ViewBuilder
    private func shareSection(url: URL) -> some View {
        TweetButtonView(
            url: url,
            text: "Check out this launch!",
            showCount: false
        )
        .frame(height: 120)
        .padding(.top, 8)
    }

    /// The close button to dismiss the view.
    private var closeButton: some View {
        Button {
            dismiss()
        } label: {
            Image(systemName: "xmark")
                .font(.system(size: Constants.closeButtonSize, weight: .bold))
                .foregroundColor(ThemeColors.almostWhite)
                .padding(8)
                .background(Circle().fill(ThemeColors.darkGray.opacity(0.8)))
                .padding()
        }
    }

    /// Placeholder view displayed while the launch image is loading.
    private var loadingPlaceholder: some View {
        Rectangle()
            .fill(ThemeColors.darkGray)
            .overlay {
                ProgressView()
                    .tint(ThemeColors.brightyellow)
            }
            .aspectRatio(4/3, contentMode: .fill)
    }

    /// Placeholder view displayed if the launch image fails to load.
    private var errorPlaceholder: some View {
        Rectangle()
            .fill(ThemeColors.darkGray)
            .overlay {
                Image(systemName: "rocket.fill")
                    .foregroundColor(ThemeColors.lunarRock)
                    .font(.system(size: 60))
            }
            .aspectRatio(4/3, contentMode: .fill)
    }

    /// Determines whether the learn more section should be displayed.
    private var hasLearnMore: Bool {
        guard let wikiURL = launch.wikiURL,
              URL(string: wikiURL) != nil else {
            return false
        }
        return true
    }
}

