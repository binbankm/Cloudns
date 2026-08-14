# Cloudns 🌐

[English](README.md) | **简体中文**

> **Cloudns** 是一款专为 Cloudflare 极客、开发者及运维工程师打造的新一代高性能原生 iOS 客户端。让你随时随地在掌中轻松管理 DNS 域名解析、WAF 安全防御、边缘重写规则、Serverless Workers、Pages 自动化部署、KV 分布式存储以及全套离线网络诊断工具箱。

---

## ✨ 功能亮点

### 🌐 DNS 与域名管理
- **全类型解析记录支持**：支持 `A`、`AAAA`、`CNAME`、`TXT`、`MX`、`NS`、`SRV`、`CAA`、`HTTPS`、`SVCB` 等全部常见记录，一键切换 Cloudflare 橙色云朵代理状态（Proxied）。
- **DNSSEC 与名称服务器**：支持一键开启 DNSSEC 安全签名、生成 DS 摘要记录，并支持 Nameservers 一键复制与配置校验。
- **批量导入 / 导出**：支持 BIND 格式 Zone 配置文件批量导出备份与快速恢复。
- **域名实时数据看板**：可视化监控请求总量、带宽吞吐量、缓存命中率（Cache Hit Ratio）及威胁拦截走势。

### ⚡ Workers 与 Serverless 边缘计算
- **超高性能代码查看与编辑器**：采用 iOS 原生 UIKit 视口虚拟化渲染引擎（TextKit Viewport Virtualization），即使面对 **10 万行以上** 的超大型 Minified JS/Bundle 代码，也能秒级加载打开、120Hz 满帧顺畅滑动，支持自动折行与横向滚动自由切换。
- **多 ESM 模块智能识别**：自动解析并呈现 Worker 包含的多个 ES 模块，支持多 Tab 自由切换与代码导出。
- **Live Tail 实时事件流日志**：内置 WebSocket 实时流监听，实时输出 Console Log、异常堆栈（Exception Stack）与 Request/Response 详细参数。
- **Cron 定时任务触发器**：内置 10+ 种常用标准定时预设，支持一键增删与自定义 Cron 表达式。
- **安全热部署**：支持在手机端直接编辑代码并执行安全部署，自动保留已配置的全部 KV/R2 资源绑定与环境变量密钥（`bindings_inherit`）。
- **子域名与路由管理**：支持一键开关 `workers.dev` 访问，并支持自定义路由（Route Patterns）与区域服务绑定。

### 🚀 Cloudflare Pages 静态与全栈托管
- **项目与部署流水线**：直观查看 Pages 项目部署状态、生产环境与预览环境分支配置。
- **自定义域名绑定**：支持主域名（Apex）与子域名（Subdomain）绑定，实时检测 DNS CNAME 解析与 SSL 证书就绪状态。
- **构建配置编辑器**：可视化修改自动化构建命令（Build Command）、输出目录（Output Directory）、项目根路径（Root Directory）与环境变量。
- **一键回滚与推向生产**：支持将任意历史版本一键回滚/推向生产环境（Rollback / Promote to Production），支持构建重试（Retry）。
- **全功能终端构建日志**：内置极客风格终端日志查看器，支持 ANSI 色彩高亮与行数统计。

### 🛡️ WAF 安全防御与边缘规则
- **WAF 自定义防火墙与速率限制**：配置高级安全表达式、拦截/质询（JS Challenge / Managed Challenge）策略与请求频次阈值。
- **IP 访问规则**：支持单 IP、CIDR 网段及国家级地理位置放行/阻断配置。
- **高级规则引擎**：全面支持转换规则（Transform Rules，含 URL 重写与请求头修改）、重定向规则（Redirect Rules）与页面缓存规则（Cache Rules）。
- **边缘 SSL 证书**：实时查看 Universal SSL 状态、证书链有效期及加密套件。

### 🗄️ 分布式存储与 AI 生态
- **KV 数据库浏览器**：直观管理命名空间、键列表模糊搜索、实时查看与编辑 JSON/文本内容、设置 TTL 自动过期。
- **R2 对象存储**：存储桶管理、对象文件上传与下载、存储空间用量统计。
- **Workers AI & AI Gateway**：直接在移动端体验云端大语言模型与多模态视觉推理。

### 🧰 免登录开发者工具箱
*无需 Cloudflare 登录，在仪表盘即可一键即用：*
- **WHOIS / RDAP 查询**：基于 IANA 官方 RDAP 协议通过加密 HTTPS 查询全球域名注册商、注册时间、到期倒计时天数与权威 DNS 记录。
- **Cloudflare Edge Trace**：实时诊断当前网络直连的 Edge PoP 数据中心、客户端出口 IP、数据中心代码及 TLS 协议。
- **1.1.1.1 DoH Dig 工具**：基于 Cloudflare 1.1.1.1 官方公共 DNS 进行低延迟安全域名解析与响应耗时诊断。
- **SSL 证书链深度检测**：查看服务器完整证书链、SAN 扩展域名列表与证书剩余有效天数。
- **官方 IP 网段与 Nginx 配置**：实时获取 Cloudflare 官方 IPv4 / IPv6 网段，一键生成 `set_real_ip_from` 配置。
- **IP 与 ASN 归属地诊断**：全球 IP 定位、ASN 自治系统编号与运营商查询。

---

## 🎨 设计规范与交互体验

- **严格遵循 Apple 人机交互指南 (HIG)**：纯原生系统控件、卡片式分组列表、平滑过渡动画与触感反馈。
- **非阻塞骨架屏 (Skeleton Loading)**：精细化骨架屏加载动画，避免列表布局抖动，搜索框常驻可即时交互。
- **全局居中空状态**：标准化无数据、搜索无匹配、离线与错误重试视图。
- **全链路 Toast 触达**：针对复制、部署、增删、回滚等操作提供即时轻量提示。
- **100% 完整中英双语国际化**：全项目覆盖 1,230+ 本地化词条，严丝合缝。

---

## 🛠️ 技术架构

- **最低系统要求**：iOS 16.0+
- **编程语言**：Swift 6（完全符合 Strict Concurrency 并发模型与 Sendable 契约）
- **界面框架**：SwiftUI + UIKit Representables（针对超大代码进行底层排版虚拟化）
- **网络底层**：`URLSession` + `async/await` Actor + WebSocket（`URLSessionWebSocketTask`）
- **状态管理**：`@MainActor` `ObservableObject` 响应式流

---

## 📦 源码编译指南

### 环境准备
- macOS 14.0+
- Xcode 16.0+
- iOS 16.0+ 模拟器或真实设备

### 快速开始

1. 克隆代码仓库：
   ```bash
   git clone https://github.com/binbankm/Cloudns.git
   cd Cloudns
   ```

2. 打开 Xcode 工程：
   ```bash
   open Cloudns.xcodeproj
   ```

3. 运行项目：
   - 选择 `Cloudns` Scheme。
   - 选择目标模拟器或 iPhone 真机。
   - 按下快捷键 `Cmd + R` 即可编译并运行。

---

## 📄 开源许可证

本项目基于 [MIT License](LICENSE) 协议开源。
