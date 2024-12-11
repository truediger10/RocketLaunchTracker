// ShareViewController.swift

import UIKit
import Social
import MobileCoreServices

class ShareViewController: SLComposeServiceViewController {

    override func isContentValid() -> Bool {
        // Validate the content - ensure there's something to share
        return !contentText.isEmpty || !attachments.isEmpty
    }

    override func didSelectPost() {
        // Handle the post action

        if let item = extensionContext?.inputItems.first as? NSExtensionItem {
            for attachment in item.attachments ?? [] {
                if attachment.hasItemConformingToTypeIdentifier(kUTTypeText as String) {
                    attachment.loadItem(forTypeIdentifier: kUTTypeText as String, options: nil) { (data, error) in
                        if let text = data as? String {
                            // Process the shared text
                            self.saveSharedText(text)
                        }
                        self.extensionContext?.completeRequest(returningItems: [], completionHandler: nil)
                    }
                }
                // Handle other content types (e.g., URLs, images) as needed
            }
        }
    }

    override func configurationItems() -> [Any]! {
        // Return any configuration options for the extension
        return []
    }

    private func saveSharedText(_ text: String) {
        // Implement saving the shared text to your app
        // Example: Save to a shared UserDefaults or a shared container
        let sharedDefaults = UserDefaults(suiteName: "group.com.yourcompany.RocketLaunchTracker")
        sharedDefaults?.set(text, forKey: "SharedLaunchDetails")
    }
}
