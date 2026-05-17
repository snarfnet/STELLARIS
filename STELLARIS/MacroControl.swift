import Foundation

class MacroControl: NSObject, ObservableObject {
    @Published var value: Double = 0.5
    @Published var target1: MacroTarget = .cutoff
    @Published var target2: MacroTarget = .resonance
    @Published var target3: MacroTarget = .reverbMix
    @Published var isEnabled: Bool = false

    enum MacroTarget: String, CaseIterable {
        case cutoff = "CUTOFF"
        case resonance = "RESO"
        case drive = "DRIVE"
        case reverbMix = "REVERB"
        case delayMix = "DELAY"
        case chorusMix = "CHORUS"
        case attackTime = "ATTACK"
        case decayTime = "DECAY"
        case sustainLevel = "SUSTAIN"
        case releaseTime = "RELEASE"
        case lfoRate = "LFO_RATE"
        case lfoDepth = "LFO_DEPTH"
    }

    func getValueForTarget(_ target: MacroTarget) -> Double {
        switch target {
        case .cutoff:
            return 100 + (value * 14900)  // 100-15000 Hz
        case .resonance:
            return value  // 0-1
        case .drive:
            return value  // 0-1
        case .reverbMix:
            return value  // 0-1
        case .delayMix:
            return value  // 0-1
        case .chorusMix:
            return value  // 0-1
        case .attackTime:
            return 0.01 + (value * 1.99)  // 0.01-2.0
        case .decayTime:
            return 0.01 + (value * 1.99)  // 0.01-2.0
        case .sustainLevel:
            return value  // 0-1
        case .releaseTime:
            return 0.01 + (value * 3.99)  // 0.01-4.0
        case .lfoRate:
            return 0.1 + (value * 19.9)  // 0.1-20 Hz
        case .lfoDepth:
            return value  // 0-1
        }
    }
}
