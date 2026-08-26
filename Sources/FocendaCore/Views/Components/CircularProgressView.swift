import SwiftUI

/// Animated circular progress ring for the focus timer
public struct CircularProgressView: View {
    public let progress: Double
    public let formattedTime: String
    public let subtitle: String
    public let themeColor: Color

    public init(
        progress: Double,
        formattedTime: String,
        subtitle: String,
        themeColor: Color = .indigo
    ) {
        self.progress = progress
        self.formattedTime = formattedTime
        self.subtitle = subtitle
        self.themeColor = themeColor
    }

    public var body: some View {
        ZStack {
            // Background track ring
            Circle()
                .stroke(
                    themeColor.opacity(0.12),
                    lineWidth: 16
                )

            // Dynamic progress ring
            Circle()
                .trim(from: 0.0, to: CGFloat(min(self.progress, 1.0)))
                .stroke(
                    AngularGradient(
                        gradient: Gradient(colors: [themeColor.opacity(0.8), themeColor]),
                        center: .center,
                        startAngle: .degrees(0),
                        endAngle: .degrees(360)
                    ),
                    style: StrokeStyle(lineWidth: 16, lineCap: .round, lineJoin: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.3), value: progress)

            // Center time readout & mode subtitle
            VStack(spacing: 8) {
                Text(formattedTime)
                    .font(.system(size: 56, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(.primary)

                Text(subtitle)
                    .font(.headline)
                    .foregroundStyle(themeColor)
            }
        }
        .frame(width: 260, height: 260)
        .padding(16)
    }
}
