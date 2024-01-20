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
        
        public func matches(for regex: String, in text: String) -> [String] {
            do {
                let regex = try NSRegularExpression(pattern: regex)
                let results = regex.matches(in: text, range: NSRange(text.startIndex..., in: text))
                return results.map {
                    String(text[Range($0.range, in: text)!])
                }
            } catch let error {
                print("invalid regex: \(error.localizedDescription)")
                return []
            }
        }

        var body: some View {
            if #available(iOS 15, *) {
                var result = Text("")
                elements.forEach { component in
                    // code
                    if component.attributes.contains(.code) {
                        result = result + code.makeBody(
                            configuration: .init(code: component.content, font: font)
                        )
                    } else if component.attributes.contains(.money) {
                        var attributedString = AttributedString("\(component.content)")
                        var container = AttributeContainer()
//                        container.font = .body
//                        container.backgroundColor = .systemFill
                        
                        if let tmp = matches(for: "[-]?[0-9]+[.]?[0-9]*", in: component.content).first {
                            let amount = (Decimal(string: tmp) ?? 0)
                            if amount > 0 {
                                attributedString.foregroundColor = .accentColor
                                container.underlineStyle = .init(pattern: .solid, color: .accentColor.opacity(0.1))
//                                container.underlineColor = .gray
//                                container.foregroundColor = .accentColor
                            } else {
                                attributedString.foregroundColor = .secondary
//                                container.inlinePresentationIntent = .strikethrough
                                container.underlineStyle = .init(pattern: .solid, color: .accentColor.opacity(0.1))
                                container.strikethroughStyle = .init(pattern: .solid, color: .secondary.opacity(0.2))
//                                container.underlineColor = .gray
//                                container.foregroundColor = .secondary
                            }
                        }
                        attributedString.setAttributes(container)
                        result = result + Text(attributedString).apply(
                            strong: strong,
                            emphasis: emphasis,
                            strikethrough: strikethrough,
                            link: link,
                            money: money,
                            attributes: component.attributes
                        )
                    } else {
                        result = result + Text(component.content).apply(
                            strong: strong,
                            emphasis: emphasis,
                            strikethrough: strikethrough,
                            link: link,
                            money: money,
                            attributes: component.attributes
                        )
                    }
                }
                return result
            } else {
                // Fallback on earlier versions
                return elements.reduce(into: Text("")) { result, component in
                    if component.attributes.contains(.code) {
                        return result = result + code.makeBody(
                            configuration: .init(code: component.content, font: font)
                        )
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
    }

    public let elements: [MarkdownInlineElement]

    public var label: some View {
        Label(elements: elements)
            .fixedSize(horizontal: false, vertical: true)
    }
}

struct InlineMarkdownStyle {
    func makeBody(configuration: InlineMarkdownConfiguration) -> some View {
        configuration.label
    }
}
