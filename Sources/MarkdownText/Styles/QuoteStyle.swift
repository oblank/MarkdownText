import SwiftUI

public protocol QuoteMarkdownStyle {
    associatedtype Body: View
    typealias Configuration = QuoteMarkdownConfiguration
    @ViewBuilder func makeBody(configuration: Configuration) -> Body
}

internal struct AnyQuoteMarkdownStyle {
    var label: (QuoteMarkdownConfiguration) -> AnyView
    init<S: QuoteMarkdownStyle>(_ style: S) {
        label = { AnyView(style.makeBody(configuration: $0)) }
    }
}

public struct QuoteMarkdownConfiguration {
    public let paragraph: ParagraphMarkdownConfiguration
}

public struct DefaultQuoteMarkdownStyle: QuoteMarkdownStyle {
    public init() { }
    public func makeBody(configuration: Configuration) -> some View {
        configuration.paragraph.label
    }
}

public extension QuoteMarkdownStyle where Self == DefaultQuoteMarkdownStyle {
    static var `default`: Self { .init() }
}

public struct NoQuoteMarkdownStyle: QuoteMarkdownStyle {
    public init() { }
    public func makeBody(configuration: Configuration) -> some View {
        EmptyView()
    }
}

public extension QuoteMarkdownStyle where Self == NoQuoteMarkdownStyle {
    static var hidden: Self { NoQuoteMarkdownStyle() }
}

private struct QuoteMarkdownEnvironmentKey: EnvironmentKey {
    static let defaultValue = AnyQuoteMarkdownStyle(.default)
}

extension EnvironmentValues {
    var markdownQuoteStyle: AnyQuoteMarkdownStyle {
        get { self[QuoteMarkdownEnvironmentKey.self] }
        set { self[QuoteMarkdownEnvironmentKey.self] = newValue }
    }
}

public extension View {
    func markdownQuoteStyle<S>(_ style: S) -> some View where S: QuoteMarkdownStyle {
        environment(\.markdownQuoteStyle, AnyQuoteMarkdownStyle(style))
    }
}
