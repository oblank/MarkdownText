import SwiftUI
import Markdown
import Foundation

struct MarkdownTextBuilder: MarkupWalker {
    var isNested: Bool = false
    var nestedBlockElements: [MarkdownBlockElement] = []
    var inlineElements: [MarkdownInlineElement] = []
    var blockElements: [MarkdownBlockElement] = []
    var lists: [MarkdownList] = []
    var indent: Int = 0
    private var moneyList: MarkdownList? = nil
    private var lastIsMoneyItem: Bool = false

    // indent 缩进字符数
    init(document: Document, indent: Int = 0) {
        self.indent = indent
        visit(document)
    }

    mutating func visitHeading(_ markdown: Heading) {
        descendInto(markdown)
        blockElements.append(.heading(.init(level: markdown.level, content: .init(elements: inlineElements))))
        inlineElements = []
    }
    
    private func isMoneyMarkdown(_ text: String) -> Bool {
        do {
//            let FEE_PREFIX_REGEX = "^[$￥¥€£؋₩₱₾Т៛С̲৳₮ரூ₫₤₽₴Kƒ₲₦₵฿ΞŁÐ]*\\. "
            let FEE_PREFIX_REGEX = "[$￥¥€£؋₩₱₾Т៛С̲৳₮ரூ₫₤₽₴Kƒ₲₦₵฿ΞŁÐ]{1}[-0-9.]{1,}"
            let regex = try NSRegularExpression(pattern: FEE_PREFIX_REGEX)
            let results = regex.matches(in: text, range: NSRange(text.startIndex..., in: text))
            if !results.isEmpty {
                return true
            }
        } catch let error {
            print("invalid regex: \(error.localizedDescription)")
        }
        return false
    }
    
    enum TextType {
        case FEE
        case String
    }
    
    struct Split {
        var text: String
        var type: TextType
    }
    
    public func extractText(for pattern: String, in inputString: String) -> [Split] {
        do {
            let regex = try NSRegularExpression(pattern: pattern, options: [])
            let matches = regex.matches(in: inputString, options: [], range: NSRange(location: 0, length: inputString.utf16.count))
            var startIndex = inputString.startIndex

            var ret: [Split] = []
            for match in matches {
                let range = Range(match.range, in: inputString)!
                let substring = inputString[startIndex..<range.lowerBound]
                let matchedPattern = String(inputString[range])
                startIndex = range.upperBound
                ret.append(Split(text: String(substring), type: .String))
                ret.append(Split(text: String(matchedPattern), type: .FEE))
            }

            // 处理最后一个匹配之后的部分
            if startIndex < inputString.endIndex {
                let substring = inputString[startIndex..<inputString.endIndex]
                ret.append(Split(text: String(substring), type: .String))
            }
            return ret
        } catch {
            print("Error with regular expression: \(error)")
            return [Split(text: inputString, type: .String)]
        }
    }


    mutating func visitText(_ markdown: Markdown.Text) {
        var attributes: InlineAttributes = []
        var parent = markdown.parent
        var text = markdown.string
    
        while parent != nil {
            defer { parent = parent?.parent }

            if parent is Strong {
                attributes.insert(.bold)
            }

            if parent is Emphasis {
                attributes.insert(.italic)
            }

            if parent is Strikethrough {
                attributes.insert(.strikethrough)
            }

            if parent is InlineCode {
                attributes.insert(.code)
            }

            if let link = parent as? Markdown.Link {
                /*
                 One idea here could be to collect links like footnotes, reference them in the rendered result as such (at least by default) and then add actual buttons to the bottom of the rendered output?
                 */
                attributes.insert(.link)
                text = link.plainText // + (link.destination.flatMap { " [\($0)]" } ?? "")
            }
        }

        // ------------------增加记账格式 text start--------------------------
        let FEE_PREFIX_REGEX = "[$￥¥€£؋₩₱₾Т៛С̲৳₮ரூ₫₤₽₴Kƒ₲₦₵฿ΞŁÐ]{1}[-0-9.]{1,}"
        let items = extractText(for: FEE_PREFIX_REGEX, in: text)
        if items.isEmpty {
            inlineElements.append(.init(content: .init(text), attributes: attributes))
        } else {
            items.forEach { item in
                if item.type == .FEE {
                    attributes.insert(.bold)
                    attributes.insert(.money)
                    inlineElements.append(.init(content: .init(" \(item.text) "), attributes: attributes))
                    attributes.remove(.bold)
                    attributes.remove(.money)
                } else {
                    inlineElements.append(.init(content: .init(item.text), attributes: attributes))
                }
            }
        }
        // ------------------增加记账格式 text end--------------------------
        
        
    }

    mutating func visitOrderedList(_ markdown: OrderedList) {
        lists.append(.init(type: .ordered))
        descendInto(markdown)

        if let list = lists.last {
            if lists.count == 1 {
                // if we're at the root element, add the the tree to the block elements
                blockElements.append(.list(.init(list: list, level: lists.count - 1)))
            } else {
                // otherwise, append nested lists to the last list
                let index = lists.index(before: lists.index(before: lists.endIndex))
                lists[index].append(nested: list)
            }
        }

        lists.removeLast()
    }

    mutating func visitUnorderedList(_ markdown: UnorderedList) {
        lists.append(.init(type: .unordered))
        descendInto(markdown)

        if let list = lists.last {
            if lists.count == 1 {
                // if we're at the root element, add the the tree to the block elements
                blockElements.append(.list(.init(list: list, level: lists.count - 1)))
            } else {
                // otherwise, append nested lists to the last list
                let index = lists.index(before: lists.index(before: lists.endIndex))
                lists[index].append(nested: list)
            }
        }

        lists.removeLast()
    }

    mutating func visitListItem(_ markdown: Markdown.ListItem) {
        descendInto(markdown)
    }

    mutating func visitParagraph(_ markdown: Paragraph) {
        descendInto(markdown)
        
        if let listItem = markdown.parent as? ListItem {
            let index = lists.index(before: lists.endIndex)

            switch lists[index].type {
            case .ordered:
                lists[index].append(ordered: .init(
                    level: lists.count - 1,
                    bullet: .init(order: listItem.indexInParent + 1),
                    content: .init(content: .init(elements: inlineElements))
                )
                )
            default:
                if let checkbox = listItem.checkbox {
                    lists[index].append(checklist: .init(
                        level: lists.count - 1,
                        bullet: .init(isChecked: checkbox == .checked),
                        content: .init(content: .init(elements: inlineElements))
                    )
                    )
                } else {
                    lists[index].append(unordered: .init(
                        level: lists.count - 1,
                        bullet: .init(level: lists.count - 1),
                        content: .init(content: .init(elements: inlineElements))
                    )
                    )
                }
            }
        } else {
            if isNested {
                nestedBlockElements.append(.paragraph(.init(content: .init(elements: inlineElements))))
            } else {
                // TODO 判断是否启用了自动缩进
                if self.indent > 0 {
                    inlineElements.insert(.init(content: .init(Array(repeating: "&ensp;", count: indent).joined()), attributes: [.indent]), at: 0)
                }
                blockElements.append(.paragraph(.init(content: .init(elements: inlineElements))))
            }
        }

        inlineElements = []
    }

    mutating func visitImage(_ markdown: Markdown.Image) {
        let title = markdown.title ?? ""
        blockElements.append(.image(.init(source: markdown.source, title: title.isEmpty ? nil : title)))
    }

    mutating func visitLink(_ markdown: Markdown.Link) {
        descendInto(markdown)
    }

    mutating func visitStrong(_ markdown: Strong) {
        descendInto(markdown)
    }

    mutating func visitEmphasis(_ markdown: Emphasis) {
        descendInto(markdown)
    }

    mutating func visitInlineCode(_ markdown: InlineCode) {
        inlineElements.append(.init(content: .init(markdown.code), attributes: .code))
    }

    mutating func visitStrikethrough(_ markdown: Strikethrough) {
        descendInto(markdown)
    }

    mutating func visitCodeBlock(_ markdown: CodeBlock) {
        blockElements.append(.code(.init(code: markdown.code, language: markdown.language)))
        inlineElements = []
    }

    mutating func visitThematicBreak(_ markdown: ThematicBreak) {
        blockElements.append(.thematicBreak(.init()))
        descendInto(markdown)
    }

    mutating func visitBlockQuote(_ markdown: BlockQuote) {
        isNested = true
        descendInto(markdown)

        for element in nestedBlockElements {
            if case let .paragraph(config) = element {
                blockElements.append(.quote(.init(content: config)))
            }
        }

        inlineElements = []
        nestedBlockElements = []
        isNested = false
    }

    mutating func visitSoftBreak(_ markdown: SoftBreak) {
        visitText(.init(markdown.plainText))
    }

    mutating func visitTable(_: Markdown.Table) { }
    mutating func visitTableRow(_: Markdown.Table.Row) { }
    mutating func visitTableBody(_: Markdown.Table.Body) { }
    mutating func visitTableCell(_: Markdown.Table.Cell) { }
    mutating func visitTableHead(_: Markdown.Table.Head) { }

    mutating func visitSymbolLink(_: SymbolLink) { }
    mutating func visitBlockDirective(_: BlockDirective) { }
    mutating func visitCustomInline(_: CustomInline) { }
    mutating func visitHTMLBlock(_: HTMLBlock) { }
    mutating func visitInlineHTML(_: InlineHTML) { }
}
