import Testing
@testable import MarkdownViewerCore

// Rendering behaviour the parser must get right (CommonMark + GitHub Flavored
// Markdown). Each case broke real documents under the previous parser (Ink).

private func render(_ markdown: String) -> String {
    MarkdownPage.html(from: markdown)
}

// MARK: Code spans

@Test func codeSpanMayContinueAcrossALineBreak() {
    let html = render("text `cmd <staging> --list\n<liste>` more")
    #expect(html.contains("<code>cmd &lt;staging&gt; --list &lt;liste&gt;</code>"))
}

@Test func codeSpanNeverCrossesABlankLine() {
    let html = render("a `b\n\nc` d")
    #expect(!html.contains("<code>"))
}

@Test func unmatchedBacktickRunStaysLiteral() {
    let html = render("einen ```-Codefence zerteilen: x\ndahinter, matcht `FENCED_CODE` nicht")
    #expect(html.contains("einen ```-Codefence"))
    #expect(html.contains("<code>FENCED_CODE</code>"))
    #expect(!html.contains("<code></code>"))
}

@Test func doubleBacktickSpanMayContainABacktick() {
    #expect(render("a ``b ` c`` d").contains("<code>b ` c</code>"))
}

// MARK: Raw HTML

@Test func unclosedInlineTagDoesNotSwallowFollowingBlocks() {
    let html = render("text <foo> more\n\n| C | D |\n|---|---|\n| 1 | 2 |\n\n# Next")
    #expect(html.contains("<table>"))
    #expect(html.contains("<h1>Next</h1>"))
}

@Test func lessThanBeforeADigitIsText() {
    let html = render("| a | b |\n|---|---|\n| created (<90d freshness) | x |\n\n> quote")
    #expect(html.contains("<td>created (&lt;90d freshness)</td>"))
    #expect(html.contains("<blockquote>"))
}

@Test func markdownInsideDetailsBlockIsRendered() {
    let html = render("<details>\n<summary>URLs</summary>\n\n| URL | vorher |\n|---|---|\n| `/a` | 200 |\n\n</details>")
    #expect(html.contains("<summary>URLs</summary>"))
    #expect(html.contains("<td><code>/a</code></td>"))
}

@Test func preBlockKeepsItsContentVerbatim() {
    let html = render("<pre>\nline 1\n\n*line 2*\n</pre>")
    #expect(html.contains("*line 2*"))
    #expect(!html.contains("<em>"))
}

// MARK: Block structure

@Test func fencedCodeBlockInsideAListItem() {
    let html = render("1. Install:\n\n   ```bash\n   npm install\n   ```\n2. Run")
    #expect(html.contains("<pre><code class=\"language-bash\">npm install\n</code></pre>"))
    #expect(!html.contains("```"))
}

@Test func tableInsideAListItem() {
    let html = render("- Liste mit Tabelle:\n\n  | X | Y |\n  |---|---|\n  | 1 | 2 |")
    #expect(html.contains("<li>"))
    #expect(html.contains("<td>1</td>"))
    #expect(html.components(separatedBy: "<table>").count - 1 == 1)
    #expect(!html.contains("---"))
}

@Test func blockquoteMayDirectlyFollowAParagraphLine() {
    let html = render("decision:\n> **The gates** are designed")
    #expect(html.contains("<blockquote>"))
    #expect(html.contains("<strong>The gates</strong>"))
    #expect(!html.contains("&gt;"))
}

// MARK: Emphasis

@Test func intrawordUnderscoresAreNotEmphasis() {
    let html = render("body.expected_behavior_checkboxes and company_name, portal_url")
    #expect(html.contains("expected_behavior_checkboxes"))
    #expect(html.contains("company_name, portal_url"))
    #expect(!html.contains("<em>"))
}

// MARK: GitHub Flavored Markdown

@Test func rendersStrikethroughTaskListsAndAutolinks() {
    let html = render("~~old~~\n\n- [x] done\n- [ ] open\n\nsee https://example.com")
    #expect(html.contains("<del>old</del>"))
    #expect(html.contains("type=\"checkbox\""))
    #expect(html.contains("<a href=\"https://example.com\">https://example.com</a>"))
}

@Test func dangerousRawTagsAreFiltered() {
    // GFM tagfilter: even with JavaScript off and a strict CSP, script-like
    // tags are neutralised in the parser output too (defence in depth).
    let html = render("<script>alert(1)</script>\n\n<iframe src=\"x\"></iframe>")
    #expect(!html.contains("<script>"))
    #expect(!html.contains("<iframe"))
}

@Test func rendersFootnotesWithInPageLinks() {
    let html = render("Text[^1].\n\n[^1]: The note.")
    #expect(html.contains("<section class=\"footnotes\" data-footnotes>"))
    #expect(html.contains("href=\"#fn-1\""))
}

@Test func taskListItemsAndFootnotesAreStyled() {
    let css = MarkdownPage.css
    // A checkbox item shows the checkbox instead of a bullet.
    #expect(css.contains("li:has(> input[type=\"checkbox\"]:first-child) { list-style: none; }"))
    #expect(css.contains(".footnotes {"))
}
