import SwiftUI
import SafariServices

struct SafariView: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> SFSafariViewController {
        return SFSafariViewController(url: url)
    }

    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {
        // No need to update anything here
    }
};struct LaunchDetailView: View {
    let launch: Launch
    @Environment(\.dismiss) private var dismiss
    @State private var showSafariView = false
    @State private var safariURL: URL?
    @State private var showMissionDetails = true
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Hero Image Section with fixed aspect ratio
                AsyncImage(url: URL(string: launch.imageURL ?? "")) { phase in
                    switch phase {
                    case .empty:
                        ProgressView()
                            .frame(height: 200)
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(height: 200)
                            .clipped()
                            .transition(.opacity) // Fade-in effect
                            .animation(.easeIn(duration: 1.0), value: launch.imageURL)
                    case .failure(_):
                        Rectangle()
                            .fill(ThemeColors.darkGray)
                            .frame(height: 200)
                            .overlay {
                                Image(systemName: "rocket.fill")
                                    .foregroundColor(ThemeColors.lunarRock)
                                    .font(.system(size: 40))
                            }
                    @unknown default:
                        EmptyView()
                    }
                }
                
                // Content Section
                VStack(alignment: .leading, spacing: 20) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text(launch.name)
                            .font(.title2)
                            .foregroundColor(ThemeColors.almostWhite)
                            .fixedSize(horizontal: false, vertical: true) // Allow text wrapping
                        
                        Text(launch.provider)
                            .font(.subheadline)
                            .foregroundColor(ThemeColors.lightGray)
                    }
                    .padding(.horizontal)
                    
                    // Launch Info
                    VStack(alignment: .leading, spacing: 12) {
                        InfoRow(title: "Date", value: launch.formattedDate)
                        InfoRow(title: "Location", value: launch.location)
                        InfoRow(title: "Rocket", value: launch.rocketName)
                        if let orbit = launch.orbit {
                            InfoRow(title: "Orbit", value: orbit)
                        }
                    }
                    .padding(.horizontal, 12)

                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            showMissionDetails.toggle()
                        }
                    }) {
                        Text(showMissionDetails ? "Hide Mission Details" : "Show Mission Details")
                            .font(.headline)
                            .foregroundColor(ThemeColors.brightyellow)
                    }
                    .padding(.horizontal)

                    // Mission Details Section
                    if showMissionDetails {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Mission Details")
                                .font(.headline)
                                .foregroundColor(ThemeColors.almostWhite)

                            Text(launch.detailedDescription)
                                .foregroundColor(ThemeColors.lightGray)
                                .fixedSize(horizontal: false, vertical: true) // Allow text wrapping
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 12)
                        .background(ThemeColors.darkGray)
                        .cornerRadius(12)
                        .transition(.slide)
                    }
                    // Wiki Link if available
                    if let wikiURL = launch.wikiURL,
                                           let url = URL(string: wikiURL) {
                                            Button(action: {
                                                self.safariURL = url
                                                self.showSafariView = true
                                            }) {
                                                HStack {
                                                    Image(systemName: "book.fill")
                                                    Text("Learn More")
                                                }
                                                .font(.headline)
                                                .foregroundColor(ThemeColors.lunarRock)
                                                .frame(maxWidth: .infinity)
                                                .padding()
                                                .background(ThemeColors.brightyellow)
                                                .cornerRadius(12)
                                            }
                                            .padding(.horizontal)
                                            .sheet(isPresented: $showSafariView) {
                                                if let safariURL = safariURL {
                                                    SafariView(url: safariURL)
                                                }
                                            }
                                        }
                                    }
                                }
                                .background(ThemeColors.spaceBlack)
                                .ignoresSafeArea(.all, edges: .top)
                                .overlay(alignment: .topTrailing) {
                                    closeButton
                                        .padding()
                                }
                            }
                        }

    private var closeButton: some View {
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.title)
                    .foregroundColor(ThemeColors.darkGray.opacity(0.5))
                    .background(Circle().fill(ThemeColors.spaceBlack.opacity(0.5)))
            }
            .accessibilityLabel(Text("Close"))
        }

        struct InfoRow: View {
            let title: String
            let value: String

            var body: some View {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.caption)
                        .foregroundColor(ThemeColors.brightyellow)
                        .buttonStyle(PlainButtonStyle())
                        .contentShape(Rectangle())
                    Text(value)
                        .font(.body)
                        .foregroundColor(ThemeColors.almostWhite)
                        .fixedSize(horizontal: false, vertical: true) // Allow text wrapping
                }
            }
        }
    }
