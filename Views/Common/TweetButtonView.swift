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
                Image(systemName: "bird.fill")
                    .resizable()
                    .frame(width: 20, height: 16)
                    .foregroundColor(.white)
                
                Text("Tweet")
                    .font(.headline)
                    .foregroundColor(.white)
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.blue)
            .cornerRadius(8)
        }
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
            UIApplication.shared.open(twitterURL)
        }
    }
}

struct TweetButtonView_Previews: PreviewProvider {
    static var previews: some View {
        TweetButtonView(
            text: "Check out this amazing rocket launch!",
            url: URL(string: "https://example.com/launch"),
            hashtags: "RocketLaunch,Space",
            via: "YourTwitterHandle"
        )
        .padding()
        .previewLayout(.sizeThatFits)
    }
}
