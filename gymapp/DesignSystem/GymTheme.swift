import SwiftUI

/// Semantic asset colors adapt to light and dark appearances.
enum GymTheme {
    static let canvas = Color("Canvas")
    static let surface = Color("Surface")
    static let softAccent = Color("SoftAccent")
    static let onAccent = Color("OnAccent")
}

private struct GymListStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .background(GymTheme.canvas)
            .listSectionSpacing(20)
            .environment(\.defaultMinListRowHeight, 56)
            .tint(.accentColor)
    }
}

extension View {
    func gymListStyle() -> some View {
        modifier(GymListStyle())
    }

    func gymCard() -> some View {
        padding(20)
            .background(GymTheme.surface, in: RoundedRectangle(cornerRadius: 24))
    }
}

struct GymPrimaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity, minHeight: 52)
            .foregroundStyle(isEnabled ? GymTheme.onAccent : Color.secondary)
            .background(
                isEnabled ? Color.accentColor : GymTheme.softAccent,
                in: RoundedRectangle(cornerRadius: 18)
            )
            .opacity(configuration.isPressed ? 0.78 : 1)
            .contentShape(RoundedRectangle(cornerRadius: 18))
    }
}

struct GymIcon: View {
    let symbol: String

    var body: some View {
        Image(systemName: symbol)
            .font(.title3.weight(.semibold))
            .foregroundStyle(.tint)
            .frame(width: 48, height: 48)
            .background(GymTheme.softAccent, in: RoundedRectangle(cornerRadius: 16))
            .accessibilityHidden(true)
    }
}

/// A compact introduction, using the same hierarchy across sheets and tabs.
struct GymIntro: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    let title: LocalizedStringKey
    let subtitle: LocalizedStringKey
    let symbol: String

    var body: some View {
        let layout = dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: 12))
            : AnyLayout(HStackLayout(alignment: .top, spacing: 16))
        return layout {
            GymIcon(symbol: symbol)
            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.title3.weight(.bold))
                    .foregroundStyle(.primary)
                    .accessibilityAddTraits(.isHeader)
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 8)
    }
}
