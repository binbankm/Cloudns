import SwiftUI

/// Cloudns 标准按钮外观样式
public enum CloudnsButtonStyle {
    /// 主操作按钮 (品牌渐变背景 + 白色文字，全宽或自适应)
    case primary(color: Color = CloudnsColor.brandAccent)
    /// 次要操作按钮 (系统填充背景 + 语义主色文字)
    case secondary
    /// 危险操作按钮 (红色背景或红色警告色)
    case destructive
    /// 轮廓描边按钮 (透明背景 + 细边框)
    case outlined(color: Color = CloudnsColor.brandAccent)
    /// 纯文本轻量按钮 (无背景)
    case text(color: Color = CloudnsColor.brand)
}

/// Cloudns 按钮尺寸层级
public enum CloudnsButtonSize {
    /// 大尺寸主按钮 (高度 48pt，适合表单底部提交或登录 CTA)
    case large
    /// 标准中号按钮 (高度 40pt，符合 HIG 触控交互标准)
    case regular
    /// 紧凑小号按钮 (高度 32pt，适合列表内操作项或卡片内快捷操作)
    case small
    
    public var height: CGFloat {
        switch self {
        case .large: return CloudnsSize.controlHeightLarge
        case .regular: return CloudnsSize.controlHeight
        case .small: return CloudnsSize.controlHeightSmall
        }
    }
    
    public var horizontalPadding: CGFloat {
        switch self {
        case .large: return CloudnsSpacing.lg
        case .regular: return CloudnsSpacing.md
        case .small: return CloudnsSpacing.mdSmall
        }
    }
    
    public var font: Font {
        switch self {
        case .large: return CloudnsTypography.headline
        case .regular: return CloudnsTypography.body.weight(.semibold)
        case .small: return CloudnsTypography.subheadline.weight(.medium)
        }
    }
    
    public var cornerRadius: CGFloat {
        switch self {
        case .large: return CloudnsRadius.md
        case .regular: return CloudnsRadius.mdLg
        case .small: return CloudnsRadius.sm
        }
    }
}

// MARK: - Cloudns Button Component

public struct CloudnsButton: View {
    let title: LocalizedStringKey
    let icon: String?
    let style: CloudnsButtonStyle
    let size: CloudnsButtonSize
    let isFullWidth: Bool
    let isLoading: Bool
    let isDisabled: Bool
    let action: () -> Void
    
    @Environment(\.colorScheme) private var colorScheme
    @State private var isPressed: Bool = false
    
    public init(
        _ title: LocalizedStringKey,
        icon: String? = nil,
        style: CloudnsButtonStyle = .primary(),
        size: CloudnsButtonSize = .regular,
        isFullWidth: Bool = false,
        isLoading: Bool = false,
        disabled: Bool = false,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.icon = icon
        self.style = style
        self.size = size
        self.isFullWidth = isFullWidth
        self.isLoading = isLoading
        self.isDisabled = disabled
        self.action = action
    }
    
    public var body: some View {
        Button {
            guard !isLoading && !isDisabled else { return }
            HapticManager.impact(.light)
            action()
        } label: {
            HStack(spacing: CloudnsSpacing.xs) {
                if isLoading {
                    ProgressView()
                        .controlSize(size == .small ? .mini : .small)
                        .tint(foregroundColor)
                } else if let icon = icon {
                    Image(systemName: icon)
                        .font(size.font)
                        .accessibilityHidden(true)
                }
                
                Text(title)
                    .font(size.font)
                    .lineLimit(1)
            }
            .foregroundStyle(foregroundColor)
            .padding(.horizontal, size.horizontalPadding)
            .frame(maxWidth: isFullWidth ? .infinity : nil)
            .frame(height: size.height)
            .background(backgroundView)
            .clipShape(RoundedRectangle(cornerRadius: size.cornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: size.cornerRadius, style: .continuous)
                    .stroke(borderStrokeColor, lineWidth: borderStrokeWidth)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(isDisabled || isLoading)
        .opacity(isDisabled ? 0.45 : 1.0)
        .animation(.easeInOut(duration: 0.15), value: isDisabled)
        .animation(.easeInOut(duration: 0.15), value: isLoading)
        .accessibilityLabel(title)
    }
    
    // MARK: - Subviews & Styling
    
    @ViewBuilder
    private var backgroundView: some View {
        switch style {
        case .primary(let color):
            LinearGradient(
                colors: [color, color.opacity(0.85)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .secondary:
            CloudnsColor.chipBackground
        case .destructive:
            CloudnsColor.danger.opacity(colorScheme == .dark ? 0.85 : 0.90)
        case .outlined:
            Color.clear
        case .text:
            Color.clear
        }
    }
    
    private var foregroundColor: Color {
        switch style {
        case .primary:
            return .white
        case .secondary:
            return .primary
        case .destructive:
            return .white
        case .outlined(let color):
            return color
        case .text(let color):
            return color
        }
    }
    
    private var borderStrokeColor: Color {
        switch style {
        case .outlined(let color):
            return color.opacity(0.8)
        case .secondary:
            return colorScheme == .dark ? Color.white.opacity(0.08) : Color.black.opacity(0.04)
        default:
            return .clear
        }
    }
    
    private var borderStrokeWidth: CGFloat {
        switch style {
        case .outlined: return 1.2
        case .secondary: return 0.5
        default: return 0
        }
    }
}
