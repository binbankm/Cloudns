import SwiftUI
import UIKit

// MARK: - DNSRecordRow (Cozy DNS Squircle Card)

struct DNSRecordRow: View {
    let record: DNSRecord
    let isUpdating: Bool
    let onToggleProxy: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void

    @State private var hasCopied: Bool = false

    private var typeBadgeColor: Color {
        switch record.type.uppercased() {
        case "A", "AAAA":
            GentleColor.accent
        case "CNAME":
            Color(red: 0.55, green: 0.45, blue: 0.85) // Soft Violet
        case "TXT":
            GentleColor.textSecondary
        case "MX":
            GentleColor.apricotGold
        case "NS":
            GentleColor.sageGreen
        case "CAA", "SRV":
            GentleColor.statusDanger
        default:
            GentleColor.textSecondary
        }
    }

    private var isProxied: Bool {
        record.proxied ?? false
    }

    private var isProxiable: Bool {
        record.proxiable ?? false
    }

    private var ttlDisplay: String {
        if isProxied || record.ttl == 1 {
            return String(localized: "Auto")
        }
        if record.ttl < 60 {
            return "\(record.ttl)s"
        }
        if record.ttl < 3600 {
            return "\(record.ttl / 60)m"
        }
        if record.ttl < 86400 {
            return "\(record.ttl / 3600)h"
        }
        return "\(record.ttl / 86400)d"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: GentleSpacing.xs) {
            // MARK: - Header: Type Badge & Full Name

            HStack(alignment: .center, spacing: GentleSpacing.sm) {
                // Type Badge
                Text(record.type)
                    .font(GentleTypography.captionSmall)
                    .fontWeight(.bold)
                    .foregroundStyle(typeBadgeColor)
                    .padding(.horizontal, GentleSpacing.xs)
                    .padding(.vertical, GentleSpacing.micro)
                    .background(typeBadgeColor.opacity(0.14))
                    .clipShape(RoundedRectangle(cornerRadius: GentleCornerRadius.xs, style: .continuous))

                // Record Name (保留原始字体 cardTitle，整行展示，绝不截断)
                Text(record.name)
                    .font(GentleTypography.cardTitle)
                    .foregroundStyle(GentleColor.textPrimary)
                    .lineLimit(2)
                    .truncationMode(.tail)

                Spacer(minLength: 0)
            }

            // MARK: - Body: Record Content (IP/Target/Value) with Dedicated Copy Icon Button

            HStack(alignment: .center, spacing: GentleSpacing.xs) {
                Text(record.content ?? "")
                    .font(GentleTypography.codeValue)
                    .foregroundStyle(GentleColor.textPrimary.opacity(0.9))
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)

                Spacer(minLength: GentleSpacing.xs)

                Button {
                    copyContent()
                } label: {
                    Image(systemName: hasCopied ? "checkmark" : "doc.on.doc")
                        .font(GentleTypography.captionSmall)
                        .foregroundStyle(hasCopied ? GentleColor.sageGreen : GentleColor.textSecondary)
                        .frame(width: 26, height: 26)
                        .background(hasCopied ? GentleColor.sageGreen.opacity(0.12) : Color.clear)
                        .clipShape(RoundedRectangle(cornerRadius: GentleCornerRadius.xs, style: .continuous))
                        .contentShape(Rectangle())
                        .animation(GentleAnimation.spring, value: hasCopied)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(Text("Copy Content"))
            }
            .padding(.horizontal, GentleSpacing.sm)
            .padding(.vertical, GentleSpacing.xxs)
            .background(GentleColor.cardSurfaceSecondary.opacity(0.6))
            .clipShape(RoundedRectangle(cornerRadius: GentleCornerRadius.sm, style: .continuous))

            // MARK: - Footer: TTL, Priority, Comments & Cloud Proxy Button

            HStack(alignment: .center, spacing: GentleSpacing.sm) {
                // TTL
                HStack(spacing: GentleSpacing.xxs) {
                    Image(systemName: "clock")
                        .font(GentleTypography.captionSmall)
                    Text("TTL: \(ttlDisplay)")
                        .font(GentleTypography.caption)
                }
                .foregroundStyle(GentleColor.textSecondary)

                // Priority for MX / SRV
                if let prio = record.priority {
                    HStack(spacing: GentleSpacing.xxs) {
                        Image(systemName: "flag")
                            .font(GentleTypography.captionSmall)
                        Text("Priority: \(prio)")
                            .font(GentleTypography.caption)
                    }
                    .foregroundStyle(GentleColor.textSecondary)
                }

                // Comment if exists
                if let comment = record.comment, !comment.isEmpty {
                    HStack(spacing: GentleSpacing.xxs) {
                        Image(systemName: "text.bubble")
                            .font(GentleTypography.captionSmall)
                        Text(comment)
                            .font(GentleTypography.caption)
                            .lineLimit(1)
                    }
                    .foregroundStyle(GentleColor.textSecondary)
                }

                Spacer(minLength: GentleSpacing.xs)

                // 云朵代理状态（方案 1：纯净无框轻图标，与上方复制按钮上下严格对齐）
                proxyCloudButton
                    .padding(.trailing, GentleSpacing.sm)
            }
        }
        .gentleCardStyle(cornerRadius: GentleCornerRadius.card, padding: GentleSpacing.md)
        .contextMenu {
            Button {
                copyContent()
            } label: {
                Label("Copy Content", systemImage: "doc.on.doc")
            }

            Button {
                UIPasteboard.general.string = record.name
                GentleHaptics.light()
            } label: {
                Label("Copy Name", systemImage: "link")
            }

            Button {
                onEdit()
            } label: {
                Label("Edit Record", systemImage: "pencil")
            }

            Button(role: .destructive) {
                onDelete()
            } label: {
                Label("Delete Record", systemImage: "trash")
            }
        }
    }

    // MARK: - Proxy Cloud Button (Style 1: Borderless & Pure, Vertically Aligned)

    @ViewBuilder
    private var proxyCloudButton: some View {
        if isProxiable {
            Button {
                onToggleProxy()
            } label: {
                ZStack {
                    if isUpdating {
                        ProgressView()
                            .scaleEffect(0.65)
                            .frame(width: 16, height: 16)
                    } else {
                        Image(systemName: isProxied ? "cloud.fill" : "cloud")
                            .font(GentleTypography.subheadlineSemibold)
                            .foregroundStyle(isProxied ? GentleColor.statusProxied : GentleColor.textSecondary)
                    }
                }
                .frame(width: 26, height: 26)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .disabled(isUpdating)
            .animation(GentleAnimation.spring, value: isProxied)
            .accessibilityLabel(isProxied ? Text("Proxied") : Text("DNS Only"))
        }
    }

    private func copyContent() {
        guard let content = record.content, !content.isEmpty else { return }
        UIPasteboard.general.string = content
        GentleHaptics.light()
        withAnimation(GentleAnimation.spring) {
            hasCopied = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) {
            withAnimation(GentleAnimation.spring) {
                hasCopied = false
            }
        }
    }
}
