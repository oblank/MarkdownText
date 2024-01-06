import SwiftUI
import SwiftUIBackports

/// A type that applies a custom appearance to unordered item markdown elements
public protocol MoneyListItemMarkdownStyle {
    associatedtype Body: View
    /// The properties of an unordered item markdown element
    typealias Configuration = MoneyListItemMarkdownConfiguration
    /// Creates a view that represents the body of a label
    @ViewBuilder func makeBody(configuration: Configuration) -> Body
}

public struct AnyMoneyListItemMarkdownStyle: MoneyListItemMarkdownStyle {
    var label: (Configuration) -> AnyView
    init<S: MoneyListItemMarkdownStyle>(_ style: S) {
        label = { AnyView(style.makeBody(configuration: $0)) }
    }

    public func makeBody(configuration: Configuration) -> some View {
        label(configuration)
    }
}

/// The properties of an unordered item markdown element
public struct MoneyListItemMarkdownConfiguration {
    private struct Item: View {
        @ScaledMetric private var reservedWidth: CGFloat = 25
        @Environment(\.markdownMoneyStyle) private var moneyStyle
//        @Environment(\.markdownMoneyListBulletStyle) private var bulletStyle
//        @Environment(\.markdownMoneyListItemBulletVisibility) private var bulletVisibility

        public let level: Int
//        public let bullet: MoneyListBulletMarkdownConfiguration
//        public let paragraph: ParagraphMarkdownConfiguration
        public let moneyConfig: MoneyMarkdownConfiguration

        private var space: String {
            Array(repeating: "    ", count: level).joined()
        }

        var body: some View {
            HStack(alignment: .firstTextBaseline, spacing: 0) {
                moneyStyle.makeBody(configuration: moneyConfig)
//                Label {
//                    paragraphStyle.makeBody(configuration: paragraph)
//                } icon: {
//                    if bulletVisibility != .hidden {
//                        bulletStyle.makeBody(configuration: bullet)
//                            .frame(minWidth: reservedWidth)
//                    }
//                }
//                .labelStyle(.list)
            }
        }
    }

    /// An integer value representing this element's indentation level in the list
    public let level: Int
    /// The bullet configuration for this element
//    public let bullet: MoneyListBulletMarkdownConfiguration
    /// The content configuration for this element
    public let content: MoneyMarkdownConfiguration
    /// Returns a default unordered item markdown representation
    public var label: some View {
//        Item(level: level, bullet: bullet, paragraph: content)
        Item(level: level, moneyConfig: content)
    }
}

/// The default unordered item style
public struct DefaultMoneyListItemMarkdownStyle: MoneyListItemMarkdownStyle {
    public init() { }
    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
    }
}

public extension MoneyListItemMarkdownStyle where Self == DefaultMoneyListItemMarkdownStyle {
    /// The default unordered item style
    static var `default`: Self { .init() }
}

private struct MoneyListItemMarkdownEnvironmentKey: EnvironmentKey {
    static let defaultValue = AnyMoneyListItemMarkdownStyle(.default)
}

public extension EnvironmentValues {
    /// The current unordered item markdown style
    var markdownMoneyListItemStyle: AnyMoneyListItemMarkdownStyle {
        get { self[MoneyListItemMarkdownEnvironmentKey.self] }
        set { self[MoneyListItemMarkdownEnvironmentKey.self] = newValue }
    }
}

public extension View {
    /// Sets the style for unordered item markdown elements
    func markdownMoneyListItemStyle<S>(_ style: S) -> some View where S: MoneyListItemMarkdownStyle {
        environment(\.markdownMoneyListItemStyle, AnyMoneyListItemMarkdownStyle(style))
    }
}
