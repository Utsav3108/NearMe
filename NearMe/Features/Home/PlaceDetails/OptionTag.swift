import SwiftUI

struct OptionTag: View {
    let title: String
    let icon: String
    let activeIcon: String?
    let isActive: Bool
    let isPrimary: Bool
    let action: () -> Void

    init(
        title: String,
        icon: String,
        activeIcon: String? = nil,
        isActive: Bool = false,
        isPrimary: Bool = false,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.icon = icon
        self.activeIcon = activeIcon
        self.isActive = isActive
        self.isPrimary = isPrimary
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            VStack(spacing: 7) {
                Image(systemName: currentIcon)
                    .font(.headline)

                Text(title)
                    .font(.caption.weight(.medium))
            }
            .foregroundStyle(foregroundColor)
            .frame(maxWidth: .infinity)
            .frame(height: 72)
            .background(
                backgroundColor,
                in: RoundedRectangle(cornerRadius: 18)
            )
        }
        .buttonStyle(.plain)
    }

    private var currentIcon: String {
        if isActive, let activeIcon {
            return activeIcon
        }

        return icon
    }

    private var foregroundColor: Color {
        isPrimary || isActive
            ? .white
            : .accentColor
    }

    private var backgroundColor: Color {
        isPrimary || isActive
            ? .accentColor
            : Color(uiColor: .secondarySystemBackground)
    }
}
