import SwiftUI

struct EdgeCertificatesView: View {
    let zoneId: String
    
    @StateObject private var viewModel = EdgeCertificatesViewModel()
    
    var displayCertificates: [EdgeCertificateModel] {
        if !viewModel.hasFetchedData {
            return EdgeCertificateModel.dummyData
        }
        return viewModel.certificates
    }
    
    var body: some View {
        ZStack {
            Color(UIColor.systemGroupedBackground).edgesIgnoringSafeArea(.all)
            
            if let errorMessage = viewModel.errorMessage, viewModel.certificates.isEmpty && viewModel.hasFetchedData {
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 48))
                        .foregroundColor(.red)
                    Text(errorMessage)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.secondary)
                    Button("Retry") {
                        Task {
                            await viewModel.fetchCertificates(zoneId: zoneId)
                        }
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding()
            } else if viewModel.certificates.isEmpty && viewModel.hasFetchedData {
                EmptyStateView(
                    icon: "lock.shield",
                    title: "No Edge Certificates",
                    message: "No Edge Certificates found."
                )
            } else {
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(displayCertificates) { cert in
                            EdgeCertificateCardView(certificate: cert)
                        }
                        
                        Divider().padding(.vertical)
                        

                    }
                    .padding()
                    .redacted(reason: !viewModel.hasFetchedData ? .placeholder : [])
                    .disabled(!viewModel.hasFetchedData)
                }
                .refreshable {
                    await viewModel.fetchCertificates(zoneId: zoneId)
                }
            }
        }
        .navigationTitle("Edge Certificates")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            if viewModel.certificates.isEmpty {
                await viewModel.fetchCertificates(zoneId: zoneId)
            }
        }
    }
}

struct EdgeCertificateCardView: View {
    let certificate: EdgeCertificateModel
    
    var iconName: String {
        switch certificate.type.lowercased() {
        case "universal": return "globe"
        case "advanced": return "star.fill"
        case "custom": return "person.badge.key"
        default: return "seal.fill"
        }
    }
    
    var iconColor: Color {
        switch certificate.type.lowercased() {
        case "universal": return .blue
        case "advanced": return .purple
        case "custom": return .orange
        default: return .gray
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                ZStack {
                    iconColor.opacity(0.15)
                    Image(systemName: iconName)
                        .foregroundColor(iconColor)
                        .font(.system(size: 14, weight: .semibold))
                }
                .frame(width: 28, height: 28)
                .cornerRadius(6)
                
                Text(certificate.type.capitalized)
                    .font(.headline)
                
                Spacer()
                
                Text(certificate.status)
                    .font(.caption)
                    .fontWeight(.bold)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(certificate.status == "active" ? Color.green.opacity(0.1) : Color.gray.opacity(0.1))
                    .foregroundColor(certificate.status == "active" ? .green : .gray)
                    .cornerRadius(6)
            }
            
            Divider()
            
            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .top) {
                    Text("Hosts")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .frame(width: 80, alignment: .leading)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(certificate.hosts, id: \.self) { host in
                            Text(host)
                                .font(.subheadline)
                        }
                    }
                }
                
                HStack {
                    Text("Issuer")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .frame(width: 80, alignment: .leading)
                    Text(certificate.issuer)
                        .font(.subheadline)
                }
                
                HStack {
                    Text("Signature")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .frame(width: 80, alignment: .leading)
                    Text(certificate.signature)
                        .font(.system(.subheadline, design: .monospaced))
                }
                
                HStack {
                    Text("Expires")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .frame(width: 80, alignment: .leading)
                    Text(formatDate(certificate.expiresOn))
                        .font(.subheadline)
                }
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.03), radius: 8, x: 0, y: 4)
    }
    
    private func formatDate(_ dateString: String) -> String {
        if dateString == "N/A" { return dateString }
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        var date = formatter.date(from: dateString)
        if date == nil {
            formatter.formatOptions = [.withInternetDateTime]
            date = formatter.date(from: dateString)
        }
        guard let validDate = date else { return dateString }
        
        let displayFormatter = DateFormatter()
        displayFormatter.dateStyle = .medium
        displayFormatter.timeStyle = .none
        return displayFormatter.string(from: validDate)
    }
}
