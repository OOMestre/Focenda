import SwiftUI

/// Animated circular progress ring for the focus timer with pulsing glow effects
public struct CircularProgressView: View {
    public let progress: Double
    public let formattedTime: String
    public let subtitle: String
    public let themeColor: Color
    public let isRunning: Bool

    @State private var isPulsing: Bool = false

    public init(
        progress: Double,
        formattedTime: String,
        subtitle: String,
        themeColor: Color = .indigo,
        isRunning: Bool = false
    ) {
        self.progress = progress
        self.formattedTime = formattedTime
        self.subtitle = subtitle
        self.themeColor = themeColor
        self.isRunning = isRunning
    }

    public var body: some View {
        ZStack {
            // Subtle breathing background glow when active
            if isRunning {
                Circle()
                    .fill(
                        RadialGradient(
                            gradient: Gradient(colors: [
                                themeColor.opacity(isPulsing ? 0.18 : 0.08),
                                themeColor.opacity(0.0)
                            ]),
                            center: .center,
                            startRadius: 70,
                            endRadius: 155
                        )
                    )
                    .frame(width: 300, height: 300)
                    .scaleEffect(isPulsing ? 1.05 : 0.98)
                    .animation(
                        .easeInOut(duration: 2.0).repeatForever(autoreverses: true),
                        value: isPulsing
                    )
            }

            // Background track ring
            Circle()
                .stroke(
                    themeColor.opacity(0.12),
                    lineWidth: 16
                )

            // Dynamic progress ring with glowing shadow
            Circle()
                .trim(from: 0.0, to: CGFloat(min(self.progress, 1.0)))
                .stroke(
                    AngularGradient(
                        gradient: Gradient(colors: [
                            themeColor.opacity(0.85),
                            themeColor,
                            themeColor.opacity(0.95)
                        ]),
                        center: .center,
                        startAngle: .degrees(0),
                        endAngle: .degrees(360)
                    ),
                    style: StrokeStyle(lineWidth: 16, lineCap: .round, lineJoin: .round)
                )
                .rotationEffect(.degrees(-90))
                .shadow(
                    color: isRunning ? themeColor.opacity(isPulsing ? 0.6 : 0.25) : .clear,
                    radius: isPulsing ? 14 : 8,
                    x: 0,
                    y: 0
                )
                .animation(.easeInOut(duration: 0.35), value: progress)

            // Center time readout & mode subtitle
            VStack(spacing: 8) {
                Text(formattedTime)
                    .font(.system(size: 56, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(.primary)
                    .contentTransition(.numericText())

                HStack(spacing: 6) {
                    if isRunning {
                        Circle()
                            .fill(themeColor)
                            .frame(width: 7, height: 7)
                            .scaleEffect(isPulsing ? 1.2 : 0.8)
                            .opacity(isPulsing ? 1.0 : 0.5)
                    }

                    Text(subtitle)
                        .font(.headline)
                        .foregroundStyle(themeColor)
                }
            }
        }
        .frame(width: 260, height: 260)
        .padding(16)
        .onAppear {
            if isRunning {
                isPulsing = true
            }
        }
        .onChange(of: isRunning) { _, newValue in
            isPulsing = newValue
        }
    }
}
