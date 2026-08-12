import Foundation

class CloudflareAPIClient {
    static let shared = CloudflareAPIClient()
    
    private let baseURL = "https://api.cloudflare.com/client/v4"
    let serviceName = "com.cloudflare.api"
    
    private init() {}
    
    func getZones(page: Int = 1, perPage: Int = 50) async throws -> ([Zone], ResultInfo?) {
        let email = UserDefaults.standard.string(forKey: "activeAccountEmail") ?? ""
        guard !email.isEmpty, let apiKey = KeychainHelper.standard.readString(service: serviceName, account: email) else {
            throw APIError.unauthorized
        }
        
        var components = URLComponents(string: "\(baseURL)/zones")
        components?.queryItems = [
            URLQueryItem(name: "page", value: "\(page)"),
            URLQueryItem(name: "per_page", value: "\(perPage)")
        ]
        
        guard let url = components?.url else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue(email, forHTTPHeaderField: "X-Auth-Email")
        request.addValue(apiKey, forHTTPHeaderField: "X-Auth-Key")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        if httpResponse.statusCode == 401 || httpResponse.statusCode == 403 {
            throw APIError.unauthorized
        }
        
        do {
            let decodedResponse = try JSONDecoder().decode(CloudflareResponse<[Zone]>.self, from: data)
            if decodedResponse.success {
                return (decodedResponse.result ?? [], decodedResponse.resultInfo)
            } else {
                let errorMessage = decodedResponse.errors?.first?.message ?? "Unknown API Error"
                throw APIError.cloudflareError(errorMessage)
            }
        } catch let decodeError as DecodingError {
            throw APIError.decodingError(decodeError)
        } catch let apiError as APIError {
            throw apiError
        } catch {
            throw APIError.decodingError(error)
        }
    }
    
    func getAccounts() async throws -> [Account] {
        let email = UserDefaults.standard.string(forKey: "activeAccountEmail") ?? ""
        guard !email.isEmpty, let apiKey = KeychainHelper.standard.readString(service: serviceName, account: email) else {
            throw APIError.unauthorized
        }
        
        guard let url = URL(string: "\(baseURL)/accounts") else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue(email, forHTTPHeaderField: "X-Auth-Email")
        request.addValue(apiKey, forHTTPHeaderField: "X-Auth-Key")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        if httpResponse.statusCode == 401 || httpResponse.statusCode == 403 {
            throw APIError.unauthorized
        }
        
        do {
            let decodedResponse = try JSONDecoder().decode(CloudflareResponse<[Account]>.self, from: data)
            if decodedResponse.success {
                return decodedResponse.result ?? []
            } else {
                let errorMessage = decodedResponse.errors?.first?.message ?? "Unknown API Error"
                throw APIError.cloudflareError(errorMessage)
            }
        } catch let decodeError as DecodingError {
            throw APIError.decodingError(decodeError)
        } catch let apiError as APIError {
            throw apiError
        } catch {
            throw APIError.decodingError(error)
        }
    }
    
    func createZone(name: String, accountId: String) async throws -> Zone {
        let email = UserDefaults.standard.string(forKey: "activeAccountEmail") ?? ""
        guard !email.isEmpty, let apiKey = KeychainHelper.standard.readString(service: serviceName, account: email) else {
            throw APIError.unauthorized
        }
        
        guard let url = URL(string: "\(baseURL)/zones") else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue(email, forHTTPHeaderField: "X-Auth-Email")
        request.addValue(apiKey, forHTTPHeaderField: "X-Auth-Key")
        
        let body: [String: Any] = [
            "name": name,
            "account": ["id": accountId]
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        if httpResponse.statusCode == 401 || httpResponse.statusCode == 403 {
            throw APIError.unauthorized
        }
        
        do {
            let decodedResponse = try JSONDecoder().decode(CloudflareResponse<Zone>.self, from: data)
            if decodedResponse.success, let zone = decodedResponse.result {
                return zone
            } else {
                let errorMessage = decodedResponse.errors?.first?.message ?? "Unknown API Error"
                throw APIError.cloudflareError(errorMessage)
            }
        } catch let decodeError as DecodingError {
            if let _ = String(data: data, encoding: .utf8), let errorResponse = try? JSONDecoder().decode(ZoneSettingUpdateResponse.self, from: data), let firstError = errorResponse.errors?.first {
                throw APIError.cloudflareError(firstError.message)
            }
            throw APIError.decodingError(decodeError)
        } catch let apiError as APIError {
            throw apiError
        } catch {
            throw APIError.decodingError(error)
        }
    }
    
    func deleteZone(zoneId: String) async throws {
        let email = UserDefaults.standard.string(forKey: "activeAccountEmail") ?? ""
        guard !email.isEmpty, let apiKey = KeychainHelper.standard.readString(service: serviceName, account: email) else {
            throw APIError.unauthorized
        }
        
        guard let url = URL(string: "\(baseURL)/zones/\(zoneId)") else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue(email, forHTTPHeaderField: "X-Auth-Email")
        request.addValue(apiKey, forHTTPHeaderField: "X-Auth-Key")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        if httpResponse.statusCode == 401 || httpResponse.statusCode == 403 {
            throw APIError.unauthorized
        }
        
        do {
            struct DeleteResponse: Codable {
                let success: Bool
                let errors: [CloudflareError]?
            }
            let decodedResponse = try JSONDecoder().decode(DeleteResponse.self, from: data)
            if !decodedResponse.success {
                let errorMessage = decodedResponse.errors?.first?.message ?? "Unknown API Error"
                throw APIError.cloudflareError(errorMessage)
            }
        } catch let decodeError as DecodingError {
            if let _ = String(data: data, encoding: .utf8), let errorResponse = try? JSONDecoder().decode(ZoneSettingUpdateResponse.self, from: data), let firstError = errorResponse.errors?.first {
                throw APIError.cloudflareError(firstError.message)
            }
            throw APIError.decodingError(decodeError)
        } catch let apiError as APIError {
            throw apiError
        } catch {
            throw APIError.decodingError(error)
        }
    }
    
    func getDNSRecords(zoneId: String, page: Int = 1, perPage: Int = 50) async throws -> ([DNSRecord], ResultInfo?) {
        let email = UserDefaults.standard.string(forKey: "activeAccountEmail") ?? ""
        guard !email.isEmpty, let apiKey = KeychainHelper.standard.readString(service: serviceName, account: email) else {
            throw APIError.unauthorized
        }
        
        var components = URLComponents(string: "\(baseURL)/zones/\(zoneId)/dns_records")
        components?.queryItems = [
            URLQueryItem(name: "page", value: "\(page)"),
            URLQueryItem(name: "per_page", value: "\(perPage)")
        ]
        
        guard let url = components?.url else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue(email, forHTTPHeaderField: "X-Auth-Email")
        request.addValue(apiKey, forHTTPHeaderField: "X-Auth-Key")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        if httpResponse.statusCode == 401 || httpResponse.statusCode == 403 {
            throw APIError.unauthorized
        }
        
        do {
            let decodedResponse = try JSONDecoder().decode(CloudflareResponse<[DNSRecord]>.self, from: data)
            if decodedResponse.success {
                return (decodedResponse.result ?? [], decodedResponse.resultInfo)
            } else {
                let errorMessage = decodedResponse.errors?.first?.message ?? "Unknown API Error"
                throw APIError.cloudflareError(errorMessage)
            }
        } catch let decodeError as DecodingError {
            throw APIError.decodingError(decodeError)
        } catch let apiError as APIError {
            throw apiError
        } catch {
            throw APIError.decodingError(error)
        }
    }
    
    func createDNSRecord(zoneId: String, payload: DNSRecordPayload) async throws -> DNSRecord {
        return try await performDNSMutation(zoneId: zoneId, recordId: nil, method: "POST", payload: payload)
    }
    
    func updateDNSRecord(zoneId: String, recordId: String, payload: DNSRecordPayload) async throws -> DNSRecord {
        return try await performDNSMutation(zoneId: zoneId, recordId: recordId, method: "PUT", payload: payload)
    }
    
    func deleteDNSRecord(zoneId: String, recordId: String) async throws {
        let email = UserDefaults.standard.string(forKey: "activeAccountEmail") ?? ""
        guard !email.isEmpty, let apiKey = KeychainHelper.standard.readString(service: serviceName, account: email) else {
            throw APIError.unauthorized
        }
        
        guard let url = URL(string: "\(baseURL)/zones/\(zoneId)/dns_records/\(recordId)") else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue(email, forHTTPHeaderField: "X-Auth-Email")
        request.addValue(apiKey, forHTTPHeaderField: "X-Auth-Key")
        
        let (_, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        if httpResponse.statusCode == 401 || httpResponse.statusCode == 403 {
            throw APIError.unauthorized
        }
        
        if !(200...299).contains(httpResponse.statusCode) {
            throw APIError.cloudflareError("Failed to delete record")
        }
    }
    
    private func performDNSMutation(zoneId: String, recordId: String?, method: String, payload: DNSRecordPayload) async throws -> DNSRecord {
        let email = UserDefaults.standard.string(forKey: "activeAccountEmail") ?? ""
        guard !email.isEmpty, let apiKey = KeychainHelper.standard.readString(service: serviceName, account: email) else {
            throw APIError.unauthorized
        }
        
        var urlString = "\(baseURL)/zones/\(zoneId)/dns_records"
        if let recordId = recordId {
            urlString += "/\(recordId)"
        }
        
        guard let url = URL(string: urlString) else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue(email, forHTTPHeaderField: "X-Auth-Email")
        request.addValue(apiKey, forHTTPHeaderField: "X-Auth-Key")
        
        request.httpBody = try JSONEncoder().encode(payload)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        if httpResponse.statusCode == 401 || httpResponse.statusCode == 403 {
            throw APIError.unauthorized
        }
        
        do {
            let decodedResponse = try JSONDecoder().decode(CloudflareResponse<DNSRecord>.self, from: data)
            if decodedResponse.success, let record = decodedResponse.result {
                return record
            } else {
                let errorMessage = decodedResponse.errors?.first?.message ?? "Unknown API Error"
                throw APIError.cloudflareError(errorMessage)
            }
        } catch let decodeError as DecodingError {
            throw APIError.decodingError(decodeError)
        } catch let apiError as APIError {
            throw apiError
        } catch {
            throw APIError.decodingError(error)
        }
    }
    
    func fetchGraphQLAnalytics(zoneTag: String, days: Int) async throws -> AnalyticsViewerData {
        let email = UserDefaults.standard.string(forKey: "activeAccountEmail") ?? ""
        guard !email.isEmpty, let apiKey = KeychainHelper.standard.readString(service: serviceName, account: email) else {
            throw APIError.unauthorized
        }
        
        let url = URL(string: "https://api.cloudflare.com/client/v4/graphql/")!
        
        let query: String
        
        if days == 1 {
            let formatter = ISO8601DateFormatter()
            let pastDate = Calendar.current.date(byAdding: .hour, value: -24, to: Date())!
            let dateString = formatter.string(from: pastDate)
            
            query = """
            query {
              viewer {
                zones(filter: { zoneTag: "\(zoneTag)" }) {
                  httpRequests1hGroups(limit: 100, filter: { datetime_gt: "\(dateString)" }, orderBy: [datetime_ASC]) {
                    dimensions {
                      datetime
                    }
                    sum {
                      requests
                      bytes
                      cachedRequests
                      cachedBytes
                    }
                  }
                }
              }
            }
            """
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            let pastDate = Calendar.current.date(byAdding: .day, value: -days, to: Date())!
            let dateString = formatter.string(from: pastDate)
            
            query = """
            query {
              viewer {
                zones(filter: { zoneTag: "\(zoneTag)" }) {
                  httpRequests1dGroups(limit: 100, filter: { date_gt: "\(dateString)" }, orderBy: [date_ASC]) {
                    dimensions {
                      date
                    }
                    sum {
                      requests
                      bytes
                      cachedRequests
                      cachedBytes
                    }
                  }
                }
              }
            }
            """
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue(email, forHTTPHeaderField: "X-Auth-Email")
        request.addValue(apiKey, forHTTPHeaderField: "X-Auth-Key")
        
        let payload = ["query": query]
        request.httpBody = try JSONEncoder().encode(payload)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        if httpResponse.statusCode == 401 || httpResponse.statusCode == 403 {
            throw APIError.unauthorized
        }
        
        do {
            let decodedResponse = try JSONDecoder().decode(GraphQLResponse<AnalyticsViewerData>.self, from: data)
            if let errors = decodedResponse.errors, !errors.isEmpty {
                throw APIError.cloudflareError(errors.first?.message ?? "GraphQL Error")
            }
            if let result = decodedResponse.data {
                return result
            } else {
                throw APIError.cloudflareError("No data returned")
            }
        } catch let decodeError as DecodingError {
            print("GraphQL decoding error: \(decodeError)")
            throw APIError.decodingError(decodeError)
        }
    }
    
    // MARK: - Zone Settings API
    func fetchZoneSettings(zoneId: String) async throws -> [ZoneSetting] {
        let email = UserDefaults.standard.string(forKey: "activeAccountEmail") ?? ""
        guard !email.isEmpty, let apiKey = KeychainHelper.standard.readString(service: serviceName, account: email) else {
            throw APIError.unauthorized
        }
        
        let url = URL(string: "\(baseURL)/zones/\(zoneId)/settings")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue(email, forHTTPHeaderField: "X-Auth-Email")
        request.addValue(apiKey, forHTTPHeaderField: "X-Auth-Key")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        if httpResponse.statusCode == 200 {
            do {
                let apiResponse = try JSONDecoder().decode(ZoneSettingsResponse.self, from: data)
                if apiResponse.success, let settings = apiResponse.result {
                    return settings
                } else {
                    let errorMsg = apiResponse.errors?.first?.message ?? "Unknown error"
                    throw APIError.cloudflareError(errorMsg)
                }
            } catch {
                if let str = String(data: data, encoding: .utf8) {
                    throw APIError.cloudflareError("Parse Error: \(error)\nJSON: \(str.prefix(200))")
                }
                throw APIError.decodingError(error as! DecodingError)
            }
        } else {
            throw APIError.invalidResponse
        }
    }
    
    func updateZoneSetting(zoneId: String, settingId: String, value: SettingValue) async throws {
        let email = UserDefaults.standard.string(forKey: "activeAccountEmail") ?? ""
        guard !email.isEmpty, let apiKey = KeychainHelper.standard.readString(service: serviceName, account: email) else {
            throw APIError.unauthorized
        }
        
        let url = URL(string: "\(baseURL)/zones/\(zoneId)/settings/\(settingId)")!
        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue(email, forHTTPHeaderField: "X-Auth-Email")
        request.addValue(apiKey, forHTTPHeaderField: "X-Auth-Key")
        
        let payload = ["value": value]
        request.httpBody = try JSONEncoder().encode(payload)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        if httpResponse.statusCode == 200 {
            let apiResponse = try JSONDecoder().decode(ZoneSettingUpdateResponse.self, from: data)
            if !apiResponse.success {
                let errorMsg = apiResponse.errors?.first?.message ?? "Unknown error"
                throw APIError.cloudflareError(errorMsg)
            }
        } else {
            if let _ = String(data: data, encoding: .utf8), let errorResponse = try? JSONDecoder().decode(ZoneSettingUpdateResponse.self, from: data), let firstError = errorResponse.errors?.first {
                throw APIError.cloudflareError(firstError.message)
            } else if let errorResponse = try? JSONDecoder().decode(CloudflareResponse<ZoneSetting>.self, from: data), let firstError = errorResponse.errors?.first {
                throw APIError.cloudflareError(firstError.message)
            }
            throw APIError.invalidResponse
        }
    }
    
    func fetchCustomCertificates(zoneId: String) async throws -> [CustomCertificate] {
        let email = UserDefaults.standard.string(forKey: "activeAccountEmail") ?? ""
        guard !email.isEmpty, let apiKey = KeychainHelper.standard.readString(service: serviceName, account: email) else {
            throw APIError.unauthorized
        }
        
        let url = URL(string: "\(baseURL)/zones/\(zoneId)/custom_certificates")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue(email, forHTTPHeaderField: "X-Auth-Email")
        request.setValue(apiKey, forHTTPHeaderField: "X-Auth-Key")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        if httpResponse.statusCode == 200 {
            do {
                let apiResponse = try JSONDecoder().decode(CustomCertificatesResponse.self, from: data)
                if apiResponse.success, let certs = apiResponse.result {
                    return certs
                } else {
                    let errorMsg = apiResponse.errors?.first?.message ?? "Unknown error"
                    throw APIError.cloudflareError(errorMsg)
                }
            } catch {
                if let str = String(data: data, encoding: .utf8) {
                    throw APIError.cloudflareError("Parse Error: \(error)\nJSON: \(str.prefix(200))")
                }
                throw APIError.decodingError(error as! DecodingError)
            }
        } else {
            if let errorResponse = try? JSONDecoder().decode(CustomCertificatesResponse.self, from: data),
               let firstError = errorResponse.errors?.first {
                throw APIError.cloudflareError(firstError.message)
            }
            if let str = String(data: data, encoding: .utf8) {
                throw APIError.cloudflareError("HTTP \(httpResponse.statusCode): \(str.prefix(150))")
            }
            throw APIError.invalidResponse
        }
    }
    
    func fetchCertificatePacks(zoneId: String) async throws -> [CertificatePack] {
        let email = UserDefaults.standard.string(forKey: "activeAccountEmail") ?? ""
        guard !email.isEmpty, let apiKey = KeychainHelper.standard.readString(service: serviceName, account: email) else {
            throw APIError.unauthorized
        }
        
        let url = URL(string: "\(baseURL)/zones/\(zoneId)/ssl/certificate_packs")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue(email, forHTTPHeaderField: "X-Auth-Email")
        request.setValue(apiKey, forHTTPHeaderField: "X-Auth-Key")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        if httpResponse.statusCode == 200 {
            do {
                let packResponse = try JSONDecoder().decode(CertificatePacksResponse.self, from: data)
                if packResponse.success, let packs = packResponse.result {
                    return packs
                } else {
                    let errorMsg = packResponse.errors?.first?.message ?? "Unknown error"
                    throw APIError.cloudflareError(errorMsg)
                }
            } catch {
                throw APIError.cloudflareError("Parse Error: \(error.localizedDescription)")
            }
        } else {
            if let str = String(data: data, encoding: .utf8) {
                throw APIError.cloudflareError("HTTP \(httpResponse.statusCode): \(str.prefix(150))")
            }
            throw APIError.invalidResponse
        }
    }
    
    func uploadCustomCertificate(zoneId: String, certificate: String, privateKey: String) async throws {
        let email = UserDefaults.standard.string(forKey: "activeAccountEmail") ?? ""
        guard !email.isEmpty, let apiKey = KeychainHelper.standard.readString(service: serviceName, account: email) else {
            throw APIError.unauthorized
        }
        
        let url = URL(string: "\(baseURL)/zones/\(zoneId)/custom_certificates")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(email, forHTTPHeaderField: "X-Auth-Email")
        request.setValue(apiKey, forHTTPHeaderField: "X-Auth-Key")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let payload = CustomCertificateUploadRequest(
            certificate: certificate,
            private_key: privateKey,
            bundle_method: "ubiquitous"
        )
        
        request.httpBody = try JSONEncoder().encode(payload)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        if httpResponse.statusCode == 200 || httpResponse.statusCode == 201 {
            return
        } else {
            if let errorResponse = try? JSONDecoder().decode(CustomCertificatesResponse.self, from: data),
               let firstError = errorResponse.errors?.first {
                throw APIError.cloudflareError(firstError.message)
            }
            
            if let str = String(data: data, encoding: .utf8) {
                throw APIError.cloudflareError("HTTP \(httpResponse.statusCode): \(str)")
            }
            throw APIError.invalidResponse
        }
    }
    
    func purgeCacheEverything(zoneId: String) async throws {
        let email = UserDefaults.standard.string(forKey: "activeAccountEmail") ?? ""
        guard !email.isEmpty, let apiKey = KeychainHelper.standard.readString(service: serviceName, account: email) else {
            throw APIError.unauthorized
        }
        
        let url = URL(string: "\(baseURL)/zones/\(zoneId)/purge_cache")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(email, forHTTPHeaderField: "X-Auth-Email")
        request.setValue(apiKey, forHTTPHeaderField: "X-Auth-Key")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let payload = ["purge_everything": true]
        request.httpBody = try JSONEncoder().encode(payload)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        if httpResponse.statusCode == 200 {
            return
        } else {
            if let errorResponse = try? JSONDecoder().decode(ZoneSettingUpdateResponse.self, from: data),
               let firstError = errorResponse.errors?.first {
                throw APIError.cloudflareError(firstError.message)
            }
            if let str = String(data: data, encoding: .utf8) {
                throw APIError.cloudflareError("HTTP \(httpResponse.statusCode): \(str)")
            }
            throw APIError.invalidResponse
        }
    }
    
    func purgeCacheByURLs(zoneId: String, urls: [String]) async throws {
        let email = UserDefaults.standard.string(forKey: "activeAccountEmail") ?? ""
        guard !email.isEmpty, let apiKey = KeychainHelper.standard.readString(service: serviceName, account: email) else {
            throw APIError.unauthorized
        }
        
        let url = URL(string: "\(baseURL)/zones/\(zoneId)/purge_cache")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(email, forHTTPHeaderField: "X-Auth-Email")
        request.setValue(apiKey, forHTTPHeaderField: "X-Auth-Key")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let payload = ["files": urls]
        request.httpBody = try JSONEncoder().encode(payload)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        if httpResponse.statusCode == 200 {
            return
        } else {
            if let errorResponse = try? JSONDecoder().decode(ZoneSettingUpdateResponse.self, from: data),
               let firstError = errorResponse.errors?.first {
                throw APIError.cloudflareError(firstError.message)
            }
            if let str = String(data: data, encoding: .utf8) {
                throw APIError.cloudflareError("HTTP \(httpResponse.statusCode): \(str)")
            }
            throw APIError.invalidResponse
        }
    }

    func fetchIPAccessRules(zoneId: String) async throws -> [IPAccessRule] {
        let email = UserDefaults.standard.string(forKey: "activeAccountEmail") ?? ""
        guard !email.isEmpty, let apiKey = KeychainHelper.standard.readString(service: serviceName, account: email) else {
            throw APIError.unauthorized
        }
        
        // Fetch up to 100 rules for now to avoid pagination logic for basic usage
        let url = URL(string: "\(baseURL)/zones/\(zoneId)/firewall/access_rules/rules?per_page=100")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue(email, forHTTPHeaderField: "X-Auth-Email")
        request.setValue(apiKey, forHTTPHeaderField: "X-Auth-Key")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        if httpResponse.statusCode == 200 {
            let decoded = try JSONDecoder().decode(IPAccessRulesResponse.self, from: data)
            return decoded.result ?? []
        } else {
            if let str = String(data: data, encoding: .utf8) {
                throw APIError.cloudflareError("HTTP \(httpResponse.statusCode): \(str)")
            }
            throw APIError.invalidResponse
        }
    }
    
    func createIPAccessRule(zoneId: String, mode: String, target: String, value: String, notes: String) async throws -> IPAccessRule {
        let email = UserDefaults.standard.string(forKey: "activeAccountEmail") ?? ""
        guard !email.isEmpty, let apiKey = KeychainHelper.standard.readString(service: serviceName, account: email) else {
            throw APIError.unauthorized
        }
        
        let url = URL(string: "\(baseURL)/zones/\(zoneId)/firewall/access_rules/rules")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(email, forHTTPHeaderField: "X-Auth-Email")
        request.setValue(apiKey, forHTTPHeaderField: "X-Auth-Key")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let payload = IPAccessRuleCreateRequest(
            mode: mode,
            configuration: IPAccessRuleConfiguration(target: target, value: value),
            notes: notes
        )
        
        request.httpBody = try JSONEncoder().encode(payload)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        if httpResponse.statusCode == 200 || httpResponse.statusCode == 201 {
            let decoded = try JSONDecoder().decode(IPAccessRuleCreateResponse.self, from: data)
            if let result = decoded.result {
                return result
            } else {
                throw APIError.invalidResponse
            }
        } else {
            if let errorResponse = try? JSONDecoder().decode(CertificatePacksResponse.self, from: data), // Re-using error format
               let firstError = errorResponse.errors?.first {
                throw APIError.cloudflareError(firstError.message)
            }
            if let str = String(data: data, encoding: .utf8) {
                throw APIError.cloudflareError("HTTP \(httpResponse.statusCode): \(str)")
            }
            throw APIError.invalidResponse
        }
    }
    
    func createIPAccessRule(zoneId: String, mode: String, target: String, value: String, notes: String?) async throws -> IPAccessRule {
        let email = UserDefaults.standard.string(forKey: "activeAccountEmail") ?? ""
        guard !email.isEmpty, let apiKey = KeychainHelper.standard.readString(service: serviceName, account: email) else {
            throw APIError.unauthorized
        }
        
        let url = URL(string: "\(baseURL)/zones/\(zoneId)/firewall/access_rules/rules")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(email, forHTTPHeaderField: "X-Auth-Email")
        request.setValue(apiKey, forHTTPHeaderField: "X-Auth-Key")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let payload: [String: Any] = [
            "mode": mode,
            "configuration": [
                "target": target,
                "value": value
            ],
            "notes": notes ?? "Added from iOS App"
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: payload)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        if httpResponse.statusCode == 200 || httpResponse.statusCode == 201 {
            let decoded = try JSONDecoder().decode(CloudflareResponse<IPAccessRule>.self, from: data)
            if let result = decoded.result {
                return result
            }
            throw APIError.invalidResponse
        } else {
            if let _ = String(data: data, encoding: .utf8), let errorResponse = try? JSONDecoder().decode(ZoneSettingUpdateResponse.self, from: data), let firstError = errorResponse.errors?.first {
                throw APIError.cloudflareError(firstError.message)
            }
            if let str = String(data: data, encoding: .utf8) {
                throw APIError.cloudflareError("HTTP \(httpResponse.statusCode): \(str)")
            }
            throw APIError.invalidResponse
        }
    }
    
    func deleteIPAccessRule(zoneId: String, ruleId: String) async throws {
        let email = UserDefaults.standard.string(forKey: "activeAccountEmail") ?? ""
        guard !email.isEmpty, let apiKey = KeychainHelper.standard.readString(service: serviceName, account: email) else {
            throw APIError.unauthorized
        }
        
        let url = URL(string: "\(baseURL)/zones/\(zoneId)/firewall/access_rules/rules/\(ruleId)")!
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue(email, forHTTPHeaderField: "X-Auth-Email")
        request.setValue(apiKey, forHTTPHeaderField: "X-Auth-Key")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        if httpResponse.statusCode == 200 {
            return
        } else {
            if let errorResponse = try? JSONDecoder().decode(CertificatePacksResponse.self, from: data),
               let firstError = errorResponse.errors?.first {
                throw APIError.cloudflareError(firstError.message)
            }
            if let str = String(data: data, encoding: .utf8) {
                throw APIError.cloudflareError("HTTP \(httpResponse.statusCode): \(str)")
            }
            throw APIError.invalidResponse
        }
    }
    
    // MARK: - Page Rules
    
    func getPageRules(zoneId: String) async throws -> [PageRule] {
        let email = UserDefaults.standard.string(forKey: "activeAccountEmail") ?? ""
        guard !email.isEmpty, let apiKey = KeychainHelper.standard.readString(service: serviceName, account: email) else {
            throw APIError.unauthorized
        }
        
        let url = URL(string: "\(baseURL)/zones/\(zoneId)/pagerules")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue(email, forHTTPHeaderField: "X-Auth-Email")
        request.addValue(apiKey, forHTTPHeaderField: "X-Auth-Key")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        if httpResponse.statusCode == 401 || httpResponse.statusCode == 403 {
            throw APIError.unauthorized
        }
        
        let decodedResponse = try JSONDecoder().decode(CloudflareResponse<[PageRule]>.self, from: data)
        if decodedResponse.success {
            return decodedResponse.result ?? []
        } else {
            let errorMessage = decodedResponse.errors?.first?.message ?? "Unknown API Error"
            throw APIError.cloudflareError(errorMessage)
        }
    }
    
    func updatePageRuleStatus(zoneId: String, ruleId: String, status: String) async throws {
        let email = UserDefaults.standard.string(forKey: "activeAccountEmail") ?? ""
        guard !email.isEmpty, let apiKey = KeychainHelper.standard.readString(service: serviceName, account: email) else {
            throw APIError.unauthorized
        }
        
        let url = URL(string: "\(baseURL)/zones/\(zoneId)/pagerules/\(ruleId)")!
        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue(email, forHTTPHeaderField: "X-Auth-Email")
        request.addValue(apiKey, forHTTPHeaderField: "X-Auth-Key")
        
        let payload = ["status": status]
        request.httpBody = try JSONEncoder().encode(payload)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        if httpResponse.statusCode != 200 {
            if let decodedResponse = try? JSONDecoder().decode(CloudflareResponse<PageRule>.self, from: data), !decodedResponse.success {
                throw APIError.cloudflareError(decodedResponse.errors?.first?.message ?? "Unknown API Error")
            }
            throw APIError.cloudflareError("HTTP \(httpResponse.statusCode)")
        }
    }
    
    func deletePageRule(zoneId: String, ruleId: String) async throws {
        let email = UserDefaults.standard.string(forKey: "activeAccountEmail") ?? ""
        guard !email.isEmpty, let apiKey = KeychainHelper.standard.readString(service: serviceName, account: email) else {
            throw APIError.unauthorized
        }
        
        let url = URL(string: "\(baseURL)/zones/\(zoneId)/pagerules/\(ruleId)")!
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue(email, forHTTPHeaderField: "X-Auth-Email")
        request.addValue(apiKey, forHTTPHeaderField: "X-Auth-Key")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        if httpResponse.statusCode != 200 {
            if let decodedResponse = try? JSONDecoder().decode(CloudflareResponse<PageRule>.self, from: data), !decodedResponse.success {
                throw APIError.cloudflareError(decodedResponse.errors?.first?.message ?? "Unknown API Error")
            }
            throw APIError.cloudflareError("HTTP \(httpResponse.statusCode)")
        }
    }
    
    // MARK: - DNSSEC
    
    func getDNSSEC(zoneId: String) async throws -> DNSSEC {
        let email = UserDefaults.standard.string(forKey: "activeAccountEmail") ?? ""
        guard !email.isEmpty, let apiKey = KeychainHelper.standard.readString(service: serviceName, account: email) else {
            throw APIError.unauthorized
        }
        
        let url = URL(string: "\(baseURL)/zones/\(zoneId)/dnssec")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue(email, forHTTPHeaderField: "X-Auth-Email")
        request.setValue(apiKey, forHTTPHeaderField: "X-Auth-Key")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        if httpResponse.statusCode == 200 {
            do {
                let apiResponse = try JSONDecoder().decode(CloudflareResponse<DNSSEC>.self, from: data)
                if let result = apiResponse.result {
                    return result
                }
                throw APIError.invalidResponse
            } catch {
                if let str = String(data: data, encoding: .utf8) {
                    print("DNSSEC Decode Error: \(error), JSON: \(str)")
                }
                throw APIError.cloudflareError("Decode error: \(error.localizedDescription)")
            }
        } else {
            if let _ = String(data: data, encoding: .utf8), let errorResponse = try? JSONDecoder().decode(ZoneSettingUpdateResponse.self, from: data), let firstError = errorResponse.errors?.first {
                throw APIError.cloudflareError(firstError.message)
            }
            throw APIError.invalidResponse
        }
    }
    
    func updateDNSSEC(zoneId: String, status: String) async throws {
        let email = UserDefaults.standard.string(forKey: "activeAccountEmail") ?? ""
        guard !email.isEmpty, let apiKey = KeychainHelper.standard.readString(service: serviceName, account: email) else {
            throw APIError.unauthorized
        }
        
        let url = URL(string: "\(baseURL)/zones/\(zoneId)/dnssec")!
        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(email, forHTTPHeaderField: "X-Auth-Email")
        request.setValue(apiKey, forHTTPHeaderField: "X-Auth-Key")
        
        let payload = ["status": status]
        request.httpBody = try JSONEncoder().encode(payload)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        if httpResponse.statusCode == 200 {
            return
        } else {
            if let _ = String(data: data, encoding: .utf8), let errorResponse = try? JSONDecoder().decode(ZoneSettingUpdateResponse.self, from: data), let firstError = errorResponse.errors?.first {
                throw APIError.cloudflareError(firstError.message)
            }
            throw APIError.invalidResponse
        }
    }
}
