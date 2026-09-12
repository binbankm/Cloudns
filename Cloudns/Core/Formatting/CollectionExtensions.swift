import Foundation

// MARK: - RangeReplaceableCollection + IndexSet Extension (Pure Foundation)

public extension RangeReplaceableCollection where Self: MutableCollection, Index == Int {
    /// Removes the elements at the specified offsets in reverse order to preserve valid indexing.
    /// Pure Foundation implementation without requiring SwiftUI framework import in ViewModels.
    mutating func remove(atOffsets offsets: IndexSet) {
        for index in offsets.reversed() {
            remove(at: index)
        }
    }
}
