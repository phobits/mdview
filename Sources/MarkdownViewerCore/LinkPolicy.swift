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
    /// opaque `about:` URL even though the string has one. On macOS 15
    /// Foundation even percent-encodes that `#` (`about:blank%23fn-1`), so for
    /// `about:` URLs the first `%23` counts as the fragment marker.
    public static func staysInPage(_ url: URL, pageURL: URL?) -> Bool {
        var string = url.absoluteString
        if isAbout(url), !string.contains("#"), let marker = string.range(of: "%23") {
            string.replaceSubrange(marker, with: "#")
        }
        guard let link = URLComponents(string: string),
              let fragment = link.fragment, !fragment.isEmpty else { return false }
        if isAbout(url) { return link.path == "blank" }
        guard let pageURL, var page = URLComponents(string: pageURL.absoluteString) else { return false }
        var target = link
        target.fragment = nil
        page.fragment = nil
        return target.string == page.string
    }

    /// Whether a link that doesn't stay in the page may go to the default
    /// browser. Never for `about:` URLs: nothing handles them, and handing one
    /// to Launch Services pops a "no application to open" dialog. This holds
    /// even when `staysInPage` can't parse an anchor (Foundation's handling of
    /// opaque `about:` URLs differs between macOS versions).
    public static func opensExternally(_ url: URL) -> Bool {
        !isAbout(url)
    }

    private static func isAbout(_ url: URL) -> Bool {
        url.scheme?.lowercased() == "about"
    }
}
