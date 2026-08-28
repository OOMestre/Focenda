import SwiftUI

/// Animated circular progress ring for the focus timer with calm, minimal, and organic styling
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
        themeColor: Color = AppTheme.accent,
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
            // Subtle ambient backdrop ring
            Circle()
                .fill(themeColor.opacity(0.03))
                .frame(width: 256, height: 256)

            // Background track ring
            Circle()
                .stroke(
                    themeColor.opacity(0.12),
                    lineWidth: 14
                )

            // Dynamic progress ring with natural soft depth
            Circle()
                .trim(from: 0.0, to: CGFloat(min(self.progress, 1.0)))
                .stroke(
                    themeColor,
                    style: StrokeStyle(lineWidth: 14, lineCap: .round, lineJoin: .round)
                )
                .rotationEffect(.degrees(-90))
                .shadow(
                    color: Color.black.opacity(isRunning ? 0.06 : 0.0),
                    radius: 4,
                    x: 0,
                    y: 2
                )
                .animation(.easeInOut(duration: 0.35), value: progress)

            // Center time readout & mode subtitle
            VStack(spacing: 6) {
                Text(formattedTime)
                    .font(.system(size: 54, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(AppTheme.textPrimary)
                    .contentTransition(.numericText())

                HStack(spacing: 6) {
                    if isRunning {
                        Circle()
                            .fill(themeColor)
                            .frame(width: 6, height: 6)
                            .scaleEffect(isPulsing ? 1.15 : 0.85)
                            .opacity(isPulsing ? 1.0 : 0.6)
                    }

                    Text(subtitle)
                        .font(.headline.weight(.medium))
                        .foregroundStyle(themeColor)
                }
            }
        }
        .frame(width: 260, height: 260)
        .padding(16)
        .onAppear {
            if isRunning {
                withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                    isPulsing = true
                }
            }
        }
        .onChange(of: isRunning) { _, newValue in
            if newValue {
                withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                    isPulsing = true
                }
            } else {
                withAnimation {
                    isPulsing = false
                }
            }
        }
    }
}
