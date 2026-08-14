# Cloudns 🌐

**English** | [简体中文](README_zh.md)

> **Cloudns** is a next-generation, high-performance native iOS client designed for Cloudflare power users, developers, and system administrators. Manage DNS, Security, Edge Rules, Serverless Workers, Pages deployments, KV storage, and developer diagnostics right from your pocket.

---

## ✨ Features Overview

### 🌐 DNS & Domain Management
- **Full DNS Records Support**: Manage `A`, `AAAA`, `CNAME`, `TXT`, `MX`, `NS`, `SRV`, `CAA`, `HTTPS`, and `SVCB` records with one-tap Cloudflare proxy status toggle.
- **DNSSEC & Nameservers**: Instant DNSSEC validation with DS record generator and one-tap nameserver clipboard export.
- **Batch Export / Import**: Backup zone configurations and quickly import BIND zone files.
- **Zone Analytics**: Real-time traffic analytics, request count, bandwidth, and edge cache hit ratio.

### ⚡ Workers & Serverless Compute
- **Ultra High-Performance Code Viewer & Editor**: Powered by native UIKit viewport virtualization (`UITextView`), effortlessly opening and scrolling 100,000+ lines of bundle code with zero lag and 120fps smoothness.
- **Multi-Module ESM Support**: Inspect and switch between multiple ES modules within a single Worker.
- **Live Tail Logs**: Real-time WebSocket event streaming with instant log levels, exceptions, and event detail inspectors.
- **Cron Triggers Management**: Add, view, and delete scheduled Cron triggers with 10+ standard presets.
- **Safe Code Deployment**: In-app code editing and instant deployment preserving all resource bindings and environment secrets.
- **Subdomain Routing**: Toggle `workers.dev` routing and custom route patterns.

### 🚀 Cloudflare Pages
- **Project & Deployment Pipelines**: Manage Pages projects, preview deployment states, and explore deployment history.
- **Custom Domains**: Connect apex domains or subdomains with automatic DNS verification and SSL certificate tracking.
- **Build Configuration**: Modify build commands, output directories, root paths, and environment settings.
- **Rollback & Retry**: Roll back production traffic to any historical deployment build with a single tap, or trigger immediate build retries.
- **Terminal Build Logs**: Integrated terminal-styled build log viewer with auto-scroll and detailed step inspects.

### 🛡️ Security & Edge Rules
- **WAF Custom Rules & Rate Limiting**: Configure complex firewall expressions, rate limit actions, and thresholds.
- **IP Access Rules**: Manage IP, IP range (CIDR), and country access rules (Allow, Block, Challenge, JS Challenge).
- **Rules Engines**: Full support for Transform Rules (URL rewrite, HTTP header modification), Redirect Rules, and Cache Rules.
- **Edge Certificates**: View Universal SSL status, custom certificates, and cipher suites.

### 🗄️ Storage & Workers AI
- **KV Browser**: Browse KV namespaces, search keys, inspect JSON/text values, and manage TTL expirations.
- **R2 Storage**: Bucket browsing, storage stats, and asset management.
- **Workers AI & AI Gateway**: Interact with serverless LLM and vision models directly from your iPhone.

### 🧰 Offline Developer Diagnostics
*Zero account required — available directly on the dashboard:*
- **WHOIS & RDAP Lookup**: Encrypted HTTPS querying against IANA RDAP for domain registration, expiration countdowns, and nameservers.
- **Edge Trace**: Instant Cloudflare Edge PoP data center, client IP, and TLS protocol diagnosis.
- **1.1.1.1 DNS Dig**: Query DoH (DNS-over-HTTPS) records with response timing metrics.
- **SSL Certificate Inspector**: Inspect complete TLS certificate chains, SANs, and expiry dates.
- **Cloudflare IP Ranges**: Official IPv4/IPv6 CIDRs and one-tap Nginx real-ip config generator.
- **IP & ASN Geolocation**: AS network and geolocation lookup.

---

## 🎨 Design Philosophy & UX

- **Apple Human Interface Guidelines (HIG)**: Clean, modern iOS native navigation, grouped lists, and fluid animations.
- **Non-blocking Skeleton Loading**: Seamless skeleton loaders that prevent layout shifts and keep search bars permanently accessible.
- **Centered Empty States**: Standardized empty states, offline indicators, and search placeholders.
- **Global Toast Feedback**: Non-intrusive notification toasts for copies, deployments, updates, and deletes.
- **Full I18n Localization**: 100% bilingual support for English (`en`) and Simplified Chinese (`zh-Hans`).

---

## 🛠️ Architecture & Tech Stack

- **Platform**: iOS 16.0+
- **Language**: Swift 6 (Strict Concurrency & Sendable compliant)
- **UI Framework**: SwiftUI + UIKit Representables (for high-performance text rendering)
- **Networking**: `URLSession` + `async/await` actors + WebSocket (`URLSessionWebSocketTask`)
- **State Management**: `@MainActor` `ObservableObject` ViewModels with reactive published streams

---

## 📦 Building from Source

### Prerequisites
- macOS 14.0+
- Xcode 16.0+
- iOS 16.0+ Simulator or physical device

### Build Steps

1. Clone the repository:
   ```bash
   git clone https://github.com/binbankm/Cloudns.git
   cd Cloudns
   ```

2. Open the project in Xcode:
   ```bash
   open Cloudns.xcodeproj
   ```

3. Build and run:
   - Select the `Cloudns` scheme.
   - Choose your target device or simulator.
   - Press `Cmd + R` to build and run.

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
