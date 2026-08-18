//
//  CloudnsTests.swift
//  CloudnsTests
//

import Foundation
import Testing
@testable import Cloudns

// MARK: - 1. APIError Tests

@Suite("APIError Tests")
struct APIErrorTests {
    
    @Test("Cloudflare standard JSON error decoding")
    func testCloudflareJSONErrorParsing() {
        let json = """
        {
            "success": false,
            "errors": [
                { "code": 10000, "message": "Authentication error" },
                { "code": 10001, "message": "Invalid token signature" }
            ],
            "messages": [],
            "result": null
        }
        """.data(using: .utf8)!
        
        let error = APIError.fromCloudflareResponse(data: json, statusCode: 400)
        #expect(error.localizedDescription.contains("Authentication error (Code 10000)"))
        #expect(error.localizedDescription.contains("Invalid token signature (Code 10001)"))
    }
    
    @Test("Cloudflare HTML Gateway error sanitization")
    func testHTMLGatewayErrorSanitization() {
        let html502 = """
        <!DOCTYPE html>
        <html>
        <head><title>502 Bad Gateway</title></head>
        <body>
        <center><h1>502 Bad Gateway</h1></center>
        <hr><center>cloudflare</center>
        </body>
        </html>
        """.data(using: .utf8)!
        
        let error = APIError.fromCloudflareResponse(data: html502, statusCode: 502)
        #expect(error.localizedDescription == "Cloudflare Gateway Error (HTTP 502)")
        
        let formatted = APIError.formatCloudflareError("<!DOCTYPE html><html><title>Error</title></html>")
        #expect(formatted == "Cloudflare Gateway Error")
    }
    
    @Test("APIError localized error descriptions")
    func testLocalizedDescriptions() {
        let unauthorized = APIError.unauthorized
        #expect(unauthorized.localizedDescription.contains("API Token or Global Key"))
        #expect(unauthorized.recoverySuggestion != nil)
        
        let invalidURL = APIError.invalidURL
        #expect(invalidURL.localizedDescription == "Invalid API URL.")
        #expect(invalidURL.failureReason != nil)
        
        let invalidResponse = APIError.invalidResponse
        #expect(invalidResponse.localizedDescription.contains("Invalid response"))
    }
}

// MARK: - 2. SWRCacheStore Tests

@Suite("SWRCacheStore Tests")
struct SWRCacheStoreTests {
    
    struct TestItem: Codable, Equatable, Sendable {
        let id: String
        let name: String
        let score: Int
    }
    
    @Test("SWR Memory and Disk cache roundtrip")
    func testSWRCacheSetAndGet() async {
        let store = SWRCacheStore.shared
        let testKey = "unit_test_key_\(UUID().uuidString)"
        let originalItem = TestItem(id: "item_123", name: "Cloudns SWR Test", score: 99)
        
        await store.set(originalItem, forKey: testKey)
        let cachedItem = await store.get(forKey: testKey, as: TestItem.self)
        
        #expect(cachedItem != nil)
        #expect(cachedItem?.id == "item_123")
        #expect(cachedItem?.name == "Cloudns SWR Test")
        #expect(cachedItem?.score == 99)
        
        // Remove
        await store.remove(forKey: testKey)
        let deletedItem = await store.get(forKey: testKey, as: TestItem.self)
        #expect(deletedItem == nil)
    }
    
    @Test("Account scoped key isolation")
    func testAccountScopedKey() {
        let keyA = SWRCacheStore.accountScopedKey("zones_list")
        #expect(keyA.contains("zones_list"))
    }
    
    @Test("SWR Cache TTL and metadata support")
    func testSWRCacheTTLAndMetadata() async throws {
        let store = SWRCacheStore.shared
        let ttlKey = "ttl_test_key_\(UUID().uuidString)"
        let item = TestItem(id: "ttl_1", name: "TTL Test", score: 100)
        
        // Write with 0.2s TTL
        await store.set(item, forKey: ttlKey, ttl: 0.2)
        
        let meta = await store.getWithMetadata(forKey: ttlKey, as: TestItem.self)
        #expect(meta != nil)
        #expect(meta?.value.name == "TTL Test")
        #expect(meta?.metadata.ttl == 0.2)
        #expect(meta?.metadata.isExpired == false)
        
        // Wait for TTL expiration
        try await Task.sleep(nanoseconds: 300_000_000)
        
        // With ignoreExpiration: false -> should return nil
        let expiredItem = await store.get(forKey: ttlKey, as: TestItem.self, ignoreExpiration: false)
        #expect(expiredItem == nil)
    }
}

// MARK: - 3. DateFormatters Tests

@Suite("DateFormatters Tests")
struct DateFormattersTests {
    
    @Test("ISO8601 with fractional seconds parsing")
    func testISO8601FractionalSeconds() {
        let dateStr = "2026-08-17T12:30:45.123456Z"
        let parsed = DateFormatters.parseISO8601(dateStr)
        #expect(parsed != nil)
    }
    
    @Test("ISO8601 standard and fallback parsing")
    func testISO8601StandardAndFallback() {
        let standard = "2026-08-17T12:30:45Z"
        #expect(DateFormatters.parseISO8601(standard) != nil)
        
        let spaceSeparated = "2026-08-17 12:30:45"
        #expect(DateFormatters.parseISO8601(spaceSeparated) != nil)
    }
    
    @Test("Chart date parsing")
    func testChartDateParsing() {
        let ymdDate = "2026-08-17"
        let date = DateFormatters.parseChartDate(ymdDate)
        let formatted = DateFormatters.yearMonthDay.string(from: date)
        #expect(formatted == "2026-08-17")
    }
    
    @Test("Timestamp millisecond formatting")
    func testTimestampMsFormatting() {
        let timestampMs: Double = 1700000000000.0
        let result = DateFormatters.formatTimestampMs(timestampMs)
        #expect(!result.isEmpty)
    }
}

// MARK: - 4. Country Coordinates & Flag Tests

@Suite("Country Coordinates & Flag Tests")
struct CountryCoordinatesTests {
    
    @Test("Country code to flag Emoji conversion")
    func testCountryFlagConversion() {
        #expect(CountryCoordinates.flag(for: "US") == "🇺🇸")
        #expect(CountryCoordinates.flag(for: "us") == "🇺🇸")
        #expect(CountryCoordinates.flag(for: "CN") == "🇨🇳")
        #expect(CountryCoordinates.flag(for: "cn") == "🇨🇳")
        #expect(CountryCoordinates.flag(for: "JP") == "🇯🇵")
        #expect(CountryCoordinates.flag(for: "GB") == "🇬🇧")
        #expect(CountryCoordinates.flag(for: "DE") == "🇩🇪")
    }
    
    @Test("Non-standard and invalid country code fallbacks")
    func testCountryFlagFallbacks() {
        #expect(CountryCoordinates.flag(for: "XX") == "🌐")
        #expect(CountryCoordinates.flag(for: "T1") == "🌐")
        #expect(CountryCoordinates.flag(for: "TOR") == "🌐")
        #expect(CountryCoordinates.flag(for: "") == "🌐")
        #expect(CountryCoordinates.flag(for: "12") == "🌐")
    }
    
    @Test("Country coordinate lookup map")
    func testCoordinatesMap() {
        #expect(CountryCoordinates.map["US"] != nil)
        #expect(CountryCoordinates.map["CN"] != nil)
        #expect(CountryCoordinates.map["JP"] != nil)
    }
}

// MARK: - 5. Models Decoding Tests

@Suite("Models Decoding Tests")
struct ModelsDecodingTests {
    
    @Test("Zone model JSON decoding")
    func testZoneDecoding() throws {
        let json = """
        {
            "id": "023e105f4ecef8ad9ca31a8372d0c353",
            "name": "example.com",
            "status": "active",
            "paused": false,
            "type": "full",
            "development_mode": 0,
            "name_servers": ["ns1.cloudflare.com", "ns2.cloudflare.com"],
            "plan": {
                "id": "free",
                "name": "Free Plan"
            }
        }
        """.data(using: .utf8)!
        
        let zone = try JSONDecoder().decode(Zone.self, from: json)
        #expect(zone.id == "023e105f4ecef8ad9ca31a8372d0c353")
        #expect(zone.name == "example.com")
        #expect(zone.status == "active")
        #expect(zone.paused == false)
        #expect(zone.nameServers?.count == 2)
        #expect(zone.plan?.name == "Free Plan")
        #expect(zone.plan?.displayName == "Free")
    }
    
    @Test("DNSRecord model JSON decoding")
    func testDNSRecordDecoding() throws {
        let json = """
        {
            "id": "372e67954025e0ba6aaa6d586b9e0b59",
            "type": "A",
            "name": "api.example.com",
            "content": "192.0.2.1",
            "proxiable": true,
            "proxied": true,
            "ttl": 1,
            "comment": "Main API origin"
        }
        """.data(using: .utf8)!
        
        let record = try JSONDecoder().decode(DNSRecord.self, from: json)
        #expect(record.id == "372e67954025e0ba6aaa6d586b9e0b59")
        #expect(record.type == "A")
        #expect(record.name == "api.example.com")
        #expect(record.content == "192.0.2.1")
        #expect(record.proxied == true)
        #expect(record.comment == "Main API origin")
    }
    
    @Test("WAFRule model JSON decoding")
    func testWAFRuleDecoding() throws {
        let json = """
        {
            "id": "3b26c6d2-c2e0-4a87-84bc-2db85f7bb197",
            "action": "block",
            "expression": "(http.request.uri.path contains \\"/admin\\")",
            "description": "Block Admin Path",
            "enabled": true
        }
        """.data(using: .utf8)!
        
        let rule = try JSONDecoder().decode(WAFRule.self, from: json)
        #expect(rule.id == "3b26c6d2-c2e0-4a87-84bc-2db85f7bb197")
        #expect(rule.action == "block")
        #expect(rule.enabled == true)
        #expect(rule.description == "Block Admin Path")
    }
    
    @Test("D1TableRow identifier stability")
    func testD1TableRowStability() {
        let rowWithId = D1TableRow(index: 0, values: ["_rowid_": "42", "name": "Alice"])
        #expect(rowWithId.id == "rowid_42")
        #expect(rowWithId.rowid == "42")
        
        let rowWithoutId = D1TableRow(index: 5, values: ["name": "Bob", "email": "bob@example.com"])
        #expect(rowWithoutId.id.hasPrefix("row_5_"))
        #expect(rowWithoutId.rowid == nil)
    }
    
    @Test("WorkerAnalytics GraphQL Response decoding")
    func testWorkerAnalyticsGraphQLDecoding() throws {
        let json = """
        {
            "data": {
                "viewer": {
                    "accounts": [
                        {
                            "workersInvocationsAdaptive": [
                                {
                                    "dimensions": {
                                        "datetime": "2026-08-17T10:00:00Z",
                                        "status": "success",
                                        "scriptName": "my-worker-api"
                                    },
                                    "sum": {
                                        "requests": 1500,
                                        "errors": 2,
                                        "subrequests": 3000
                                    },
                                    "quantiles": {
                                        "cpuTimeP50": 1.25,
                                        "cpuTimeP99": 8.5
                                    }
                                }
                            ]
                        }
                    ]
                }
            },
            "errors": null
        }
        """.data(using: .utf8)!
        
        let decoded = try JSONDecoder().decode(GraphQLResponse<WorkerAnalyticsViewerData>.self, from: json)
        let items = decoded.data?.viewer.accounts?.first?.workersInvocationsAdaptive
        #expect(items?.count == 1)
        #expect(items?.first?.dimensions.scriptName == "my-worker-api")
        #expect(items?.first?.sum?.requests == 1500)
        #expect(items?.first?.sum?.errors == 2)
        #expect(items?.first?.quantiles?.cpuTimeP50 == 1.25)
        #expect(items?.first?.quantiles?.cpuTimeP99 == 8.5)
    }
    
    @Test("ZoneAnalytics GraphQL Response decoding")
    func testZoneAnalyticsGraphQLDecoding() throws {
        let json = """
        {
            "data": {
                "viewer": {
                    "zones": [
                        {
                            "httpRequests1hGroups": [
                                {
                                    "dimensions": {
                                        "datetime": "2026-08-17T10:00:00Z"
                                    },
                                    "sum": {
                                        "requests": 8420,
                                        "bytes": 1048576,
                                        "cachedRequests": 6200,
                                        "cachedBytes": 838860
                                    }
                                }
                            ],
                            "trafficByCountry1h": [
                                {
                                    "dimensions": {
                                        "clientCountryName": "US"
                                    },
                                    "count": 4200
                                }
                            ]
                        }
                    ]
                }
            },
            "errors": null
        }
        """.data(using: .utf8)!
        
        let decoded = try JSONDecoder().decode(GraphQLResponse<AnalyticsViewerData>.self, from: json)
        let zone = decoded.data?.viewer.zones?.first
        #expect(zone?.httpRequests1hGroups?.count == 1)
        #expect(zone?.httpRequests1hGroups?.first?.sum.requests == 8420)
        #expect(zone?.trafficByCountry1h?.first?.dimensions.clientCountryName == "US")
        #expect(zone?.trafficByCountry1h?.first?.count == 4200)
    }
    
    @Test("Pages Functions GraphQL adaptive groups decoding")
    func testPagesFunctionsGraphQLDecoding() throws {
        let json = """
        {
            "data": {
                "viewer": {
                    "accounts": [
                        {
                            "pagesFunctionsInvocationsAdaptiveGroups": [
                                {
                                    "dimensions": {
                                        "datetime": "2026-08-17T11:00:00Z",
                                        "scriptName": "my-pages-project"
                                    },
                                    "sum": {
                                        "requests": 5600,
                                        "errors": 4
                                    },
                                    "quantiles": {
                                        "cpuTimeP50": 1850.0,
                                        "cpuTimeP99": 7200.0,
                                        "durationMsP50": 12.5,
                                        "durationMsP99": 45.0
                                    }
                                }
                            ]
                        }
                    ]
                }
            },
            "errors": null
        }
        """.data(using: .utf8)!
        
        let decoded = try JSONDecoder().decode(GraphQLResponse<WorkerAnalyticsViewerData>.self, from: json)
        let list = decoded.data?.viewer.accounts?.first?.pagesFunctionsInvocationsAdaptiveGroups
        #expect(list?.count == 1)
        #expect(list?.first?.dimensions.scriptName == "my-pages-project")
        #expect(list?.first?.sum?.requests == 5600)
        #expect(list?.first?.sum?.errors == 4)
    }
    
    @Test("Chart date parsing compatibility (ISO8601 & YYYY-MM-DD)")
    func testChartDateParsing() {
        let isoDate = DateFormatters.parseChartDate("2026-08-17T14:30:00Z")
        #expect(isoDate.timeIntervalSince1970 > 0)
        
        let dayDate = DateFormatters.parseChartDate("2026-08-17")
        #expect(dayDate.timeIntervalSince1970 > 0)
    }
}

// MARK: - 6. HTTPNetworkClient Tests

@Suite("HTTPNetworkClient Tests")
struct HTTPNetworkClientTests {
    
    final class MockURLProtocol: URLProtocol, @unchecked Sendable {
        override class func canInit(with request: URLRequest) -> Bool {
            return true
        }
        
        override class func canonicalRequest(for request: URLRequest) -> URLRequest {
            return request
        }
        
        override func startLoading() {
            let url = request.url ?? URL(string: "https://api.cloudflare.com/client/v4/user")!
            let path = url.path
            
            if path.contains("unauthorized") {
                let response = HTTPURLResponse(url: url, statusCode: 401, httpVersion: "HTTP/2.0", headerFields: nil)!
                client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
                client?.urlProtocol(self, didLoad: Data())
                client?.urlProtocolDidFinishLoading(self)
                return
            }
            
            if path.contains("zones") {
                let json = """
                {
                    "success": true,
                    "errors": [],
                    "messages": [],
                    "result": {
                        "id": "mock_zone_123",
                        "name": "example.com",
                        "status": "active",
                        "paused": false
                    }
                }
                """.data(using: .utf8)!
                let response = HTTPURLResponse(url: url, statusCode: 200, httpVersion: "HTTP/2.0", headerFields: ["Content-Type": "application/json"])!
                client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
                client?.urlProtocol(self, didLoad: json)
                client?.urlProtocolDidFinishLoading(self)
                return
            }
            
            let defaultResponse = HTTPURLResponse(url: url, statusCode: 200, httpVersion: "HTTP/2.0", headerFields: nil)!
            client?.urlProtocol(self, didReceive: defaultResponse, cacheStoragePolicy: .notAllowed)
            client?.urlProtocolDidFinishLoading(self)
        }
        
        override func stopLoading() {}
    }
    
    @Test("HTTPNetworkClient successful performRequest")
    func testSuccessfulPerformRequest() async throws {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockURLProtocol.self]
        let session = URLSession(configuration: config)
        let client = HTTPNetworkClient(session: session, maxRetries: 1)
        
        let request = URLRequest(url: URL(string: "https://api.cloudflare.com/client/v4/zones/mock_zone_123")!)
        let (zone, _): (Zone?, ResultInfo?) = try await client.performRequest(request)
        
        #expect(zone != nil)
        #expect(zone?.id == "mock_zone_123")
        #expect(zone?.name == "example.com")
    }
    
    @Test("HTTPNetworkClient handles 401 unauthorized")
    func testUnauthorizedResponse() async {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockURLProtocol.self]
        let session = URLSession(configuration: config)
        let client = HTTPNetworkClient(session: session, maxRetries: 1)
        
        let request = URLRequest(url: URL(string: "https://api.cloudflare.com/client/v4/unauthorized")!)
        
        do {
            let _: (Zone?, ResultInfo?) = try await client.performRequest(request)
            #expect(Bool(false), "Should have thrown unauthorized error")
        } catch let error as APIError {
            switch error {
            case .unauthorized:
                #expect(true)
            default:
                #expect(Bool(false), "Expected .unauthorized, got \(error)")
            }
        } catch {
            #expect(Bool(false), "Expected APIError.unauthorized")
        }
    }
}

