import SwiftUI

struct WaveformVisualizer: View {
    let frequency: Double
    let waveform: Waveform
    let color: Color

    var body: some View {
        Canvas { context in
            let width = 300.0
            let height = 80.0
            let samplesPerCycle = 60

            var path = Path()
            var isFirstPoint = true

            for i in 0..<samplesPerCycle {
                let phase = Double(i) / Double(samplesPerCycle) * 2 * .pi
                let sample = generateSample(phase: phase)

                let x = (Double(i) / Double(samplesPerCycle)) * width
                let y = height / 2 - sample * height / 2

                if isFirstPoint {
                    path.move(to: CGPoint(x: x, y: y))
                    isFirstPoint = false
                } else {
                    path.addLine(to: CGPoint(x: x, y: y))
                }
            }

            context.stroke(path, with: .color(color), lineWidth: 2)
        }
        .frame(height: 80)
        .background(Color.black.opacity(0.3))
        .cornerRadius(6)
    }

    private func generateSample(phase: Double) -> Double {
        switch waveform {
        case .sine:
            return sin(phase)
        case .square:
            return phase < .pi ? 0.8 : -0.8
        case .sawtooth:
            return 2 * (phase / (2 * .pi) - floor(phase / (2 * .pi) + 0.5))
        case .triangle:
            return abs(4 * (phase / (2 * .pi) - floor(phase / (2 * .pi) + 0.25))) - 2
        }
    }
}

struct SpectrumVisualizer: View {
    let frequencies: [Double]
    let color: Color

    var body: some View {
        Canvas { context in
            let width = 300.0
            let height = 60.0
            let barCount = min(16, frequencies.count)

            for i in 0..<barCount {
                let freq = frequencies[i]
                let normalized = min(1.0, freq / 2000.0)
                let barHeight = normalized * height

                let x = CGFloat(i) / CGFloat(barCount) * width
                let barWidth = width / CGFloat(barCount) * 0.8

                let rect = CGRect(
                    x: x,
                    y: height - barHeight,
                    width: barWidth,
                    height: barHeight
                )

                context.fill(
                    Path(roundedRect: rect, cornerSize: CGSize(width: 2, height: 2)),
                    with: .color(color.opacity(0.5 + normalized * 0.5))
                )
            }
        }
        .frame(height: 60)
        .background(Color.black.opacity(0.3))
        .cornerRadius(6)
    }
}

struct MeterView: View {
    let value: Double
    let color: Color
    let label: String

    var body: some View {
        VStack(spacing: 4) {
            Text(label)
                .font(.system(size: 9, weight: .bold, design: .monospaced))
                .foregroundColor(.white.opacity(0.6))

            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.white.opacity(0.1))

                RoundedRectangle(cornerRadius: 2)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [color, color.opacity(0.5)]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: CGFloat(value) * 100)
            }
            .frame(height: 8)

            Text("\(value * 100, specifier: "%.0f")%")
                .font(.system(size: 8, weight: .bold, design: .monospaced))
                .foregroundColor(color)
        }
    }
}

struct EqualizerView: View {
    @Binding var frequencies: [Double]
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            HStack(alignment: .bottom, spacing: 4) {
                ForEach(0..<frequencies.count, id: \.self) { index in
                    VStack(spacing: 2) {
                        Slider(value: $frequencies[index], in: 0...1)
                            .tint(color)
                            .rotationEffect(.degrees(180))
                            .scaleEffect(x: 1, y: -1, anchor: .center)

                        Text("\(index * 2)k")
                            .font(.system(size: 7, weight: .bold, design: .monospaced))
                            .foregroundColor(.white.opacity(0.5))
                    }
                }
            }
        }
        .padding(8)
        .background(Color.black.opacity(0.2))
        .cornerRadius(6)
    }
}
