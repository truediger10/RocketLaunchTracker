import SwiftUI
import SafariServices
import WebKit

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
