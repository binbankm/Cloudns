import SwiftUI

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
                        .font(.body.monospacedDigit())
                        .foregroundStyle(.primary)
                }
                
                LabeledContent("Logging") {
                    Text(gateway.collectLogs == true ? "Enabled" : "Disabled")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(gateway.collectLogs == true ? .green : .secondary)
                }
                
                if let created = gateway.createdOn {
                    LabeledContent("Created") {
                        Text(DateFormatters.formatISO8601ToDisplay(created, style: DateFormatters.dateOnly))
                            .font(.subheadline)
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
                    HapticManager.impact(.light)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text(universalEndpoint)
                        .font(.caption.monospaced())
                        .foregroundStyle(.blue)
                        .lineLimit(2)
                        .padding(.vertical, 4)
                    
                    Button {
                        UIPasteboard.general.string = universalEndpoint
                        HapticManager.notification(.success)
                        ToastManager.shared.showCopied("Endpoint URL copied")
                    } label: {
                        HStack {
                            Image(systemName: "doc.on.doc").font(.subheadline)
                            Text("Copy Base URL")
                        }
                        .font(.subheadline.weight(.semibold))
                    }
                    .buttonStyle(.bordered)
                }
                .padding(.vertical, 2)
            }
            
            // MARK: - Integration Code Examples
            Section(header: Text("Quick Integration Snippets")) {
                Picker("Language", selection: $selectedCodeLanguage) {
                    Text("cURL").tag("curl")
                    Text("Python").tag("python")
                    Text("Node.js").tag("node")
                }
                .pickerStyle(.segmented)
                .padding(.vertical, 2)
                .onChange(of: selectedCodeLanguage) { _ in
                    HapticManager.impact(.light)
                }
                
                VStack(alignment: .leading, spacing: 6) {
                    ScrollView(.horizontal) {
                        Text(codeSnippet)
                            .font(.caption2.monospaced())
                            .foregroundStyle(.primary)
                            .padding(.vertical, 4)
                    }
                    .scrollIndicators(.hidden)
                    
                    Button {
                        UIPasteboard.general.string = codeSnippet
                        HapticManager.notification(.success)
                        ToastManager.shared.showCopied("Code snippet copied")
                    } label: {
                        Label("Copy Code", systemImage: "doc.on.doc")
                            .font(.caption.weight(.semibold))
                    }
                }
                .padding(.vertical, 4)
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
