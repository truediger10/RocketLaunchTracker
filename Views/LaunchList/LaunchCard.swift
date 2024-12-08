import SwiftUI

struct LaunchCard: View {
    let launch: Launch
    
    @State private var hasAppeared = false
    @State private var imageLoaded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack(alignment: .topLeading) {
                AsyncImage(url: URL(string: launch.imageURL ?? "")) { phase in
                    switch phase {
                    case .empty:
                        loadingPlaceholder
                            .transition(.opacity.animation(.easeInOut(duration: 0.3)))
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(16/9, contentMode: .fill)
                            .onAppear {
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.7, blendDuration: 0)) {
                                    imageLoaded = true
                                }
                            }
                            .scaleEffect(imageLoaded ? 1.0 : 0.9)
                            .opacity(imageLoaded ? 1.0 : 0.0)
                            .transition(.opacity.animation(.easeInOut(duration: 0.3)))
                    case .failure:
                        errorPlaceholder
                            .transition(.opacity.animation(.easeInOut(duration: 0.3)))
                    @unknown default:
                        EmptyView()
                    }
                }
                .frame(height: 200)
                .clipped()
                .overlay(
                    LinearGradient(
                        colors: [
                            .black.opacity(0.4),
                            .clear,
                            .clear
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                
                // Provider overlay (bright yellow), similar to detail view
                VStack(alignment: .leading, spacing: 8) {
                    Text(launch.provider)
                        .font(.headline)
                        .foregroundColor(ThemeColors.brightyellow)
                    
                    LaunchStatusTag(status: launch.status)
                }
                .padding([.top, .leading], 16)
                .scaleEffect(hasAppeared ? 1.0 : 0.8)
                .opacity(hasAppeared ? 1.0 : 0.0)
                .animation(.easeInOut(duration: 0.4).delay(0.2), value: hasAppeared)
            }
            
            // Semi-transparent backdrop for readability
            ZStack(alignment: .topLeading) {
                ThemeColors.darkGray.opacity(0.4)
                    .cornerRadius(12)
                    .padding([.leading, .trailing], 16)
                    .padding(.top, 8)
                
                VStack(alignment: .leading, spacing: 16) {
                    // Title and Short Description
                    VStack(alignment: .leading, spacing: 8) {
                        Text(launch.name)
                            .font(.title2.bold())
                            .foregroundColor(ThemeColors.almostWhite)
                            .lineLimit(2)
                            .fixedSize(horizontal: false, vertical: true)
                            .multilineTextAlignment(.leading)
                        
                        Text(launch.shortDescription)
                            .font(.subheadline)
                            .foregroundColor(ThemeColors.lightGray)
                            .lineSpacing(2)
                            .multilineTextAlignment(.leading)
                            .lineLimit(2)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    
                    // Simplified Launch Details (Date and Location)
                    VStack(alignment: .leading, spacing: 12) {
                        LaunchDetailRow(label: "Launch Date", value: launch.formattedDate, icon: "calendar")
                        LaunchDetailRow(label: "Location", value: launch.location, icon: "mappin.and.ellipse")
                    }
                }
                .padding(16)
            }
        }
        .background(ThemeColors.darkGray)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 2)
        .scaleEffect(hasAppeared ? 1.0 : 0.98)
        .onAppear {
            withAnimation(.easeInOut(duration: 0.4)) {
                hasAppeared = true
            }
        }
    }
    
    // MARK: - Helper Views
    private var loadingPlaceholder: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [ThemeColors.darkGray, ThemeColors.midGray]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .opacity(0.8)
            
            VStack(spacing: 8) {
                ShimmerView()
                    .frame(width: 150, height: 20)
                Text("Loading...")
                    .font(.footnote)
                    .foregroundColor(ThemeColors.almostWhite.opacity(0.8))
            }
        }
    }
    
    private var errorPlaceholder: some View {
        Rectangle()
            .fill(ThemeColors.darkGray)
            .overlay {
                VStack {
                    Image(systemName: "exclamationmark.triangle")
                        .foregroundColor(ThemeColors.lunarRock)
                        .font(.system(size: 40))
                    Text("Image Unavailable")
                        .foregroundColor(ThemeColors.lightGray)
                        .font(.footnote)
                }
            }
    }
}
