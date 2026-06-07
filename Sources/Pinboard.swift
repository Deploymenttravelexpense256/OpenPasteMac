import SwiftUI

struct Pinboard: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var name: String
    var colorHex: String
    var itemIDs: [String] = []

    var color: Color { Color(hex: colorHex) }

    static let palette = ["4F86F7", "34C759", "AF52DE", "FF9500", "FF3B30", "00C7BE", "FFD60A", "FF6B35"]
}

extension Color {
    init(hex: String) {
        let h = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var val: UInt64 = 0
        Scanner(string: h).scanHexInt64(&val)
        self.init(
            red:   Double((val >> 16) & 0xFF) / 255.0,
            green: Double((val >> 8)  & 0xFF) / 255.0,
            blue:  Double( val        & 0xFF) / 255.0
        )
    }
}
