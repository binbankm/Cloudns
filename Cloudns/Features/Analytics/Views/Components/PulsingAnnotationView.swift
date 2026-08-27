import SwiftUI
import CoreLocation

// MARK: - MapAnnotationItem

struct MapAnnotationItem: Identifiable, Sendable {
    let id: UUID
    let countryCode: String
    let coordinate: CLLocationCoordinate2D
    let size: CGFloat
    let requests: Int
    let ratio: Double
    
    init(
        id: UUID = UUID(),
        countryCode: String,
        coordinate: CLLocationCoordinate2D,
        size: CGFloat = 12.0,
        requests: Int,
        ratio: Double
    ) {
        self.id = id
        self.countryCode = countryCode
        self.coordinate = coordinate
        self.size = size
        self.requests = requests
        self.ratio = ratio
    }
}

// MARK: - PulsingAnnotationView

struct PulsingAnnotationView: View {
    // MARK: - Properties
    let item: MapAnnotationItem
    let isSelected: Bool
    @State private var isPulsing = false
    
    init(item: MapAnnotationItem, isSelected: Bool) {
        self.item = item
        self.isSelected = isSelected
    }
    
    private var heatColor: Color {
        switch item.ratio {
        case 0.7...: return .red
        case 0.3..<0.7: return .orange
        case 0.1..<0.3: return .yellow
        default: return .cyan
        }
    }
    
    // MARK: - Body
    var body: some View {
        ZStack {
            Circle()
                .stroke(heatColor, lineWidth: 2)
                .frame(width: item.size, height: item.size)
                .scaleEffect(isPulsing ? 2.5 : 1.0)
                .opacity(isPulsing ? 0.0 : 0.8)
            
            Circle()
                .fill(heatColor)
                .frame(width: item.size, height: item.size)
                .overlay(Circle().stroke(Color.white, lineWidth: isSelected ? 2.5 : 0.5))
                .shadow(color: heatColor.opacity(0.6), radius: isSelected ? 10 : 3, x: 0, y: 0)
                .scaleEffect(isSelected ? 1.3 : 1.0)
        }
        .onAppear {
            withAnimation(Animation.easeOut(duration: 2.0).repeatForever(autoreverses: false)) {
                isPulsing = true
            }
        }
    }
}
