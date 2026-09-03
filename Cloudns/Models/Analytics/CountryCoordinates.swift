import Foundation
import CoreLocation

struct CountryCoordinates {
    static let map: [String: CLLocationCoordinate2D] = [
        "US": CLLocationCoordinate2D(latitude: 37.09, longitude: -95.71),
        "CN": CLLocationCoordinate2D(latitude: 35.86, longitude: 104.19),
        "GB": CLLocationCoordinate2D(latitude: 55.37, longitude: -3.43),
        "DE": CLLocationCoordinate2D(latitude: 51.16, longitude: 10.45),
        "FR": CLLocationCoordinate2D(latitude: 46.22, longitude: 2.21),
        "IN": CLLocationCoordinate2D(latitude: 20.59, longitude: 78.96),
        "JP": CLLocationCoordinate2D(latitude: 36.2, longitude: 138.25),
        "CA": CLLocationCoordinate2D(latitude: 56.13, longitude: -106.34),
        "BR": CLLocationCoordinate2D(latitude: -14.23, longitude: -51.92),
        "AU": CLLocationCoordinate2D(latitude: -25.27, longitude: 133.77),
        "RU": CLLocationCoordinate2D(latitude: 61.52, longitude: 105.31),
        "ZA": CLLocationCoordinate2D(latitude: -30.55, longitude: 22.93),
        "KR": CLLocationCoordinate2D(latitude: 35.9, longitude: 127.76),
        "IT": CLLocationCoordinate2D(latitude: 41.87, longitude: 12.56),
        "ES": CLLocationCoordinate2D(latitude: 40.46, longitude: -3.74),
        "MX": CLLocationCoordinate2D(latitude: 23.63, longitude: -102.55),
        "ID": CLLocationCoordinate2D(latitude: -0.78, longitude: 113.92),
        "TR": CLLocationCoordinate2D(latitude: 38.96, longitude: 35.24),
        "NL": CLLocationCoordinate2D(latitude: 52.13, longitude: 5.29),
        "SA": CLLocationCoordinate2D(latitude: 23.88, longitude: 45.07),
        "CH": CLLocationCoordinate2D(latitude: 46.81, longitude: 8.22),
        "SE": CLLocationCoordinate2D(latitude: 60.12, longitude: 18.64),
        "PL": CLLocationCoordinate2D(latitude: 51.91, longitude: 19.14),
        "BE": CLLocationCoordinate2D(latitude: 50.5, longitude: 4.46),
        "AR": CLLocationCoordinate2D(latitude: -38.41, longitude: -63.61),
        "NO": CLLocationCoordinate2D(latitude: 60.47, longitude: 8.46),
        "AT": CLLocationCoordinate2D(latitude: 47.51, longitude: 14.55),
        "AE": CLLocationCoordinate2D(latitude: 23.42, longitude: 53.84),
        "IL": CLLocationCoordinate2D(latitude: 31.04, longitude: 34.85),
        "SG": CLLocationCoordinate2D(latitude: 1.35, longitude: 103.81),
        "MY": CLLocationCoordinate2D(latitude: 4.21, longitude: 101.97),
        "HK": CLLocationCoordinate2D(latitude: 22.39, longitude: 114.1),
        "TW": CLLocationCoordinate2D(latitude: 23.69, longitude: 120.96),
        "TH": CLLocationCoordinate2D(latitude: 15.87, longitude: 100.99),
        "VN": CLLocationCoordinate2D(latitude: 14.05, longitude: 108.27),
        "PH": CLLocationCoordinate2D(latitude: 12.87, longitude: 121.77),
        "NZ": CLLocationCoordinate2D(latitude: -40.9, longitude: 174.88),
        "IE": CLLocationCoordinate2D(latitude: 53.41, longitude: -8.24),
        "DK": CLLocationCoordinate2D(latitude: 56.26, longitude: 9.5),
        "FI": CLLocationCoordinate2D(latitude: 61.92, longitude: 25.74),
        "PT": CLLocationCoordinate2D(latitude: 39.39, longitude: -8.22),
        "GR": CLLocationCoordinate2D(latitude: 39.07, longitude: 21.82),
        "CZ": CLLocationCoordinate2D(latitude: 49.81, longitude: 15.47),
        "RO": CLLocationCoordinate2D(latitude: 45.94, longitude: 24.96),
        "HU": CLLocationCoordinate2D(latitude: 47.16, longitude: 19.5),
        "UA": CLLocationCoordinate2D(latitude: 48.37, longitude: 31.16),
        "CO": CLLocationCoordinate2D(latitude: 4.57, longitude: -74.29),
        "CL": CLLocationCoordinate2D(latitude: -35.67, longitude: -71.54),
        "PE": CLLocationCoordinate2D(latitude: -9.19, longitude: -75.01),
        "VE": CLLocationCoordinate2D(latitude: 6.42, longitude: -66.58),
        "EG": CLLocationCoordinate2D(latitude: 26.82, longitude: 30.8),
        "NG": CLLocationCoordinate2D(latitude: 9.08, longitude: 8.67),
        "KE": CLLocationCoordinate2D(latitude: -0.02, longitude: 37.9),
        "MA": CLLocationCoordinate2D(latitude: 31.79, longitude: -7.09),
        "PK": CLLocationCoordinate2D(latitude: 30.37, longitude: 69.34),
        "BD": CLLocationCoordinate2D(latitude: 23.68, longitude: 90.35)
    ]
    
    static func flag(for countryCode: String) -> String {
        let code = countryCode.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        guard code.count == 2, CountryCoordinates.map[code] != nil else { return "🌐" }
        
        let base: UInt32 = 127397
        var flagStr = ""
        for scalar in code.unicodeScalars {
            guard scalar.value >= 65 && scalar.value <= 90 else { return "🌐" }
            if let flagScalar = UnicodeScalar(base + scalar.value) {
                flagStr.unicodeScalars.append(flagScalar)
            }
        }
        return flagStr.isEmpty ? "🌐" : flagStr
    }
}
