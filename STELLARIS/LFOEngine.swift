import Foundation

class LFOEngine: NSObject, ObservableObject {
    @Published var rate: Double = 5.0        // 0.1 - 20 Hz
    @Published var depth: Double = 0.5       // 0 - 1
    @Published var waveform: LFOWaveform = .sine
    @Published var target: LFOTarget = .cutoff
    @Published var isEnabled: Bool = false

    private var phase: Double = 0
    private let sampleRate: Double = 44100

    func getValue() -> Double {
        let value = generateWaveform(phase: phase)
        phase += (rate / sampleRate)
        if phase >= 1.0 { phase -= 1.0 }
        return value * depth
    }

    private func generateWaveform(phase: Double) -> Double {
        switch waveform {
        case .sine:
            return sin(phase * 2 * .pi)

        case .triangle:
            return abs(4 * (phase - floor(phase + 0.25))) - 2

        case .sawtooth:
            return 2 * (phase - floor(phase + 0.5))

        case .square:
            return phase < 0.5 ? 1.0 : -1.0

        case .random:
            return Double.random(in: -1...1)
        }
    }
}

enum LFOWaveform: String, CaseIterable {
    case sine = "SIN"
    case triangle = "TRI"
    case sawtooth = "SAW"
    case square = "SQR"
    case random = "RND"
}

enum LFOTarget: String, CaseIterable {
    case cutoff = "CUTOFF"
    case resonance = "RESO"
    case amplitude = "AMP"
    case pitch = "PITCH"
    case all = "ALL"
}
