import SwiftUI

struct DNSRecordFormView: View {
    @Environment(\.dismiss) var dismiss
    
    let viewModel: DNSRecordsViewModel
    let existingRecord: DNSRecord? // If nil, we are creating a new record
    
    @State private var type: String = "A"
    @State private var name: String = ""
    @State private var content: String = ""
    @State private var proxied: Bool = false
    @State private var ttl: Int = 1 // 1 means Auto in Cloudflare
    @State private var priority: String = "10" // Used for MX, SRV, URI
    @State private var comment: String = ""
    
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
    
    @State private var isSaving = false
    @State private var errorMessage: String?
    
    let recordTypes = ["A", "AAAA", "CNAME", "TXT", "MX", "NS", "SRV", "CAA", "PTR", "CERT", "DNSKEY", "DS", "NAPTR", "SMIMEA", "SSHFP", "TLSA", "URI"]
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
        return type == "A" || type == "AAAA" || type == "CNAME"
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Record Details")) {
                    Picker("Type", selection: $type) {
                        ForEach(recordTypes, id: \.self) { t in
                            Text(t).tag(t)
                        }
                    }
                    .onChange(of: type) { newValue in
                        if !isProxySupported {
                            proxied = false
                        }
                    }
                    
                    TextField("Name (e.g., @ or www)", text: $name)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                    
                    if type == "SRV" {
                        TextField("Service (e.g., _sip)", text: $srvService)
                            .autocapitalization(.none)
                        Picker("Protocol", selection: $srvProto) {
                            Text("_tcp").tag("_tcp")
                            Text("_udp").tag("_udp")
                            Text("_tls").tag("_tls")
                        }
                        TextField("Priority (e.g., 10)", text: $priority).keyboardType(.numberPad)
                        TextField("Weight (e.g., 5)", text: $srvWeight).keyboardType(.numberPad)
                        TextField("Port (e.g., 443)", text: $srvPort).keyboardType(.numberPad)
                        TextField("Target (e.g., example.com)", text: $srvTarget)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                    } else if type == "CAA" {
                        TextField("Flags (e.g., 0)", text: $caaFlags).keyboardType(.numberPad)
                        Picker("Tag", selection: $caaTag) {
                            Text("issue").tag("issue")
                            Text("issuewild").tag("issuewild")
                            Text("iodef").tag("iodef")
                        }
                        TextField("Value (e.g., letsencrypt.org)", text: $caaValue)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                    } else {
                        TextField("Target (IPv4, IPv6, or domain)", text: $content)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                        
                        if type == "MX" || type == "URI" {
                            TextField("Priority (e.g., 10)", text: $priority)
                                .keyboardType(.numberPad)
                        }
                    }
                }
                
                Section(header: Text("Cloudflare Settings")) {
                    if isProxySupported {
                        Toggle(isOn: $proxied) {
                            HStack {
                                Image(systemName: "cloud.fill")
                                    .foregroundColor(proxied ? .orange : .gray)
                                VStack(alignment: .leading) {
                                    Text("Proxy status")
                                    Text(proxied ? "Proxied" : "DNS only")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                    
                    Picker("TTL", selection: $ttl) {
                        ForEach(ttlOptions, id: \.0) { option in
                            Text(option.1).tag(option.0)
                        }
                    }
                }
                
                Section(header: Text("Notes")) {
                    TextField("Comment (Optional)", text: $comment)
                }
                
                if let errorMessage = errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.callout)
                    }
                }
            }
            .navigationTitle(existingRecord == nil ? "Add Record" : "Edit Record")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        Task {
                            await saveRecord()
                        }
                    }
                    .disabled(name.isEmpty || isSaving)
                }
            }
            .overlay {
                if isSaving {
                    ZStack {
                        Color.black.opacity(0.3).edgesIgnoringSafeArea(.all)
                        ProgressView("Saving...")
                            .padding()
                            .background(Color(UIColor.secondarySystemBackground))
                            .cornerRadius(10)
                    }
                }
            }
        }
    }
    
    private func saveRecord() async {
        isSaving = true
        errorMessage = nil
        
        var payloadData: DNSRecordData? = nil
        var finalContent: String? = content
        var finalPriority: Int? = nil
        
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
        } else if type == "MX" || type == "URI" {
            finalPriority = Int(priority) ?? 10
        }
        
        let payload = DNSRecordPayload(
            type: type,
            name: name,
            content: finalContent,
            ttl: ttl,
            proxied: isProxySupported ? proxied : false,
            priority: finalPriority,
            comment: comment.isEmpty ? nil : comment,
            data: payloadData
        )
        
        do {
            if let existingRecord = existingRecord {
                try await viewModel.updateRecord(recordId: existingRecord.id, payload: payload)
            } else {
                try await viewModel.addRecord(payload: payload)
            }
            dismiss()
        } catch APIError.cloudflareError(let message) {
            errorMessage = message
        } catch {
            errorMessage = "Failed to save record. Please try again."
        }
        
        isSaving = false
    }
}
