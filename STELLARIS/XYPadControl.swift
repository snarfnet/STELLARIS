import Foundation
import SwiftUI

class XYPadControl: NSObject, ObservableObject {
    @Published var xValue: Double = 0.5
    @Published var yValue: Double = 0.5
    @Published var xTarget: XYTarget = .cutoff
    @Published var yTarget: XYTarget = .resonance
    @Published var isEnabled: Bool = false

    enum XYTarget: String, CaseIterable {
        case cutoff = "CUTOFF"
        case resonance = "RESO"
        case drive = "DRIVE"
        case reverbMix = "REVERB"
        case delayMix = "DELAY"
        case chorusMix = "CHORUS"
        case attackTime = "ATTACK"
        case releaseTime = "RELEASE"
        case lfoRate = "LFO_RATE"
        case lfoDepth = "LFO_DEPTH"
        case frequency = "FREQ"
        case sustain = "SUSTAIN"
    }

    func getValueForTarget(_ target: XYTarget, axisValue: Double) -> Double {
        switch target {
        case .cutoff:
            return 100 + (axisValue * 14900)  // 100-15000 Hz
        case .resonance:
            return axisValue  // 0-1
        case .drive:
            return axisValue  // 0-1
        case .reverbMix:
            return axisValue  // 0-1
        case .delayMix:
            return axisValue  // 0-1
        case .chorusMix:
            return axisValue  // 0-1
        case .attackTime:
            return 0.01 + (axisValue * 1.99)  // 0.01-2.0
        case .releaseTime:
            return 0.01 + (axisValue * 3.99)  // 0.01-4.0
        case .lfoRate:
            return 0.1 + (axisValue * 19.9)  // 0.1-20 Hz
        case .lfoDepth:
            return axisValue  // 0-1
        case .frequency:
            return 20 + (axisValue * 1980)  // 20-2000 Hz
        case .sustain:
            return axisValue  // 0-1
        }
    }
}

struct XYPadView: View {
    @ObservedObject var control: XYPadControl
    let size: CGFloat = 200

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.black.opacity(0.3))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )

                // Crosshairs
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Rectangle()
                            .fill(Color.white.opacity(0.1))
                            .frame(width: 1)
                        Spacer()
                    }
                    Spacer()
                }

                HStack {
                    Spacer()
                    VStack {
                        Spacer()
                        Rectangle()
                            .fill(Color.white.opacity(0.1))
                            .frame(height: 1)
                        Spacer()
                    }
                    Spacer()
                }

                // Control point
                Circle()
                    .fill(Color.stellarisTeal)
                    .frame(width: 16, height: 16)
                    .offset(
                        x: (control.xValue - 0.5) * size,
                        y: (0.5 - control.yValue) * size
                    )
            }
            .frame(width: size, height: size)
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        let rect = CGRect(x: -size/2, y: -size/2, width: size, height: size)
                        let newX = (value.location.x - rect.midX) / (size / 2)
                        let newY = (rect.midY - value.location.y) / (size / 2)

                        control.xValue = max(0, min(1, newX))
                        control.yValue = max(0, min(1, newY))
                    }
            )

            HStack(spacing: 12) {
                VStack(spacing: 4) {
                    Text(control.xTarget.rawValue)
                        .font(.system(size: 8, weight: .bold, design: .monospaced))
                        .foregroundColor(.white.opacity(0.6))
                    Text("\(control.xValue * 100, specifier: "%.0f")%")
                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                        .foregroundColor(.stellarisTeal)
                }

                Spacer()

                VStack(spacing: 4) {
                    Text(control.yTarget.rawValue)
                        .font(.system(size: 8, weight: .bold, design: .monospaced))
                        .foregroundColor(.white.opacity(0.6))
                    Text("\(control.yValue * 100, specifier: "%.0f")%")
                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                        .foregroundColor(.stellarisAcid)
                }
            }
        }
    }
}
