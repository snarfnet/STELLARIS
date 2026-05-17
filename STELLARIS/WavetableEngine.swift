import Foundation

class WavetableEngine: NSObject, ObservableObject {
    @Published var isEnabled: Bool = false
    @Published var morphAmount: Double = 0.5  // 0 = waveform1, 1 = waveform2
    @Published var waveform1: Waveform = .sine
    @Published var waveform2: Waveform = .square
    @Published var unison: Int = 1  // 1-7 voices with slight detuning
    @Published var detune: Double = 0.01  // Detune amount for unison

    private let voicePitch: [Double] = [
        -0.05, -0.03, -0.01, 0.0, 0.01, 0.03, 0.05
    ]

    func generateMorphedWaveform(phase: Double, morphAmount: Double) -> Double {
        let sample1 = generateWaveformSample(phase: phase, waveform: waveform1)
        let sample2 = generateWaveformSample(phase: phase, waveform: waveform2)

        return sample1 * (1.0 - morphAmount) + sample2 * morphAmount
    }

    func generateUnisonWaveform(phase: Double) -> Double {
        guard unison > 1 else {
            return generateMorphedWaveform(phase: phase, morphAmount: morphAmount)
        }

        var sample: Double = 0.0
        let voiceSample = 1.0 / Double(unison)

        for i in 0..<unison {
            let detuneAmount = voicePitch[i] * detune
            let detunePhase = phase * (1.0 + detuneAmount)
            let voiceOutput = generateMorphedWaveform(phase: detunePhase, morphAmount: morphAmount)
            sample += voiceOutput * voiceSample
        }

        return sample
    }

    private func generateWaveformSample(phase: Double, waveform: Waveform) -> Double {
        let normalizedPhase = phase.truncatingRemainder(dividingBy: 2.0 * .pi)

        switch waveform {
        case .sine:
            return sin(normalizedPhase)

        case .square:
            return normalizedPhase < .pi ? 0.8 : -0.8

        case .sawtooth:
            return 2.0 * (normalizedPhase / (2.0 * .pi) - floor(normalizedPhase / (2.0 * .pi) + 0.5))

        case .triangle:
            let normalized = normalizedPhase / (2.0 * .pi)
            return abs(4.0 * (normalized - floor(normalized + 0.25))) - 2.0
        }
    }

    func getMorphName() -> String {
        let percent = Int(morphAmount * 100)
        return "\(waveform1.rawValue)/\(waveform2.rawValue) \(percent)%"
    }
}
