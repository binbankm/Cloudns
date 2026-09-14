import Foundation

public struct ZoneSparklineCache: Codable, Sendable {
    public let points: [Double]
    public let totalRequests: Int

    public init(points: [Double], totalRequests: Int) {
        self.points = points
        self.totalRequests = totalRequests
    }
}
