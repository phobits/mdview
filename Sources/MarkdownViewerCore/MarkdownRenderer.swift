import Foundation
import cmark_gfm
import cmark_gfm_extensions

/// Markdown → HTML body via cmark-gfm: CommonMark plus the GitHub Flavored
/// Markdown extensions, i.e. the same parser GitHub renders `.md` files with.
///
/// Raw HTML is passed through (`CMARK_OPT_UNSAFE`) so documents keep working
/// `<details>`, `<br>` etc. That is safe here because safety never relies on
/// the parser: the page is rendered under a strict CSP with JavaScript off (see
/// `MarkdownPage.csp`). The `tagfilter` extension additionally neutralises
/// `<script>`, `<iframe>`, `<style>` and the like, as GitHub does.
enum MarkdownRenderer {
    private static let extensionNames = ["table", "strikethrough", "autolink", "tagfilter", "tasklist"]

    static func html(from markdown: String) -> String {
        cmark_gfm_core_extensions_ensure_registered()

        let options = CMARK_OPT_UNSAFE | CMARK_OPT_FOOTNOTES
        guard let parser = cmark_parser_new(options) else { return "" }
        defer { cmark_parser_free(parser) }

        for name in extensionNames {
            if let syntaxExtension = cmark_find_syntax_extension(name) {
                cmark_parser_attach_syntax_extension(parser, syntaxExtension)
            }
        }

        let utf8 = Array(markdown.utf8)
        utf8.withUnsafeBufferPointer { buffer in
            buffer.baseAddress?.withMemoryRebound(to: CChar.self, capacity: buffer.count) {
                cmark_parser_feed(parser, $0, buffer.count)
            }
        }

        guard let document = cmark_parser_finish(parser) else { return "" }
        defer { cmark_node_free(document) }

        guard let rendered = cmark_render_html(document, options, cmark_parser_get_syntax_extensions(parser)) else {
            return ""
        }
        defer { free(rendered) }
        return String(cString: rendered)
    }
}
