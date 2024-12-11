// Views/Common/TweetButtonView.swift

import SwiftUI

struct TweetButtonView: View {
    let text: String
    let url: URL?
    let hashtags: String?
    let via: String?
    
    var body: some View {
        Button(action: {
            shareOnTwitter()
        }) {
            HStack {
                Image("TwitterBird") // Ensure this matches the name in Assets
                    .resizable()
                    .frame(width: 20, height: 16)
                
                Text("Tweet")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color(red: 29/255, green: 161/255, blue: 242/255)) // Twitter Blue
            .cornerRadius(25)
        }
        .accessibilityLabel("Share on Twitter")
    }
    
    private func shareOnTwitter() {
        var tweetText = text
        if let url = url {
            tweetText += " \(url.absoluteString)"
        }
        
        // Encode the tweet text to ensure it's URL-safe
        guard let tweetEncoded = tweetText.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            return
        }
        
        // Construct the Twitter intent URL
        var twitterURLString = "https://twitter.com/intent/tweet?text=\(tweetEncoded)"
        
        if let hashtags = hashtags {
            twitterURLString += "&hashtags=\(hashtags)"
        }
        
        if let via = via {
            twitterURLString += "&via=\(via)"
        }
        
        if let twitterURL = URL(string: twitterURLString) {
            UIApplication.shared.open(twitterURL, options: [:], completionHandler: nil)
        }
    }
}

struct TweetButtonView_Previews: PreviewProvider {
    static var previews: some View {
        TweetButtonView(
            text: "Check out this amazing rocket launch!",
            url: URL(string: "https://example.com/launch"),
            hashtags: "RocketLaunch,Space",
            via: "YourTwitterHandle" // Replace with your actual Twitter handle
        )
        .padding()
        .previewLayout(.sizeThatFits)
    }
}
