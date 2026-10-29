import Foundation
import Testing
@testable import MarkdownViewerCore

// The preview is loaded with `loadHTMLString(_:baseURL: nil)`, so its own
// anchors (footnotes, `[x](#anchor)`) resolve to `about:blank#…`.

@Test func footnoteJumpStaysInThePage() {
    #expect(LinkPolicy.staysInPage(URL(string: "about:blank#fn-1")!, pageURL: URL(string: "about:blank")))
    #expect(LinkPolicy.staysInPage(URL(string: "about:blank#fnref-1")!, pageURL: URL(string: "about:blank#fn-1")))
}

@Test func inPageJumpIsRecognisedWithoutAPageURL() {
    #expect(LinkPolicy.staysInPage(URL(string: "about:blank#fn-1")!, pageURL: nil))
}

@Test func linksLeavingThePageOpenInTheBrowser() {
    let page = URL(string: "about:blank")
    #expect(!LinkPolicy.staysInPage(URL(string: "https://example.com")!, pageURL: page))
    #expect(!LinkPolicy.staysInPage(URL(string: "https://example.com/doc#section")!, pageURL: page))
    #expect(!LinkPolicy.staysInPage(URL(string: "mailto:someone@example.com")!, pageURL: page))
    #expect(!LinkPolicy.staysInPage(URL(string: "about:blank")!, pageURL: page))
}

@Test func footnoteJumpIsRecognisedOnTheURLWebKitDelivers() {
    // WebKit hands over a bridged NSURL; for an opaque `about:` URL its
    // `fragment` is nil although the string has one. This broke footnote clicks.
    let fromWebKit = NSURL(string: "about:blank#fn-1")! as URL
    #expect(LinkPolicy.staysInPage(fromWebKit, pageURL: NSURL(string: "about:blank")! as URL))
    #expect(LinkPolicy.staysInPage(NSURL(string: "about:blank#fnref-1")! as URL, pageURL: nil))
    #expect(!LinkPolicy.staysInPage(NSURL(string: "https://example.com/doc#section")! as URL, pageURL: NSURL(string: "about:blank")! as URL))
}

@Test func otherAboutPagesNeverNavigateThePreview() {
    // Only the page's own `about:blank` anchors stay in the page; an untrusted
    // document must not swap the preview for another about: page.
    #expect(!LinkPolicy.staysInPage(NSURL(string: "about:srcdoc#x")! as URL, pageURL: NSURL(string: "about:blank")! as URL))
    #expect(!LinkPolicy.staysInPage(URL(string: "about:foo#x")!, pageURL: nil))
}
