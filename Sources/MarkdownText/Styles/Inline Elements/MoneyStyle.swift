import SwiftUI

/// A type that applies a custom appearance to bold (strong) markdown elements
public protocol MoneyMarkdownStyle {
    /// The properties of a bold (strong) markdown element
    typealias Configuration = MoneyMarkdownConfiguration
    /// Creates a view that represents the body of a label
    func makeBody(configuration: Configuration) -> Text
}

/// The properties of a bold (strong) markdown element
public struct MoneyMarkdownConfiguration {
    /// The textual content for this element
    public let content: Text
    /// Returns a default bold (strong) markdown representation
    public var label: Text { content.bold() }
}

/// An bold (strong) style that applies the `bold` modifier to its textual content
public struct DefaultMoneyMarkdownStyle: MoneyMarkdownStyle {
    public init() { }
    public func makeBody(configuration: Configuration) -> Text {
        configuration.label
            .foregroundColor(.accentColor)
    }
}

public extension MoneyMarkdownStyle where Self == DefaultMoneyMarkdownStyle {
    /// An bold (strong) style that applies the `bold` modifier to its textual content
    static var `default`: Self { .init() }
}

private struct MoneyMarkdownEnvironmentKey: EnvironmentKey {
    static let defaultValue: MoneyMarkdownStyle = DefaultMoneyMarkdownStyle()
}

public extension EnvironmentValues {
    /// The current bold (strong) markdown style
    var markdownMoneyStyle: MoneyMarkdownStyle {
        get { self[MoneyMarkdownEnvironmentKey.self] }
        set { self[MoneyMarkdownEnvironmentKey.self] = newValue }
    }
}

public extension View {
    /// Sets the style for bold (strong) markdown elements
    func markdownMoneyStyle<S>(_ style: S) -> some View where S: MoneyMarkdownStyle {
        environment(\.markdownMoneyStyle, style)
    }
}
