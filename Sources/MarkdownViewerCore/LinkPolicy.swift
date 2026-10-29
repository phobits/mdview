import Foundation

/// Decides what a clicked link in the preview does.
public enum LinkPolicy {
    /// Whether `url` only jumps to an anchor in the rendered page itself (a
    /// footnote, `[x](#anchor)`), which the preview handles by scrolling.
    /// Every other link opens in the default browser.
    ///
    /// The preview is loaded without a base URL, so its anchors resolve to
    /// `about:blank#…`. Fragment and comparison are read from the URL *string*:
    /// WebKit hands over a bridged `NSURL`, whose `fragment` is nil for an
    /// opaque `about:` URL even though the string has one.
    public static func staysInPage(_ url: URL, pageURL: URL?) -> Bool {
        guard let link = URLComponents(string: url.absoluteString),
              let fragment = link.fragment, !fragment.isEmpty else { return false }
        if link.scheme == "about" { return link.path == "blank" }
        guard let pageURL, var page = URLComponents(string: pageURL.absoluteString) else { return false }
        var target = link
        target.fragment = nil
        page.fragment = nil
        return target.string == page.string
    }
}
