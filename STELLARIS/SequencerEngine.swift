import Foundation

class SequencerEngine: NSObject, ObservableObject {
    @Published var tempo: Double = 120.0
    @Published var scale: MusicalScale = .major
    @Published var rootNote: Int = 0  // 0=C, 1=D, 2=E, etc.
    @Published var sequence: [Int] = Array(repeating: 0, count: 32)
    @Published var isSequencerPlaying = false
    @Published var currentStep: Int = 0
    @Published var stepCount: Int = 32  // 16 or 32

    private var sequencerTimer: Timer?
    private var stepIndex = 0
    private let notes = [261.63, 293.66, 329.63, 349.23, 392.00, 440.00, 493.88, 523.25]

    func generateMelody() {
        let scaleOffsets = getScaleOffsets()

        var melody: [Int] = []
        for _ in 0..<stepCount {
            let randomOffset = scaleOffsets.randomElement() ?? 0
            let octave = Int.random(in: 0...2)
            let midiNote = (rootNote + randomOffset + (octave * 12)) % 127
            melody.append(midiNote)
        }

        sequence = melody
    }

    func setStepCount(_ count: Int) {
        stepCount = count
        sequence = Array(repeating: 0, count: count)
    }

    func startSequencer(onNoteChange: @escaping (Int, Int) -> Void) {
        isSequencerPlaying = true
        stepIndex = 0
        currentStep = 0

        let secondsPerStep = (60.0 / tempo) / 4.0
        sequencerTimer = Timer.scheduledTimer(withTimeInterval: secondsPerStep, repeats: true) { [weak self] _ in
            guard let self = self else { return }

            let step = self.stepIndex % self.stepCount
            self.currentStep = step
            let midiNote = self.sequence[step]

            onNoteChange(midiNote, step)
            self.stepIndex += 1
        }
    }

    func stopSequencer() {
        sequencerTimer?.invalidate()
        sequencerTimer = nil
        isSequencerPlaying = false
        currentStep = 0
    }

    func setSequenceNote(_ step: Int, _ midiNote: Int) {
        if step < sequence.count {
            sequence[step] = midiNote
        }
    }

    private func getScaleOffsets() -> [Int] {
        switch scale {
        case .major:
            return [0, 2, 4, 5, 7, 9, 11]
        case .minor:
            return [0, 2, 3, 5, 7, 8, 10]
        case .pentatonic:
            return [0, 2, 4, 7, 9]
        case .blues:
            return [0, 3, 5, 6, 7, 10]
        case .dorian:
            return [0, 2, 3, 5, 7, 9, 10]
        }
    }

    func frequencyFromMidiNote(_ midiNote: Int) -> Double {
        return 440.0 * pow(2.0, Double(midiNote - 69) / 12.0)
    }
}

enum MusicalScale: String, CaseIterable {
    case major = "MAJOR"
    case minor = "MINOR"
    case pentatonic = "PENTA"
    case blues = "BLUES"
    case dorian = "DORIAN"
}
