import Foundation

public struct CloudflarePoPInfo: Sendable {
    public let code: String
    public let city: String
    public let country: String
    public let flag: String
    public let region: String
    public let airport: String
    
    public init(code: String, city: String, country: String, flag: String, region: String, airport: String) {
        self.code = code
        self.city = city
        self.country = country
        self.flag = flag
        self.region = region
        self.airport = airport
    }
}

public final class CloudflarePoPDatabase: Sendable {
    public static let shared = CloudflarePoPDatabase()
    
    private let pops: [String: CloudflarePoPInfo]
    
    private init() {
        var dict: [String: CloudflarePoPInfo] = [:]
        
        let allItems = Self.loadAsiaPops() + Self.loadAmericasPops() + Self.loadEuropePops() + Self.loadOtherPops()
        
        for item in allItems {
            let info = CloudflarePoPInfo(
                code: item.0,
                city: item.1,
                country: item.2,
                flag: item.3,
                region: item.4,
                airport: item.5
            )
            dict[item.0.uppercased()] = info
        }
        
        self.pops = dict
    }
    
    public func getPoP(code: String?) -> CloudflarePoPInfo? {
        guard let code = code?.trimmingCharacters(in: .whitespacesAndNewlines).uppercased(), !code.isEmpty else {
            return nil
        }
        return pops[code]
    }
    
    private static func loadAsiaPops() -> [(String, String, String, String, String, String)] {
        [
            ("HKG", "Hong Kong", "Hong Kong", "🇭🇰", "Asia Pacific", "Hong Kong International Airport"),
            ("TPE", "Taipei", "Taiwan", "🇹🇼", "Asia Pacific", "Taoyuan International Airport"),
            ("KHH", "Kaohsiung", "Taiwan", "🇹🇼", "Asia Pacific", "Kaohsiung International Airport"),
            ("NRT", "Tokyo", "Japan", "🇯🇵", "Asia Pacific", "Narita International Airport"),
            ("HND", "Tokyo", "Japan", "🇯🇵", "Asia Pacific", "Haneda Airport"),
            ("KIX", "Osaka", "Japan", "🇯🇵", "Asia Pacific", "Kansai International Airport"),
            ("FUK", "Fukuoka", "Japan", "🇯🇵", "Asia Pacific", "Fukuoka Airport"),
            ("OKA", "Okinawa", "Japan", "🇯🇵", "Asia Pacific", "Naha Airport"),
            ("ICN", "Seoul", "South Korea", "🇰🇷", "Asia Pacific", "Incheon International Airport"),
            ("GMP", "Seoul", "South Korea", "🇰🇷", "Asia Pacific", "Gimpo International Airport"),
            ("PUS", "Busan", "South Korea", "🇰🇷", "Asia Pacific", "Gimhae International Airport"),
            ("MFM", "Macau", "Macau", "🇲🇴", "Asia Pacific", "Macau International Airport"),
            ("ULN", "Ulaanbaatar", "Mongolia", "🇲🇳", "Asia Pacific", "Chinggis Khaan International Airport"),
            ("SIN", "Singapore", "Singapore", "🇸🇬", "Asia Pacific", "Singapore Changi Airport"),
            ("BKK", "Bangkok", "Thailand", "🇹🇭", "Asia Pacific", "Suvarnabhumi Airport"),
            ("DMK", "Bangkok", "Thailand", "🇹🇭", "Asia Pacific", "Don Mueang International Airport"),
            ("CNX", "Chiang Mai", "Thailand", "🇹🇭", "Asia Pacific", "Chiang Mai International Airport"),
            ("KUL", "Kuala Lumpur", "Malaysia", "🇲🇾", "Asia Pacific", "Kuala Lumpur International Airport"),
            ("JHB", "Johor Bahru", "Malaysia", "🇲🇾", "Asia Pacific", "Senai International Airport"),
            ("CGK", "Jakarta", "Indonesia", "🇮🇩", "Asia Pacific", "Soekarno-Hatta International Airport"),
            ("DPS", "Bali", "Indonesia", "🇮🇩", "Asia Pacific", "Ngurah Rai International Airport"),
            ("MNL", "Manila", "Philippines", "🇵🇭", "Asia Pacific", "Ninoy Aquino International Airport"),
            ("CEB", "Cebu", "Philippines", "🇵🇭", "Asia Pacific", "Mactan-Cebu International Airport"),
            ("HAN", "Hanoi", "Vietnam", "🇻🇳", "Asia Pacific", "Noi Bai International Airport"),
            ("SGN", "Ho Chi Minh City", "Vietnam", "🇻🇳", "Asia Pacific", "Tan Son Nhat International Airport"),
            ("PNH", "Phnom Penh", "Cambodia", "🇰🇭", "Asia Pacific", "Phnom Penh International Airport"),
            ("VTE", "Vientiane", "Laos", "🇱🇦", "Asia Pacific", "Wattay International Airport"),
            ("BWN", "Bandar Seri Begawan", "Brunei", "🇧🇳", "Asia Pacific", "Brunei International Airport")
        ]
    }
    
    private static func loadAmericasPops() -> [(String, String, String, String, String, String)] {
        [
            ("SFO", "San Francisco", "United States", "🇺🇸", "North America", "San Francisco International Airport"),
            ("SJC", "San Jose", "United States", "🇺🇸", "North America", "Norman Y. Mineta San Jose Airport"),
            ("LAX", "Los Angeles", "United States", "🇺🇸", "North America", "Los Angeles International Airport"),
            ("SAN", "San Diego", "United States", "🇺🇸", "North America", "San Diego International Airport"),
            ("SEA", "Seattle", "United States", "🇺🇸", "North America", "Seattle-Tacoma International Airport"),
            ("PDX", "Portland", "United States", "🇺🇸", "North America", "Portland International Airport"),
            ("PHX", "Phoenix", "United States", "🇺🇸", "North America", "Phoenix Sky Harbor Airport"),
            ("LAS", "Las Vegas", "United States", "🇺🇸", "North America", "Harry Reid International Airport"),
            ("SLC", "Salt Lake City", "United States", "🇺🇸", "North America", "Salt Lake City Airport"),
            ("DEN", "Denver", "United States", "🇺🇸", "North America", "Denver International Airport"),
            ("YVR", "Vancouver", "Canada", "🇨🇦", "North America", "Vancouver International Airport"),
            ("YYC", "Calgary", "Canada", "🇨🇦", "North America", "Calgary International Airport"),
            ("ORD", "Chicago", "United States", "🇺🇸", "North America", "O'Hare International Airport"),
            ("DFW", "Dallas", "United States", "🇺🇸", "North America", "Dallas/Fort Worth International Airport"),
            ("IAH", "Houston", "United States", "🇺🇸", "North America", "George Bush Intercontinental Airport"),
            ("AUS", "Austin", "United States", "🇺🇸", "North America", "Austin-Bergstrom International Airport"),
            ("SAT", "San Antonio", "United States", "🇺🇸", "North America", "San Antonio International Airport"),
            ("MCI", "Kansas City", "United States", "🇺🇸", "North America", "Kansas City International Airport"),
            ("MSP", "Minneapolis", "United States", "🇺🇸", "North America", "Minneapolis-Saint Paul Airport"),
            ("DTW", "Detroit", "United States", "🇺🇸", "North America", "Detroit Metropolitan Wayne Airport"),
            ("ATL", "Atlanta", "United States", "🇺🇸", "North America", "Hartsfield-Jackson Atlanta Airport"),
            ("MIA", "Miami", "United States", "🇺🇸", "North America", "Miami International Airport"),
            ("TPA", "Tampa", "United States", "🇺🇸", "North America", "Tampa International Airport"),
            ("MCO", "Orlando", "United States", "🇺🇸", "North America", "Orlando International Airport"),
            ("CLT", "Charlotte", "United States", "🇺🇸", "North America", "Charlotte Douglas International Airport"),
            ("IAD", "Washington D.C.", "United States", "🇺🇸", "North America", "Dulles International Airport"),
            ("DCA", "Washington D.C.", "United States", "🇺🇸", "North America", "Ronald Reagan Washington Airport"),
            ("PHL", "Philadelphia", "United States", "🇺🇸", "North America", "Philadelphia International Airport"),
            ("EWR", "Newark", "United States", "🇺🇸", "North America", "Newark Liberty International Airport"),
            ("JFK", "New York", "United States", "🇺🇸", "North America", "John F. Kennedy International Airport"),
            ("LGA", "New York", "United States", "🇺🇸", "North America", "LaGuardia Airport"),
            ("BOS", "Boston", "United States", "🇺🇸", "North America", "Logan International Airport"),
            ("YYZ", "Toronto", "Canada", "🇨🇦", "North America", "Toronto Pearson International Airport"),
            ("YUL", "Montreal", "Canada", "🇨🇦", "North America", "Montréal-Trudeau International Airport"),
            ("GRU", "Sao Paulo", "Brazil", "🇧🇷", "South America", "São Paulo/Guarulhos Airport"),
            ("GIG", "Rio de Janeiro", "Brazil", "🇧🇷", "South America", "Rio de Janeiro/Galeão Airport"),
            ("EZE", "Buenos Aires", "Argentina", "🇦🇷", "South America", "Ministro Pistarini Airport"),
            ("SCL", "Santiago", "Chile", "🇨🇱", "South America", "Arturo Merino Benítez Airport"),
            ("BOG", "Bogota", "Colombia", "🇨🇴", "South America", "El Dorado International Airport"),
            ("LIM", "Lima", "Peru", "🇵🇪", "South America", "Jorge Chávez International Airport")
        ]
    }
    
    private static func loadEuropePops() -> [(String, String, String, String, String, String)] {
        [
            ("LHR", "London", "United Kingdom", "🇬🇧", "Europe", "London Heathrow Airport"),
            ("LGW", "London", "United Kingdom", "🇬🇧", "Europe", "London Gatwick Airport"),
            ("MAN", "Manchester", "United Kingdom", "🇬🇧", "Europe", "Manchester Airport"),
            ("EDI", "Edinburgh", "United Kingdom", "🇬🇧", "Europe", "Edinburgh Airport"),
            ("DUB", "Dublin", "Ireland", "🇮🇪", "Europe", "Dublin Airport"),
            ("FRA", "Frankfurt", "Germany", "🇩🇪", "Europe", "Frankfurt am Main Airport"),
            ("MUC", "Munich", "Germany", "🇩🇪", "Europe", "Munich Airport"),
            ("BER", "Berlin", "Germany", "🇩🇪", "Europe", "Berlin Brandenburg Airport"),
            ("HAM", "Hamburg", "Germany", "🇩🇪", "Europe", "Hamburg Airport"),
            ("DUS", "Dusseldorf", "Germany", "🇩🇪", "Europe", "Düsseldorf Airport"),
            ("AMS", "Amsterdam", "Netherlands", "🇳🇱", "Europe", "Amsterdam Airport Schiphol"),
            ("BRU", "Brussels", "Belgium", "🇧🇪", "Europe", "Brussels Airport"),
            ("CDG", "Paris", "France", "🇫🇷", "Europe", "Charles de Gaulle Airport"),
            ("ORY", "Paris", "France", "🇫🇷", "Europe", "Paris Orly Airport"),
            ("MRS", "Marseille", "France", "🇫🇷", "Europe", "Marseille Provence Airport"),
            ("LYS", "Lyon", "France", "🇫🇷", "Europe", "Lyon-Saint Exupéry Airport"),
            ("ZRH", "Zurich", "Switzerland", "🇨🇭", "Europe", "Zurich Airport"),
            ("GVA", "Geneva", "Switzerland", "🇨🇭", "Europe", "Geneva Airport"),
            ("VIE", "Vienna", "Austria", "🇦🇹", "Europe", "Vienna International Airport"),
            ("MAD", "Madrid", "Spain", "🇪🇸", "Europe", "Adolfo Suárez Madrid-Barajas Airport"),
            ("BCN", "Barcelona", "Spain", "🇪🇸", "Europe", "Josep Tarradellas Barcelona-El Prat"),
            ("LIS", "Lisbon", "Portugal", "🇵🇹", "Europe", "Lisbon Portela Airport"),
            ("MXP", "Milan", "Italy", "🇮🇹", "Europe", "Milan Malpensa Airport"),
            ("FCO", "Rome", "Italy", "🇮🇹", "Europe", "Leonardo da Vinci-Fiumicino Airport"),
            ("ARN", "Stockholm", "Sweden", "🇸🇪", "Europe", "Stockholm Arlanda Airport"),
            ("OSL", "Oslo", "Norway", "🇳🇴", "Europe", "Oslo Airport, Gardermoen"),
            ("CPH", "Copenhagen", "Denmark", "🇩🇰", "Europe", "Copenhagen Airport"),
            ("HEL", "Helsinki", "Finland", "🇫🇮", "Europe", "Helsinki Airport"),
            ("WAW", "Warsaw", "Poland", "🇵🇱", "Europe", "Warsaw Chopin Airport"),
            ("PRG", "Prague", "Czech Republic", "🇨🇿", "Europe", "Václav Havel Airport Prague"),
            ("BUD", "Budapest", "Hungary", "🇭🇺", "Europe", "Budapest Ferenc Liszt Airport"),
            ("ATH", "Athens", "Greece", "🇬🇷", "Europe", "Athens International Airport"),
            ("IST", "Istanbul", "Turkey", "🇹🇷", "Europe", "Istanbul Airport"),
            ("SAW", "Istanbul", "Turkey", "🇹🇷", "Europe", "Sabiha Gökçen Airport")
        ]
    }
    
    private static func loadOtherPops() -> [(String, String, String, String, String, String)] {
        [
            ("SYD", "Sydney", "Australia", "🇦🇺", "Oceania", "Sydney Kingsford Smith Airport"),
            ("MEL", "Melbourne", "Australia", "🇦🇺", "Oceania", "Melbourne Airport"),
            ("BNE", "Brisbane", "Australia", "🇦🇺", "Oceania", "Brisbane Airport"),
            ("PER", "Perth", "Australia", "🇦🇺", "Oceania", "Perth Airport"),
            ("ADL", "Adelaide", "Australia", "🇦🇺", "Oceania", "Adelaide Airport"),
            ("AKL", "Auckland", "New Zealand", "🇳🇿", "Oceania", "Auckland Airport"),
            ("WLG", "Wellington", "New Zealand", "🇳🇿", "Oceania", "Wellington International Airport"),
            ("CHC", "Christchurch", "New Zealand", "🇳🇿", "Oceania", "Christchurch Airport"),
            ("DXB", "Dubai", "United Arab Emirates", "🇦🇪", "Middle East", "Dubai International Airport"),
            ("AUH", "Abu Dhabi", "United Arab Emirates", "🇦🇪", "Middle East", "Abu Dhabi Airport"),
            ("DOH", "Doha", "Qatar", "🇶🇦", "Middle East", "Hamad International Airport"),
            ("RUH", "Riyadh", "Saudi Arabia", "🇸🇦", "Middle East", "King Khalid International Airport"),
            ("JED", "Jeddah", "Saudi Arabia", "🇸🇦", "Middle East", "King Abdulaziz Airport"),
            ("TLV", "Tel Aviv", "Israel", "🇮🇱", "Middle East", "Ben Gurion Airport"),
            ("BOM", "Mumbai", "India", "🇮🇳", "South Asia", "Chhatrapati Shivaji Maharaj Airport"),
            ("DEL", "New Delhi", "India", "🇮🇳", "South Asia", "Indira Gandhi International Airport"),
            ("BLR", "Bengaluru", "India", "🇮🇳", "South Asia", "Kempegowda International Airport"),
            ("MAA", "Chennai", "India", "🇮🇳", "South Asia", "Chennai International Airport"),
            ("HYD", "Hyderabad", "India", "🇮🇳", "South Asia", "Rajiv Gandhi International Airport"),
            ("CCU", "Kolkata", "India", "🇮🇳", "South Asia", "Netaji Subhash Chandra Bose Airport"),
            ("CMB", "Colombo", "Sri Lanka", "🇱🇰", "South Asia", "Bandaranaike International Airport"),
            ("KHI", "Karachi", "Pakistan", "🇵🇰", "South Asia", "Jinnah International Airport"),
            ("ISB", "Islamabad", "Pakistan", "🇵🇰", "South Asia", "Islamabad International Airport"),
            ("JNB", "Johannesburg", "South Africa", "🇿🇦", "Africa", "O. R. Tambo International Airport"),
            ("CPT", "Cape Town", "South Africa", "🇿🇦", "Africa", "Cape Town International Airport"),
            ("NBO", "Nairobi", "Kenya", "🇰🇪", "Africa", "Jomo Kenyatta International Airport"),
            ("LOS", "Lagos", "Nigeria", "🇳🇬", "Africa", "Murtala Muhammed International Airport"),
            ("CAI", "Cairo", "Egypt", "🇪🇬", "Africa", "Cairo International Airport"),
            ("CMN", "Casablanca", "Morocco", "🇲🇦", "Africa", "Mohammed V International Airport")
        ]
    }
}
