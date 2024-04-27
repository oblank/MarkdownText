import SwiftUI

public struct InlineMarkdownConfiguration {
    struct Label: View {
        @Environment(\.font) private var font
        @Environment(\.markdownStrongStyle) private var strong
        @Environment(\.markdownEmphasisStyle) private var emphasis
        @Environment(\.markdownStrikethroughStyle) private var strikethrough
        @Environment(\.markdownInlineCodeStyle) private var code
        @Environment(\.markdownInlineLinkStyle) private var link
        @Environment(\.markdownMoneyStyle) private var money

        let elements: [MarkdownInlineElement]

        var body: some View {
            elements.reduce(into: Text("")) { result, component in
                if component.attributes.contains(.code) {
                    return result = result + code.makeBody(
                        configuration: .init(code: component.content, font: font)
                    )
                } else if component.attributes.contains(.indent) {
                    // 自定义首页缩进，参考 https://cloud.tencent.com/developer/article/1616968
                    result = result + Text(.init(component.content))
                } else {
                    return result = result + Text(component.content).apply(
                        strong: strong,
                        emphasis: emphasis,
                        strikethrough: strikethrough,
                        link: link, 
                        money: money,
                        attributes: component.attributes
                    )
                }
            }
        }
    }

    public let elements: [MarkdownInlineElement]

    public var label: some View {
        Label(elements: elements)
            .fixedSize(horizontal: false, vertical: true)
    }
    
    // TODO 返原回原始内容，但不精准
    public var content: String {
        var result = ""
        for component in elements {
            result += component.content
        }
        return result
    }
    
    // TODO 返原回原始内容，但不精准，md样式的先后顺序不对
    public var contentOrigin: String {
        var result = ""
        for component in elements {
            let attributes = component.attributes
            var tmp = component.content
            if attributes.contains(.code) {
                tmp = "`\(tmp)`"
            }
            if attributes.contains(.bold) {
                tmp = "**\(tmp)**"
            }
            if attributes.contains(.strikethrough) {
                tmp = "~~\(tmp)~~"
            }
            if attributes.contains(.italic) {
                tmp = "*\(tmp)*"
            }
            if attributes.contains(.link) {
                tmp = "[](\(tmp)"
            }
            result += tmp
        }
        return result
    }
    
    public var contentOriginRegex: String {
        var result = ""
        for component in elements {
            let attributes = component.attributes
            var tmp = component.content
            var styles: [String] = []
            if attributes.contains(.code) {
                let symbol = "\\`"
                if !styles.contains(symbol) {
                    styles.append(symbol)
                }
            }
            if attributes.contains(.bold) {
                let symbol = "\\*\\*"
                if !styles.contains(symbol) {
                    styles.append(symbol)
                }
            }
            if attributes.contains(.strikethrough) {
                let symbol = "\\~\\~"
                if !styles.contains(symbol) {
                    styles.append(symbol)
                }
            }
            if attributes.contains(.italic) {
                let symbol = "\\*"
                if !styles.contains(symbol) {
                    styles.append(symbol)
                }
            }
            if attributes.contains(.link) {
                tmp = "\\(\(tmp)\\)"
            }
            
            tmp = tmp.replacingOccurrences(of: "\n", with: "(.*)?")
            if styles.isEmpty {
                result += tmp
            } else {
                result += "([\(styles.joined())]+)\(tmp)([\(styles.joined())]+)"
            }
        }
        return result
    }
}

struct InlineMarkdownStyle {
    func makeBody(configuration: InlineMarkdownConfiguration) -> some View {
        configuration.label
    }
}
