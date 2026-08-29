import SwiftUI
import Network

struct DNSRecordFormView: View {
    @Environment(\.dismiss) var dismiss
    
    let viewModel: DNSRecordsViewModel
    let existingRecord: DNSRecord? // If nil, we are creating a new record
    
    @State private var type: String = "A"
    @State private var name: String = ""
    @State private var content: String = ""
    @State private var proxied: Bool = false
    @State private var ttl: Int = 1 // 1 means Auto in Cloudflare
    @State private var priority: String = "10" // Used for MX, SRV, URI, HTTPS
    @State private var comment: String = ""
    @State private var tagsText: String = ""
    
    // SRV specific
    @State private var srvService: String = "_sip"
    @State private var srvProto: String = "_tcp"
    @State private var srvWeight: String = "1"
    @State private var srvPort: String = "443"
    @State private var srvTarget: String = ""
    
    // CAA specific
    @State private var caaFlags: String = "0"
    @State private var caaTag: String = "issue"
    @State private var caaValue: String = ""
    
    // HTTPS / SVCB specific
    @State private var httpsTarget: String = "."
    @State private var httpsParams: String = "alpn=\"h3,h2\" port=443"
    
    @State private var isSaving = false
    @State private var errorMessage: String?
    
    enum FocusField {
        case name, content, comment, tags, priority, srvService, srvPort, srvWeight, srvTarget, caaFlags, caaValue, httpsTarget, httpsParams
    }
    @FocusState private var focusedField: FocusField?
    
    let recordTypes = ["A", "AAAA", "CNAME", "HTTPS", "SVCB", "TXT", "MX", "NS", "SRV", "CAA", "PTR", "CERT", "DNSKEY", "DS", "NAPTR", "SMIMEA", "SSHFP", "TLSA", "URI"]
    let ttlOptions = [
        (1, "Auto"),
        (120, "2 min"),
        (300, "5 min"),
        (3600, "1 hr"),
        (86400, "1 day")
    ]
    
    init(viewModel: DNSRecordsViewModel, existingRecord: DNSRecord? = nil) {
        self.viewModel = viewModel
        self.existingRecord = existingRecord
        
        if let record = existingRecord {
            _type = State(initialValue: record.type)
            _name = State(initialValue: record.name)
            _content = State(initialValue: record.content ?? "")
            _proxied = State(initialValue: record.proxied ?? false)
            _ttl = State(initialValue: record.ttl)
            _comment = State(initialValue: record.comment ?? "")
            _tagsText = State(initialValue: (record.tags ?? []).joined(separator: ", "))
            
            if let prio = record.priority {
                _priority = State(initialValue: String(prio))
            }
            
            if record.type == "SRV", let data = record.data {
                _srvService = State(initialValue: data.service ?? "")
                _srvProto = State(initialValue: data.proto ?? "")
                if let w = data.weight { _srvWeight = State(initialValue: String(w)) }
                if let p = data.port { _srvPort = State(initialValue: String(p)) }
                _srvTarget = State(initialValue: data.target ?? "")
            }
            if record.type == "CAA", let data = record.data {
                if let f = data.flags { _caaFlags = State(initialValue: String(f)) }
                _caaTag = State(initialValue: data.tag ?? "issue")
                _caaValue = State(initialValue: data.value ?? "")
            }
        }
    }
    
    var isProxySupported: Bool {
        return type == "A" || type == "AAAA" || type == "CNAME" || type == "HTTPS" || type == "SVCB"
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Record Details")) {
                    Picker("Type", selection: $type) {
                        ForEach(recordTypes, id: \.self) { t in
                            Text(t).tag(t)
                        }
                    }
                    .onChange(of: type) { _ in
                        if !isProxySupported {
                            proxied = false
                        }
                    }
                    
                    TextField("Name (e.g., @ or www)", text: $name)
                        .keyboardType(.URL)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .submitLabel(.next)
                        .focused($focusedField, equals: .name)
                        .onSubmit {
                            if type == "SRV" {
                                focusedField = .srvService
                            } else if type == "CAA" {
                                focusedField = .caaFlags
                            } else {
                                focusedField = .content
                            }
                        }
                    
                    if type == "SRV" {
                        TextField("Service (e.g., _sip)", text: $srvService)
                            .keyboardType(.asciiCapable)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .submitLabel(.next)
                            .focused($focusedField, equals: .srvService)
                            .onSubmit { focusedField = .priority }
                        Picker("Protocol", selection: $srvProto) {
                            Text("_tcp").tag("_tcp")
                            Text("_udp").tag("_udp")
                            Text("_tls").tag("_tls")
                        }
                        TextField("Priority (e.g., 10)", text: $priority)
                            .keyboardType(.numberPad)
                            .autocorrectionDisabled()
                            .submitLabel(.next)
                            .focused($focusedField, equals: .priority)
                            .onSubmit { focusedField = .srvWeight }
                        TextField("Weight (e.g., 5)", text: $srvWeight)
                            .keyboardType(.numberPad)
                            .autocorrectionDisabled()
                            .submitLabel(.next)
                            .focused($focusedField, equals: .srvWeight)
                            .onSubmit { focusedField = .srvPort }
                        TextField("Port (e.g., 443)", text: $srvPort)
                            .keyboardType(.numberPad)
                            .autocorrectionDisabled()
                            .submitLabel(.next)
                            .focused($focusedField, equals: .srvPort)
                            .onSubmit { focusedField = .srvTarget }
                        TextField("Target (e.g., example.com)", text: $srvTarget)
                            .keyboardType(.URL)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .submitLabel(.next)
                            .focused($focusedField, equals: .srvTarget)
                            .onSubmit { focusedField = .comment }
                    } else if type == "CAA" {
                        TextField("Flags (e.g., 0)", text: $caaFlags)
                            .keyboardType(.numberPad)
                            .autocorrectionDisabled()
                            .submitLabel(.next)
                            .focused($focusedField, equals: .caaFlags)
                        Picker("Tag", selection: $caaTag) {
                            Text("issue").tag("issue")
                            Text("issuewild").tag("issuewild")
                            Text("iodef").tag("iodef")
                        }
                        TextField("Value (e.g., letsencrypt.org)", text: $caaValue)
                            .keyboardType(.URL)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .submitLabel(.next)
                            .focused($focusedField, equals: .caaValue)
                            .onSubmit { focusedField = .comment }
                    } else if type == "HTTPS" || type == "SVCB" {
                        TextField("Priority (e.g. 1)", text: $priority)
                            .keyboardType(.numberPad)
                            .autocorrectionDisabled()
                            .submitLabel(.next)
                            .focused($focusedField, equals: .priority)
                        TextField("Target (e.g. . or domain.com)", text: $httpsTarget)
                            .keyboardType(.URL)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .submitLabel(.next)
                            .focused($focusedField, equals: .httpsTarget)
                        TextField("Value / Params (e.g. alpn=\"h3,h2\" port=443)", text: $httpsParams)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .submitLabel(.next)
                            .focused($focusedField, equals: .httpsParams)
                            .onSubmit { focusedField = .comment }
                    } else {
                        TextField("Content (e.g., 192.0.2.1)", text: $content)
                            .keyboardType(type == "A" || type == "AAAA" ? .numbersAndPunctuation : .URL)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .submitLabel(.next)
                            .focused($focusedField, equals: .content)
                            .onSubmit {
                                if type == "MX" || type == "URI" {
                                    focusedField = .priority
                                } else {
                                    focusedField = .comment
                                }
                            }
                    }
                }
                
                Section(header: Text("Configuration")) {
                    if type == "MX" || type == "URI" {
                        TextField("Priority", text: $priority)
                            .keyboardType(.numberPad)
                            .autocorrectionDisabled()
                            .submitLabel(.next)
                            .focused($focusedField, equals: .priority)
                            .onSubmit { focusedField = .comment }
                    }
                    
                    if isProxySupported {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                HStack(spacing: 8) {
                                    Text("Proxy Status")
                                        .font(.body.weight(.medium))
                                    CloudnsBadge(proxied ? .proxied : .dnsOnly, isCompact: true)
                                }
                                Text(proxied ? "Accelerated & Protected by Cloudflare" : "Bypasses Cloudflare proxy")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Toggle(isOn: $proxied) { }
                                .labelsHidden()
                        }
                    }
                    
                    Picker("TTL", selection: $ttl) {
                        ForEach(ttlOptions, id: \.0) { option in
                            Text(option.1).tag(option.0)
                        }
                    }
                }
                
                Section(header: Text("Tags & Comments (Optional)")) {
                    TextField("Tags (comma separated, e.g. prod, api)", text: $tagsText)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .submitLabel(.next)
                        .focused($focusedField, equals: .tags)
                        .onSubmit { focusedField = .comment }
                    
                    TextField("Add a note about this record", text: $comment)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .submitLabel(.done)
                        .focused($focusedField, equals: .comment)
                        .onSubmit {
                            focusedField = nil
                            if !name.isEmpty && !isSaving {
                                Task { await saveRecord() }
                            }
                        }
                }
                
                if let error = errorMessage {
                    Section {
                        Text(error)
                            .foregroundStyle(.red)
                            .font(.caption)
                    }
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle(existingRecord == nil ? "Add Record" : "Edit Record")
            .navigationBarTitleDisplayMode(.inline)
            .presentationDragIndicator(.visible)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        HapticManager.impact(.medium)
                        Task {
                            await saveRecord()
                        }
                    }
                    .disabled(name.isEmpty || isSaving)
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .interactiveDismissDisabled(isSaving)
            .overlay {
                if isSaving {
                    ZStack {
                        Color.black.opacity(0.3).ignoresSafeArea()
                        ProgressView("Saving...")
                            .padding()
                            .background(Color(UIColor.secondarySystemBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    }
                }
            }
            .toastContainer()
        }
    }
    
    private func saveRecord() async {
        if type == "A" {
            if IPv4Address(content) == nil {
                errorMessage = "Invalid IPv4 address format."
                return
            }
        } else if type == "AAAA" {
            if IPv6Address(content) == nil {
                errorMessage = "Invalid IPv6 address format."
                return
            }
        }
        
        isSaving = true
        errorMessage = nil
        
        var payloadData: DNSRecordData?
        var finalContent: String? = content
        var finalPriority: Int?
        
        if type == "SRV" {
            let p = Int(priority) ?? 10
            payloadData = DNSRecordData(
                service: srvService,
                proto: srvProto,
                name: name,
                priority: p,
                weight: Int(srvWeight) ?? 1,
                port: Int(srvPort) ?? 443,
                target: srvTarget
            )
            finalContent = nil
            finalPriority = p
        } else if type == "CAA" {
            payloadData = DNSRecordData(
                flags: Int(caaFlags) ?? 0,
                tag: caaTag,
                value: caaValue
            )
            finalContent = nil
        } else if type == "HTTPS" || type == "SVCB" {
            let p = Int(priority) ?? 1
            finalPriority = p
            finalContent = "\(p) \(httpsTarget) \(httpsParams)".trimmingCharacters(in: .whitespaces)
        } else if type == "MX" || type == "URI" {
            finalPriority = Int(priority) ?? 10
        }
        
        let tagsList = tagsText
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        
        let payload = DNSRecordPayload(
            type: type,
            name: name,
            content: finalContent,
            ttl: ttl,
            proxied: isProxySupported ? proxied : nil,
            priority: finalPriority,
            comment: comment.isEmpty ? nil : comment,
            tags: tagsList.isEmpty ? nil : tagsList,
            data: payloadData
        )
        
        do {
            if let existingRecord = existingRecord {
                try await viewModel.updateRecord(recordId: existingRecord.id, payload: payload)
                ToastManager.shared.showSuccess("DNS Record Updated", message: "\(name) (\(type))")
            } else {
                try await viewModel.addRecord(payload: payload)
                ToastManager.shared.showSuccess("DNS Record Created", message: "\(name) (\(type))")
            }
            dismiss()
        } catch {
            errorMessage = APIError.formatCloudflareError(error.localizedDescription)
        }
        
        isSaving = false
    }
}
