import SwiftUI

// MARK: - AIGatewayDetailView
// Apple HIG Compliant AI Gateway Endpoint & Code Generator

struct AIGatewayDetailView: View {
    let accountId: String
    let gateway: AIGateway
    
    @State private var selectedProvider = "openai"
    @State private var selectedCodeLanguage = "curl"
    
    let providers: [(id: String, name: String, icon: String)] = [
        ("openai", "OpenAI", "brain"),
        ("anthropic", "Anthropic", "character.bubble"),
        ("workers-ai", "Workers AI", "bolt.fill"),
        ("huggingface", "Hugging Face", "face.smiling"),
        ("replicate", "Replicate", "cube.transparent")
    ]
    
    private var universalEndpoint: String {
        "https://gateway.ai.cloudflare.com/v1/\(accountId)/\(gateway.id)/\(selectedProvider)"
    }
    
    var body: some View {
        List {
            // MARK: - Overview
            Section(header: Text("Gateway Overview")) {
                LabeledContent("Gateway Slug") {
                    Text(gateway.id)
                        .font(HIGTypography.body.monospacedDigit())
                        .foregroundStyle(.primary)
                }
                
                LabeledContent("Logging") {
                    Text(gateway.collectLogs == true ? "Enabled" : "Disabled")
                        .font(HIGTypography.subheadline.weight(.medium))
                        .foregroundStyle(gateway.collectLogs == true ? HIGColors.success : .secondary)
                }
                
                if let created = gateway.createdOn, let date = DateFormatters.parseISO8601(created) {
                    LabeledContent("Created") {
                        Text(date.displayFormatted(date: .abbreviated, time: .omitted))
                            .font(HIGTypography.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            
            // MARK: - Universal AI Endpoint Generator
            Section(
                header: Text("Universal AI Endpoint"),
                footer: Text("Route requests through this endpoint to get caching, rate limiting, and analytics.")
            ) {
                Picker("Provider", selection: $selectedProvider) {
                    ForEach(providers, id: \.id) { p in
                        Label(p.name, systemImage: p.icon).tag(p.id)
                    }
                }
                .onChange(of: selectedProvider) { _ in
                    HIGFeedback.impact(.light)
                }
                
                VStack(alignment: .leading, spacing: HIGTokens.Spacing.sm) {
                    Text(universalEndpoint)
                        .font(HIGTypography.caption.monospaced())
                        .foregroundStyle(Color.higAccent)
                        .lineLimit(2)
                        .padding(.vertical, HIGTokens.Spacing.xxs)
                    
                    Button {
                        UIPasteboard.general.string = universalEndpoint
                        ToastManager.shared.showCopied("Base URL Copied")
                        HIGFeedback.copied()
                    } label: {
                        HStack(spacing: HIGTokens.Spacing.xs) {
                            Image(systemName: "doc.on.doc")
                                .font(HIGTypography.subheadline)
                            Text("Copy Base URL")
                        }
                        .font(HIGTypography.subheadline.weight(.semibold))
                    }
                    .buttonStyle(.bordered)
                    .higTouchTarget(44)
                }
                .padding(.vertical, HIGTokens.Spacing.xxs)
            }
            
            // MARK: - Integration Code Examples
            Section(header: Text("Quick Integration Snippets")) {
                Picker("Language", selection: $selectedCodeLanguage) {
                    Text("cURL").tag("curl")
                    Text("Python").tag("python")
                    Text("Node.js").tag("node")
                }
                .pickerStyle(.segmented)
                .padding(.vertical, HIGTokens.Spacing.xxs)
                .onChange(of: selectedCodeLanguage) { _ in
                    HIGFeedback.impact(.light)
                }
                
                VStack(alignment: .leading, spacing: HIGTokens.Spacing.xs) {
                    ScrollView(.horizontal) {
                        Text(verbatim: codeSnippet)
                            .font(HIGTypography.caption2.monospaced())
                            .foregroundStyle(.primary)
                            .padding(.vertical, HIGTokens.Spacing.xxs)
                    }
                    .scrollIndicators(.hidden)
                    
                    Button {
                        UIPasteboard.general.string = codeSnippet
                        ToastManager.shared.showCopied("Code Snippet Copied")
                        HIGFeedback.copied()
                    } label: {
                        Label("Copy Code", systemImage: "doc.on.doc")
                            .font(HIGTypography.caption.weight(.semibold))
                    }
                    .higTouchTarget(44)
                }
                .padding(.vertical, HIGTokens.Spacing.xxs)
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle(gateway.id)
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private var codeSnippet: String {
        if selectedProvider == "openai" {
            switch selectedCodeLanguage {
            case "curl":
                return """
                curl \(universalEndpoint)/chat/completions \\
                  -H "Content-Type: application/json" \\
                  -H "Authorization: Bearer $OPENAI_API_KEY" \\
                  -d '{
                    "model": "gpt-4o",
                    "messages": [{"role": "user", "content": "Hello via AI Gateway!"}]
                  }'
                """
            case "python":
                return """
                from openai import OpenAI

                client = OpenAI(
                    base_url="\(universalEndpoint)",
                    api_key=os.environ.get("OPENAI_API_KEY")
                )

                response = client.chat.completions.create(
                    model="gpt-4o",
                    messages=[{"role": "user", "content": "Hello!"}]
                )
                print(response.choices[0].message.content)
                """
            case "node":
                return """
                import OpenAI from "openai";

                const openai = new OpenAI({
                  baseURL: "\(universalEndpoint)",
                  apiKey: process.env.OPENAI_API_KEY,
                });

                const completion = await openai.chat.completions.create({
                  model: "gpt-4o",
                  messages: [{ role: "user", content: "Hello!" }],
                });
                console.log(completion.choices[0].message.content);
                """
            default: return ""
            }
        } else {
            return """
            curl \(universalEndpoint)/v1/messages \\
              -H "Content-Type: application/json" \\
              -H "x-api-key: $ANTHROPIC_API_KEY" \\
              -H "anthropic-version: 2023-06-01" \\
              -d '{
                "model": "claude-3-5-sonnet-20241022",
                "max_tokens": 1024,
                "messages": [{"role": "user", "content": "Hello via Gateway!"}]
              }'
            """
        }
    }
}
