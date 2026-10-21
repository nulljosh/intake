import SwiftUI

/// Every empty screen gets Aski, the mascot (brand/mascot.svg), instead of a stock symbol.
struct EmptyState: View {
    let title: String
    let message: String
    var size: CGFloat = 96

    var body: some View {
        ContentUnavailableView {
            VStack(spacing: size > 60 ? 16 : 8) {
                Image("Mascot").resizable().scaledToFit().frame(width: size, height: size).accessibilityHidden(true)
                Text(title).font(size > 60 ? .title2.weight(.semibold) : .headline)
            }
        } description: {
            Text(message)
        }
    }
}
