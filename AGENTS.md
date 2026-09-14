# Cloudns 全维度工业级架构规范与开发执行手册 (AGENTS.md)

本项目是一款基于 SwiftUI 构建的高性能原生 Cloudflare 客户端。为确保代码具备企业级严谨度、统一的工程语言、极致温和的视觉体验与长期的可维护性，所有开发与重构工作必须严格遵守本全维度规范。

---

## 目录索引
1. [鉴权与账号体系规范](#一-鉴权与账号体系规范-authentication--accounts)
2. [架构设计与状态机规范](#二-架构设计与状态机规范-mvvm--state-machine)
3. [国际化与多语言规范](#三-国际化与多语言规范-i18n--localization)
4. [界面设计语言与视觉规范](#四-界面设计语言与视觉规范-ultra-gentle--cozy-hig)
5. [文案与微交互语气指南](#五-文案与微交互语气指南-tone-of-voice--microcopy)
6. [目录与文件组织规范](#六-目录与文件组织规范-directory-tree--architecture)
7. [命名与 Swift 编码风格规范](#七-命名与-swift-编码风格规范-naming--conventions)
8. [网络通信与 API 对齐规范](#八-网络通信与-api-对齐规范-networking--cloudflare-api)
9. [内存安全与生命周期管理](#九-内存安全与生命周期管理-memory--performance)
10. [安全合规与隐私保护](#十-安全合规与隐私保护-security--privacy)
11. [完整开发执行顺序 (Roadmap)](#十一-完整开发执行顺序-standard-roadmap)
12. [质量红线与代码审查清单](#十二-质量红线与代码审查清单-code-review-redlines)

---

## 一、 鉴权与账号体系规范 (Authentication & Accounts)

1. **纯粹的 Global API Key 鉴权**：
   - **绝对禁止引入 API Token**。本项目所有鉴权完全基于 Cloudflare Global API Key。
   - 账号模型 `CloudflareAccount` 严格定义：
     ```swift
     struct CloudflareAccount: Identifiable, Codable, Sendable, Equatable {
         let id: String           // UUID String，唯一标识
         var name: String         // 用户备注别名（如“个人主站”、“公司生产”）
         let email: String        // Cloudflare 登录邮箱
         let createdAt: Date      // 创建时间
     }
     ```
2. **钥匙串物理隔离与安全性**：
   - 37 位 Global API Key 属于高度敏感凭证，**严禁明文保存在 UserDefaults**。
   - 必须通过 iOS `Security.framework` 的 `KeychainHelper` 安全存取：
     - 查询类：`kSecClassGenericPassword`
     - 服务名：`com.cloudflare.api`
     - 账号索引：以 `account.id` 作为唯一 Key 隔离存储。
     - 权限保护级别：`kSecAttrAccessibleWhenUnlockedThisDeviceOnly`（仅当设备解锁且仅本机有效，严防备份提取与跨设备同步泄露）。
3. **多账号管理与无感热切换**：
   - `AccountManager` 作为全局唯一的 `@MainActor` 单例集中管理账号持久化列表与当前激活账号（`activeAccountId`）。
   - 切换账号时执行以下标准流程：
     1. 更新内存与 UserDefaults 中的当前激活 `activeAccountId`；
     2. 立即清空上一个账号的内存敏感缓存（域名列表、DNS 记录等）；
     3. 触发全局广播通知（`Notification.Name.accountSwitched`）；
     4. 触发轻柔微触觉反馈（`.selection`），当前视图无感拉取新账户数据。
4. **请求自动装配**：
   - 底层 `AuthenticatedRequestFactory` 统一从 `AccountManager.shared.currentAccount` 提取凭证，在每个请求中自动注入官方鉴权 Header：
     ```http
     X-Auth-Email: user@example.com
     X-Auth-Key: 37位GlobalApiKey
     ```

---

## 二、 架构设计与状态机规范 (MVVM & State Machine)

1. **标准 MVVM 职责清晰划分**：
   - **View**：纯粹声明式 UI 渲染，只负责响应 ViewModel 的 `@Published` 属性变化和向 ViewModel 派发用户意图（如点击、滑动），**严禁出现任何网络请求、业务计算或数据持久化逻辑**。
   - **ViewModel**：
     - 负责管理单个页面或组件的所有 UI 状态与业务编排。
     - 必须继承 `ObservableObject`，类前必须标注 `@MainActor`。
     - 数据流遵循单向数据流（UDF），所有对外状态以 `@Published` 属性暴露给 View。
   - **Service**：
     - 面向协议（Protocol）设计，承接 ViewModel 的业务动作。
     - 全面基于 Swift 5.10 / 6 并发模型（`async/await` / `throws`），遵循 `Sendable` 规范。
     - 依赖注入 `HTTPNetworkClient` 与 `AuthenticatedRequestFactory`。
   - **Model**：纯 Swift 强类型结构体，遵循 `Codable`、`Identifiable`、`Sendable`、`Equatable`。
2. **统一标准页面状态机 (ViewState Machine)**：
   - **严禁**在 ViewModel 中定义多个碎散的布尔状态（如同时定义 `isLoading`、`isError`、`hasData`，极易导致状态死锁）。
   - 必须统一使用泛型页面状态枚举：
     ```swift
     enum ViewState<T>: Equatable where T: Equatable {
         case idle                        // 初始待机态
         case loading                     // 数据加载中（骨架屏/微光渐变）
         case loaded(T)                   // 加载成功（包含强类型数据载荷）
         case empty(message: String)      // 成功但无数据（包含温和引导文案）
         case error(message: String)      // 失败（包含温和友好的人性化提示）
     }
     ```
   - 每个主页面必须完整处理该枚举的 5 种状态，杜绝任何加载卡死、白屏或无响应体验。
3. **系统兼容基准与渐进增强**：
   - **最低系统支持：iOS 16.0**。
   - **严禁**使用 iOS 17+ 专属的 `@Observable` 宏，以保证在 iOS 16 上的绝对稳定性。
   - 对 iOS 17/18 新特性采用向下兼容封装或条件编译（`#available`）。

---

## 三、 国际化与多语言规范 (i18n & Localization)

1. **技术方案**：
   - 统一采用苹果推荐的现代 **String Catalog (`Localizable.xcstrings`)**。
   - 针对当前版本，基准支持：**英文 (`en`) 作为默认源语言**，**简体中文 (`zh-Hans`) 作为首选语言**。
2. **文案 Key 与自然语言抽取规范**：
   - 在 SwiftUI View 中直接使用具有自解释意义的英文语句作为 Key，例如：
     ```swift
     Text("DNS Records")
     Text("Add New Record")
     ```
   - 对于需要参数插值的字符串，使用命名参数格式化：
     ```swift
     Text("Active Domains: \(count, format: .number)")
     ```
3. **中英文混排排版规范**：
   - 中文与英文单词、阿拉伯数字之间**必须保留一个半角空格**：
     - ❌ `添加A记录至example.com`
     -  `添加 A 记录至 example.com`
   - 专有名词与大小写严格遵循官方标准：`Cloudflare`、`DNSSEC`、`Global API Key`、`IPv4 / IPv6`、`TTL`、`CNAME`、`Nameservers`。
4. **数字、货币与时间本地化**：
   - 涉及时间戳解析统一调用 `DateFormatters`，根据用户系统当前 Locale 自动呈现本地化相对时间（如“2 小时前” / “2 hours ago”）。
   - 请求量、带宽等数据必须通过 `MetricFormatters` 与 `ByteCountFormatters` 格式化，严禁生硬拼凑 `xxx bytes`。

---

## 四、 界面设计语言与视觉规范 (Ultra-Gentle & Cozy HIG)

本项目采用**极致温和风格（Ultra-Gentle & Calming）+ 苹果原生 HIG 规范**，彻底摒弃生硬冰冷的技术后台感，营造如同 Apple Health、Things 3 般的舒适、松弛与高质量质感。

### 1. 配色系统 (Design Tokens)
* **主背景 (Background)**：
  * 浅色模式：温润燕麦米 / 暖羊绒色（`#F7F4EE`），呈现高级哑光纸张般的舒适质感。
  * 深色模式：深邃石墨夜色（`#1C1C1E`），杜绝粗暴死黑（#000000）。
* **卡片浮层 (Card Surface)**：
  * 浅色模式：温润奶白（`#FDFBF7`），自然悬浮。
  * 深色模式：深岩板灰（`#2C2C2E`），极度护眼。
* **主强调色 (Warm Accent)**：
  * 温暖的日落琥珀橙（`#E87A1E` / `RGB(232, 122, 30)`），降饱和度并带有温暖柔光，非高亮荧光橙。
* **文字颜色 (Typography)**：
  * 主要文字：深暖木炭灰（`#2E2A27` / 浅色模式）与 纯净暖白（`#F5F5F7` / 深色模式）。
  * 次要说明文字：暖灰（`#8E8883`）。
* **语义状态色 (Semantic Badges)**：
  * 正常生效 / Active：低饱和马卡龙鼠尾草绿（Pastel Sage Green，`#5B8E7D`）。
  * 代理状态 / Proxied：柔光蜜桃暖橙（Warm Peach Orange，`#E08A58`）。
  * 危险操作 / Delete：温和珊瑚粉红（Coral Red，`#D96B6B`）。

### 2. 容器与形状 (Shapes & Surfaces)
* **超椭圆平滑连续曲率 (Squircle)**：
  * 卡片统一使用 **22pt~24pt** 的苹果连续曲率超椭圆：
    ```swift
    .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
    ```
    视觉上杜绝任何生硬棱角与接缝。
* **羽化级环境微光阴影 (Feather-soft Shadow)**：
  * 拒绝粗硬黑边框与浓黑阴影，统一采用漫反射微光阴影：
    ```swift
    .shadow(color: Color.black.opacity(0.035), radius: 10, x: 0, y: 3)
    ```
* **状态胶囊 (Pill Badges)**：
  * 状态和标签统一采用大圆角胶囊形态，半透明微底色（10%~12% 不透明度）搭配深色文本。

### 3. 字体与排版 (Typography & Spacing)
* 字形优先使用 **SF Pro Rounded**（柔和圆角字体），数据与时间强制使用 `.monospacedDigit()` 避免跳动。
* 保持充足的呼吸感留白：
  * 卡片内边距：16pt ~ 20pt
  * 列表卡片间距：12pt ~ 14pt
  * 分组模块间距：24pt
  * 页面水平边距：16pt ~ 20pt

### 4. 触觉与微动效 (Gentle Haptics & Springs)
* 动画曲线：统一使用平滑弹簧阻尼：
  ```swift
  .animation(.spring(response: 0.38, dampingFraction: 0.82), value: ...)
  ```
* 触觉反馈：
  * 点击切换账号、点选标签：`.selection`
  * 刷新完成、保存成功：`.light` 或 `.soft`
  * 删除或破坏性操作：`.warning`

---

## 五、 文案与微交互语气指南 (Tone of Voice & Microcopy)

1. **核心基调**：**专业、简洁、温和、克制、富有同理心**。
2. **拒绝冰冷机器错误**：
   * ❌ 严禁向用户直接呈现冷硬错误代码：`The operation couldn’t be completed. (Code -1009)` 或 `Error 10000: Unauthorized`。
   *  必须转化为温和、清晰、可操作的指引：
     - 网络离线：*“网络连接似乎暂时中断了 · 请检查后轻触重试”*
     - 凭据无效：*“邮箱或 Global API Key 未通过验证 · 请检查是否拼写正确”*
     - 记录冲突：*“已存在相同的解析记录 · 请修改主机名或内容”*
3. **按钮行动点明确**：
   - 动作优先使用精准动词，杜绝“确定”、“提交”等模糊用词。
   - 推荐：“保存解析记录”、“立即切换账户”、“开始校验凭据”、“移除此账号”。
4. **空状态充满温度**：
   - 空数据时必须呈现柔和的 SF Symbol 图标 + 温暖的说明文案 + 引导按钮（如：“暂无域名 · 轻触下方添加绑定”）。

---

## 六、 目录与文件组织规范 (Directory Tree & Architecture)

**严禁创建 `Common.swift`、`Utils.swift`、`Helper.swift` 这种职责混乱的垃圾桶类**。全工程采用特征分层结构：

```text
Cloudns/
├── App/                             # 应用主入口与根容器
│   ├── CloudnsApp.swift
│   └── ContentView.swift
├── DesignSystem/                    # 全局温和设计系统（与业务彻底解耦）
│   ├── GentleColors.swift           # 动态语义化色彩 Token
│   ├── GentleCardModifier.swift     # 22pt 超椭圆卡片与微阴影
│   ├── GentleBadge.swift            # 状态与类型胶囊组件
│   └── GentleHaptics.swift          # 微触觉反馈 API
├── Account/                         # 纯 Global Key 账户域
│   ├── CloudflareAccount.swift      # 账户模型
│   └── AccountManager.swift         # 多账号增删改查与 Keychain 存取
├── Models/                          # 纯 Swift 强类型模型（纯 Codable / Sendable）
│   ├── Base/                        # APIError、CloudflareResponse 等通用响应信封
│   ├── Zones/                       # Zone、ZoneSetting 等域名模型
│   ├── DNS/                         # DNSRecord、DNSSEC 等解析模型
│   ├── Security/                    # WAF、IPAccessRules 等安全模型
│   ├── Settings/                    # AuditLog、CloudflareStatus 等设置模型
│   └── Developer/                   # Workers、Pages、KV 等开发者生态模型
├── Services/                        # 面向协议的纯异步业务服务层
│   ├── Base/                        # HTTPNetworkClient、AuthenticatedRequestFactory
│   ├── Auth/                        # AuthValidationService (用于校验凭据)
│   ├── Zones/                       # ZoneServiceProtocol & ZoneService
│   ├── DNS/                         # DNSServiceProtocol & DNSService
│   └── ...                          # 其余各模块对应 Service
├── ViewModels/                      # MVVM 状态与逻辑中心（@MainActor）
│   ├── Auth/                        # LoginViewModel
│   ├── Account/                     # AccountSwitcherViewModel
│   ├── Zones/                       # ZonesListViewModel
│   ├── DNS/                         # DNSRecordsViewModel
│   └── Settings/                    # SettingsViewModel
├── Views/                           # 纯粹的 SwiftUI 页面渲染
│   ├── Auth/                        # LoginView, ApiKeyGuideSheet
│   ├── Account/                     # AccountSwitcherView (半屏抽屉)
│   ├── Zones/                       # ZonesListView, ZoneCardView, HealthRingCard
│   ├── DNS/                         # DNSRecordsView, DNSRecordRow, DNSRecordFormSheet
│   └── Settings/                    # SettingsView
├── Assets.xcassets/                 # 核心图标与强调色资源
├── Info.plist                       # 基础属性配置
├── Cloudns.entitlements             # 权限配置
├── Localizable.xcstrings            # 中英双语多语言字典
└── PrivacyInfo.xcprivacy            # App Store 隐私合规清单
```

**文件大小铁律**：单一 View 或 ViewModel 文件行数尽量控制在 **300 行以内**，复杂视图必须合理拆分为子组件（Subviews）。

---

## 七、 命名与 Swift 编码风格规范 (Naming & Conventions)

严格对齐 **Swift API Design Guidelines** 与全局 `swiftlint`：

1. **类型命名（大驼峰 PascalCase）**：
   - 视图类必须以 `View` 或 `Sheet` 结尾：`ZonesListView`、`DNSRecordFormSheet`。
   - ViewModel 类必须以 `ViewModel` 结尾：`ZonesListViewModel`。
   - 业务服务类必须成对定义：
     - 协议：`[Module]ServiceProtocol`（如 `DNSServiceProtocol`）
     - 实现类：`[Module]Service`（如 `DNSService`）
2. **属性与方法命名（小驼峰 camelCase）**：
   - 布尔值属性必须以 **断言动词** 开头：`isLoading`、`isProxied`、`hasActiveAccount`、`canSubmit`。
   - 方法命名必须动词开头，自解释性强：
     ```swift
     func fetchZones(page: Int) async throws -> [Zone]
     func switchAccount(to id: String)
     func deleteRecord(zoneId: String, recordId: String) async throws
     ```
3. **通知名规范**：
   - 统一采用反向域名命名空间，防止冲突：
     ```swift
     extension Notification.Name {
         static let accountSwitched = Notification.Name("com.cloudns.accountSwitched")
         static let localCachePurged = Notification.Name("com.cloudns.localCachePurged")
     }
     ```

---

## 八、 网络通信与 API 对齐规范 (Networking & Cloudflare API)

1. **严格对齐 Cloudflare v4 REST API 文档**：
   - 端点路径、Query 参数、Body 格式必须 100% 对齐官方文档（`https://developers.cloudflare.com/api/`）。
2. **统一信封反序列化**：
   - 所有 Cloudflare 接口返回均被 `CloudflareResponse<T>` 信封包裹：
     ```swift
     struct CloudflareResponse<T: Codable & Sendable>: Codable, Sendable {
         let success: Bool
         let errors: [APIErrorDetail]
         let messages: [String]
         let result: T?
         let resultInfo: ResultInfo?
     }
     ```
   - 遇到 `success == false` 时，自动解析首个错误信息并包装为强类型 `APIError` 抛出。
3. **网络状态自适应**：
   - 离线时优雅呈现温和横幅，禁止直接弹出阻断式阻塞弹窗。

---

## 九、 内存安全与生命周期管理 (Memory & Performance)

1. **强引用循环杜绝 (Zero Retain Cycles)**：
   - 在所有的闭包、通知监听或异步回调中，涉及 `self` 访问必须显式声明 `[weak self]`，严防页面关闭后 ViewModel 无法释放导致的内存泄漏。
2. **自动任务生命周期绑定 (Task Cancellation)**：
   - View 触发的异步加载统一使用 SwiftUI 原生 `.task { await viewModel.fetchData() }`。
   - 当用户退出页面时，系统会自动发出 Cancellation 信号，底层 `URLSession` 立即终止网络请求，省电省流量。
3. **UI 120Hz 满帧渲染原则**：
   - 所有耗时的数据解析、JSON 序列化必须在后台并发线程进行，只有最终赋值给 `@Published` 属性的操作在 `@MainActor` 主线程完成，杜绝任何滑动掉帧。

---

## 十、 安全合规与隐私保护 (Security & Privacy)

1. **硬件级存储安全**：
   - Global API Key 仅保存在 Keychain 中，并限定当前设备使用。
2. **敏感信息脱敏日志**：
   - 日志与调试打印（`print` / `OSLog`）中**严禁打印完整的 37 位 Global API Key**。如需排查，仅允许打印掩码（如 `1234****abcd`）。
3. **App Store 隐私合规 (PrivacyInfo.xcprivacy)**：
   - 保持工程内 `PrivacyInfo.xcprivacy` 的准确声明，合规使用系统 API。

---

## 十一、 完整开发执行顺序 (Standard Roadmap)

后续开发必须严格按以下 6 个阶段顺序推进，步步为营，确保每个阶段通过编译与验证：

```
Phase 1: 温和设计系统与多账号底层基建（当前第一步）
   │ 
   ├── GentleColors / GentleCard / GentleBadge / GentleHaptics
   └── AccountManager (纯 Global API Key + Keychain 硬件隔离)
   ▼
Phase 2: 鉴权流程与多账号管理
   │
   ├── LoginView / LoginViewModel（邮箱 + 37位 Key 格式与网络有效性验证）
   └── AccountSwitcherView（顶部半屏抽屉，一键打勾无感切换）
   ▼
Phase 3: 域名管理与温和仪表盘 (Zones)
   │
   ├── 对齐 Cloudflare GET /client/v4/zones 官方 API
   └── ZonesListView（暖杏光环运行健康度总览 + 域名卡片列表）
   ▼
Phase 4: DNS 解析记录核心引擎 (DNS CRUD)
   │
   ├── 对齐 Cloudflare DNS Records 官方 API
   ├── DNSRecordsView（彩色类型胶囊、一键秒切蜜桃橙云朵代理）
   └── DNSRecordFormSheet（优雅的添加/编辑抽屉表单）
   ▼
Phase 5: 全局设置与系统中心 (Settings)
   │
   └── SettingsView（账号集中管理、深色石墨夜色切换、应用锁与缓存清理）
   ▼
Phase 6: 高级特性逐步扩展 (Post-MVP)
   └── Workers / Pages / WAF / SSL 逐步演进
```

---

## 十二、 质量红线与代码审查清单 (Code Review Redlines)

在完成任何模块的代码提交前，必须逐项通过以下质量审查：

- [ ] **0 警告 0 报错**：`xcodebuild` 编译无任何 error 和 warning。
- [ ] **SwiftLint 零违规**：必须通过 `swiftlint` 扫描，0 violations。
- [ ] **线程安全保证**：ViewModel 均有 `@MainActor`，异步数据获取不卡主线程。
- [ ] **零硬编码**：颜色全部调用 `GentleColor`，圆角全部使用 `DesignSystem` 规范。
- [ ] **文案与国际化**：中英文排版规范，文案温和有温度，禁止裸露原生技术报错。
- [ ] **纯 Global API Key**：严禁出现任何 API Token 相关的代码或参数。
