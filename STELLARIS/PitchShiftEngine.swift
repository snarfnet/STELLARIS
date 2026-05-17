import Foundation

class PitchShiftEngine: NSObject, ObservableObject {
    @Published var isEnabled: Bool = false
    @Published var amount: Double = 0.0  // -12 to +12 semitones
    @Published var quality: PitchQuality = .medium
    @Published var voiceCount: Int = 1  // 1-3 pitch shifted voices
    @Published var voiceSpacing: Double = 7.0  // semitones between voices (1-12)

    enum PitchQuality: String, CaseIterable {
        case low = "FAST"
        case medium = "MEDIUM"
        case high = "QUALITY"
    }

    func getPitchMultiplier(_ semitones: Double) -> Double {
        return pow(2.0, semitones / 12.0)
    }

    func getVoicePitchShifts() -> [Double] {
        var pitches: [Double] = [amount]

        guard voiceCount > 1 else { return pitches }

        for i in 1..<voiceCount {
            let shift = amount + (Double(i) * voiceSpacing)
            pitches.append(shift)
        }

        return pitches
    }

    func getVoiceGain() -> Double {
        return 1.0 / Double(voiceCount)
    }

    func getPitchShiftName() -> String {
        let direction = amount > 0 ? "+" : ""
        let rounded = Int(amount)
        return "\(direction)\(rounded) semitones"
    }
}
