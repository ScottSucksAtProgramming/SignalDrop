import SwiftUI

struct CollapsibleSectionView<Content: View>: View {
    let title: String
    @Binding var isCollapsed: Bool
    let isPaid: Bool
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            if isPaid {
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isCollapsed.toggle()
                    }
                } label: {
                    HStack {
                        Text(title)
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Image(systemName: isCollapsed ? "chevron.right" : "chevron.down")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                }
                .buttonStyle(.plain)
                .accessibilityLabel(String(localized: "\(title) section"))
                .accessibilityValue(isCollapsed ? String(localized: "Collapsed") : String(localized: "Expanded"))
                .accessibilityHint(String(localized: "Double tap to \(isCollapsed ? "expand" : "collapse")"))
            } else {
                Text(title)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)
            }

            if !isCollapsed || !isPaid {
                content()
            }
        }
    }
}
