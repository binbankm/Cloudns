# Cloudns 温和设计系统开发与维护指南 (DESIGN_SYSTEM.md)

本项目所有界面严格遵循 **Ultra-Gentle & Cozy HIG** 规范与 **单点真理（Single Source of Truth）** 原则。
若未来需要调整任何视觉风格、间距、字体或动效，**只需修改对应 Token 文件，全 App 所有页面自动同步更新，绝无在业务页面到处寻找魔数之忧**。

---

## 一、 Token 目录索引：改样式去哪改？

| 想要调整的设计要素 | 对应文件路径 | 说明与作用范围 |
| :--- | :--- | :--- |
| **全 App 背景/卡片/文字/状态颜色** | [`GentleColors.swift`](file:///Users/lbyan/Desktop/Cloudns/Cloudns/DesignSystem/GentleColors.swift) | 浅色燕麦米、深色石墨夜色、文字深浅、日落琥珀橙、鼠尾草绿等。支持系统暗黑模式与高对比度（Accessibility High Contrast）。 |
| **页面留白、卡片内边距、行间距** | [`GentleSpacing.swift`](file:///Users/lbyan/Desktop/Cloudns/Cloudns/DesignSystem/GentleSpacing.swift) | 基于 Apple HIG 8pt 律动网格（`micro: 2`, `xxs: 4`, `xs: 8`, `sm: 12`, `md: 16`, `lg: 20`, `xl: 24`, `xxl: 32`, `huge: 40`）。 |
| **卡片/按钮/搜索栏圆角连续曲率** | [`GentleCornerRadius.swift`](file:///Users/lbyan/Desktop/Cloudns/Cloudns/DesignSystem/GentleCornerRadius.swift) | 苹果超椭圆平滑连续曲率（`card: 22pt`, `cardLarge: 24pt`, `xl: 16pt`, `lg: 14pt`, `md: 12pt`, `sm: 8pt`, `pill: 999pt`）。 |
| **字体大小、圆角字形、等宽指标** | [`GentleTypography.swift`](file:///Users/lbyan/Desktop/Cloudns/Cloudns/DesignSystem/GentleTypography.swift) | 全系 SF Pro Rounded 柔和圆角。针对流量、DNS 记录数、TTL 强制提供 `.monospacedDigit()` 防跳动字体。 |
| **弹簧动效、阻尼系数、展开时间** | [`GentleAnimation.swift`](file:///Users/lbyan/Desktop/Cloudns/Cloudns/DesignSystem/GentleAnimation.swift) | 物理阻尼弹簧标准：`spring` (0.38/0.82)、`snappy` (0.28/0.76)、`gentleExpand` (0.42/0.84 抽屉与横幅专用)。 |
| **漫反射微阴影、柔光 Halo** | [`GentleShadow.swift`](file:///Users/lbyan/Desktop/Cloudns/Cloudns/DesignSystem/GentleShadow.swift) | 羽化漫反射微光（`card` 0.035 透明度、`subtle` 0.025 透明度、`amberGlow` 日落琥珀橙外发光）。 |
| **微触觉震动反馈** | [`GentleHaptics.swift`](file:///Users/lbyan/Desktop/Cloudns/Cloudns/DesignSystem/GentleHaptics.swift) | 统一振动：轻柔 `.light()`、选择 `.selection()`、操作完成 `.success()`、危险警告 `.warning()`。 |

---

## 二、 基础组件矩阵：业务页面如何调用？

### 1. 容器与卡片
* **标准卡片**：
  ```swift
  GentleCard(variant: .elevated) {
      // 内容
  }
  // 或修饰器方式：
  VStack { ... }
      .gentleCard()
  ```
* **全屏温润画布背景**：
  ```swift
  .gentleCanvas()
  ```
* **分组嵌入式卡片**：
  ```swift
  GentleSection(title: "Security", footer: "DNSSEC protects your domain.") {
      // 内部卡片行
  }
  ```
* **标准列表行与设置项**：
  ```swift
  GentleListRow(
      title: "Audit Logs",
      subtitle: "View recent operations",
      showDivider: true,
      showChevron: true,
      action: { ... },
      leading: { GentleIconTile(systemName: "list.bullet", tint: GentleColor.accent) }
  )
  ```

### 2. 按钮与交互控件
* **日落琥珀橙主按钮**：
  ```swift
  Button("Login") { ... }
      .gentlePrimaryButton()
  ```
* **温润卡片次级按钮**：
  ```swift
  Button("Cancel") { ... }
      .gentleSecondaryButton()
  ```
* **危险破坏性珊瑚红按钮**：
  ```swift
  Button("Delete Record") { ... }
      .gentleDestructiveButton()
  ```
* **Cloudflare 柔光蜜桃橙代理微开关**：
  ```swift
  Toggle("", isOn: $isProxied)
      .gentleToggle()
  ```
* **滑块分段器**：
  ```swift
  GentleSegmentedControl(items: ["A", "CNAME", "TXT"], selection: $recordType)
  ```

### 3. 表单输入与搜索
* **邮箱与 37 位 Key 专用输入框**：
  ```swift
  GentleTextField("Email", text: $email, leadingIcon: "envelope.fill")
  GentleTextField("Global API Key", text: $key, leadingIcon: "key.fill", isSecure: true, isMonospaced: true)
  ```
* **柔和圆角搜索栏**：
  ```swift
  GentleSearchBar(text: $searchQuery, placeholder: "Search domains or records")
  ```

### 4. 状态微标与通知反馈
* **语义状态胶囊徽标**：
  ```swift
  GentleBadge("Active", iconName: "checkmark", type: .active)
  GentleBadge("Proxied", iconName: "cloud.fill", type: .proxied)
  ```
* **多账号彩色首字母头像**：
  ```swift
  GentleAvatar(name: account.name, size: .medium, isActive: true)
  ```
* **超细温和分割线**：
  ```swift
  GentleDivider(leadingInset: 16) // 水平分割线
  GentleVerticalDivider(height: 30) // 统计卡片垂直分割线
  ```
* **异步加载按钮**：
  ```swift
  GentleLoadingButton("Save Record", isLoading: isSaving, iconName: "checkmark") {
      // 自动展示 GentleSpinner 并禁用交互
  }
  ```
* **行内提示卡片 (Callout)**：
  ```swift
  GentleCallout(
      title: "Keychain Security",
      message: "37-character Global API Key is saved securely.",
      type: .info // .info, .success, .warning, .danger
  )
  ```
* **微加载指示器与平滑进度条**：
  ```swift
  GentleSpinner(tint: GentleColor.accent, size: 20)
  GentleProgressBar(value: 0.75, tint: GentleColor.accent)
  ```
* **标准半屏抽屉头部**：
  ```swift
  GentleSheetHeader(title: "Add DNS Record", trailingButtonTitle: "Save") {
      // 保存操作
  }
  ```
* **破坏性动作温和确认弹窗**：
  ```swift
  .gentleConfirmationDialog(
      isPresented: $showDeleteConfirm,
      title: "Delete DNS Record",
      message: "This action cannot be undone.",
      confirmTitle: "Delete Record"
  ) {
      // 确认删除回调（自动触发 .warning 触觉反馈）
  }
  ```
* **骨架屏微动效**：
  ```swift
  RoundedRectangle(cornerRadius: GentleCornerRadius.xs, style: .continuous)
      .fill(GentleColor.cardSurfaceSecondary)
      .gentleShimmer()
  ```
* **空状态与人性化错误**：
  ```swift
  GentleEmptyStateView(title: "No Domains", message: "...") { ... }
  GentleErrorView(message: "Network offline") { ... }
  ```
* **全局悬浮通知横幅**：
  ```swift
  GentleBannerManager.shared.show(type: .success, title: "Saved", message: "DNS record updated.")
  GentleBannerManager.shared.showOffline()
  ```

---

## 三、 五大质量铁律 (Strict Quality Rules)

1. **绝对禁止在 View 中硬编码颜色**：严禁出现 `Color.black`, `Color.white`, `Color(red: ...)`, 必须调用 `GentleColor.xxx`。
2. **绝对禁止在 View 中使用绝对字号**：严禁出现 `.font(.system(size: 16))`，必须使用 `GentleTypography.xxx`，确保适配动态字体（Dynamic Type）。
3. **绝对禁止硬编码圆角与弹簧参数**：必须使用 `GentleCornerRadius.card`、`GentleAnimation.spring` 等统一 Token。
4. **绝对禁止在 Swift 代码中硬编码中文字符串**：代码中全用自解释英文 Key，中文翻译全部归档在 `Localizable.xcstrings`。
5. **绝对禁止引入任何 API Token 概念**：本项目只支持 Cloudflare 官方 Global API Key，使用 iOS Keychain 硬件隔离。
