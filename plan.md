1. 🏛️ 架构设计与代码组织 (Architecture & Code Organization)
清晰的分层架构 (Clean Layered Architecture)：
Presentation 层 (UI & ViewModels)：负责视图渲染与用户意图处理，保持 View 为声明式纯 UI，业务状态收敛在 ViewModel。
Domain 层 (Use Cases & Business Logic)：核心业务规则，不依赖具体 UI 框架。
Data 层 (Repositories & Services)：负责向远程 API 或本地数据库读写数据。
Core / Foundation 层：网络底座、设计系统、工具集、缓存系统。
面向协议抽象与依赖注入 (Protocol-Oriented & DI)：
所有服务接口（如 DNSServiceProtocol）均面向协议设计，依赖通过构造器注入（Initializer Injection），便于脱机注入 Mock 数据进行 100% 独立测试。
单一职责与无“神类” (No God Classes)：
单个文件/类控制在合理行数（通常不超过 300~500 行），无职责混杂。
2. ⚡ Swift 6 现代化语言与并发标准 (Swift 6 Strict Concurrency)
数据竞争安全 (Data-Race Safety)：
全面开启 Swift 6 Strict Concurrency 模式，消除所有编译器并发告警。
严格的 Actor 隔离边界：
所有 UI 相关的状态（@Published、ViewModel、Navigation）严格限定在 @MainActor。
共享可变状态采用 actor 进行线程安全封装（如 SWRCacheStore、RDAPService）。
结构化并发 (Structured Concurrency)：
杜绝脱离生命周期的随意 Task { ... } 派发。
使用受管的 Task 句柄（如防抖搜索时显式执行 task?.cancel()）或 TaskGroup、AsyncSequence。
强类型错误模型 (Typed Errors & LocalizedError)：
统一定义具有丰富语义的 Error 枚举，并实现 LocalizedError，提供对用户友好的错误说明与恢复建议。
3. 🌐 网络通信与数据持久化 (Networking & Data Resilience)
高性能网络底座 (Robust Network Client)：
合理的超时控制（如请求 15s、资源 30s），连接池复用，支持 HTTP/2 与 HTTP/3。
SWR 双层缓存机制 (Stale-While-Revalidate)：
内存缓存（0ms 极速响应）+ 磁盘持久化（沙盒隔离）。
支持缓存 TTL（过期时间）与多租户/多账号 Key 隔离。
弹性网络容灾 (Resilience & Rate-Limiting)：
对 HTTP 429（Rate Limit）自动读取 Retry-After 头并执行带抖动的指数退避重试 (Exponential Backoff with Jitter)。
针对弱网/断网环境提供离线暂存或优雅降级提示。
安全本地持久化：
敏感凭据（Token、Key）存储于 Keychain，业务数据使用 SwiftData / CoreData / SQLite，轻量用户偏好使用 UserDefaults (@AppStorage)。
4. 🔒 安全与隐私合规 (Security & Privacy by Design)
凭据与敏感数据保护：
Keychain 权限严格设置 kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly（禁止无密码或云同步外泄）。
界面敏感凭证（如 Secret Key、Private Key）默认掩码脱敏（••••••），支持生物识别防偷窥。
传输层安全 (TLS / ATS)：
强制 HTTPS，遵循 Apple App Transport Security (ATS) 规范，验证证书链。
生物识别与应用防窥 (Biometrics & Privacy Shield)：
支持 Face ID / Touch ID 二次解锁；进入多任务后台（App Switcher）时自动施加高斯模糊/隐私遮罩，防截屏信息泄露。
官方隐私清单 (Privacy Manifest)：
配置 PrivacyInfo.xcprivacy，明确声明 API 访问理由（如 UserDefaults、File Timestamp）以满足 App Store 审核硬性要求。
5. 🎨 Apple HIG 美学、无障碍与交互 (Apple HIG & Accessibility)
统一设计系统 (Design System)：
使用语义化颜色（Color(.systemBackground)、Color(.label)），完美支持深色/浅色模式与对比度增强。
遵循 Apple 材质规范（Ultra-Thin Material 毛玻璃、0.5pt 微高光描边）。
无障碍排版 (Dynamic Type 100% 适配)：
移除所有固定最大高度（maxHeight），让文字在开启大号辅助字体时自由缩放而不截断。
为所有无文字的图标按钮配置 .accessibilityLabel。
原生微交互与触感系统 (Motion & Haptics)：
统一使用系统 Spring 弹簧动效；为点击、删除、成功、失败提供层级分明的触感震动（UIImpactFeedbackGenerator / UINotificationFeedbackGenerator）。
交互细节 (Keyboard & Focus)：
表单配置 @FocusState 链式回车跳格，支持 .scrollDismissesKeyboard(.interactively)。
6. 🚀 性能与系统资源治理 (Performance & Resource Management)
渲染性能 (120Hz ProMotion)：
稳定 View Identity，消除 SwiftUI 视图无效重绘风暴（Invalidation Storms）。
海量列表（如千条 DNS 记录）做懒加载与分页虚拟化。
内存与资源生命周期 (Zero Leaks & OOM Prevention)：
杜绝 Delegate 引起的 URLSession 强引用泄露，及时调用 invalidateAndCancel()。
大文件 I/O（如 R2 对象上传下载）采用沙盒文件流（Stream/File URL），禁止大块 Data 读入内存避免 Jetsam OOM 闪退。
WebSocket 长连接具备 30s 定时 Ping 心跳与自动断线感知。
7. 🧪 全链路测试与质量保证 (Testing & Code Quality)
分层测试体系：
单元测试 (Unit Tests)：覆盖 ViewModel 状态机、API 解码、数据转换、分页回滚、转义逻辑（测试覆盖率目标 80%+）。
Mock 测试：注入 Mock 网络客户端，无需依赖真实网络即可跑通所有测试。
UI / 快照测试 (Snapshot Testing)：自动化比对不同机型、多语言与深浅色模式下的排版一致性。
静态代码分析与门禁：
配置 .swiftlint.yml，严格禁止强制解包（!）、死代码与空 catch。
8. 📦 国际化与工程化交付 (i18n & DevOps)
现代国际化 (String Catalogs)：
使用 Xcode 15+ 的 Localizable.xcstrings，全量覆盖中英文本地化，规范格式化占位符（如 %lld、%@），杜绝硬编码英文。
持续集成与交付 (CI/CD)：
配置 GitHub Actions / Xcode Cloud，在每一次 PR/Commit 时自动化执行：
SwiftLint 代码规范扫描；
xcodebuild test 自动化单元测试；
TestFlight 自动打包与发布流水线。