import Foundation

class MultiTrackEngine: NSObject, ObservableObject {
    @Published var tracks: [SequenceTrack] = []
    @Published var selectedTrack: Int = 0
    @Published var isEnabled: Bool = false
    @Published var maxTracks: Int = 4

    private var trackTimers: [Timer?] = []

    override init() {
        super.init()
        initializeTracks()
    }

    private func initializeTracks() {
        tracks = (0..<maxTracks).map { i in
            SequenceTrack(
                id: i,
                name: "TRACK \(i + 1)",
                sequence: Array(repeating: 0, count: 32),
                isActive: i == 0
            )
        }
        trackTimers = Array(repeating: nil, count: maxTracks)
    }

    func toggleTrack(_ index: Int) {
        guard index < tracks.count else { return }
        tracks[index].isActive.toggle()
    }

    func setTrackSequence(_ trackIndex: Int, _ sequence: [Int]) {
        guard trackIndex < tracks.count else { return }
        tracks[trackIndex].sequence = sequence
    }

    func generateMelodyForTrack(_ trackIndex: Int, scale: MusicalScale, rootNote: Int) {
        guard trackIndex < tracks.count else { return }
        let scaleOffsets = getScaleOffsets(scale)

        var melody: [Int] = []
        for _ in 0..<tracks[trackIndex].sequence.count {
            let randomOffset = scaleOffsets.randomElement() ?? 0
            let octave = Int.random(in: 0...2)
            let midiNote = (rootNote + randomOffset + (octave * 12)) % 127
            melody.append(midiNote)
        }

        tracks[trackIndex].sequence = melody
    }

    func startAllTracks(onNoteChange: @escaping (Int, Int, Int) -> Void) {
        // Parameters: trackIndex, midiNote, step

        for (index, track) in tracks.enumerated() {
            guard track.isActive else { continue }

            var stepIndex = 0
            let secondsPerStep = (60.0 / track.tempo) / 4.0

            trackTimers[index] = Timer.scheduledTimer(withTimeInterval: secondsPerStep, repeats: true) { [weak self] _ in
                guard let self = self else { return }
                let step = stepIndex % track.sequence.count
                let midiNote = track.sequence[step]

                onNoteChange(index, midiNote, step)
                stepIndex += 1
            }
        }
    }

    func stopAllTracks() {
        for i in 0..<trackTimers.count {
            trackTimers[i]?.invalidate()
            trackTimers[i] = nil
        }
    }

    private func getScaleOffsets(_ scale: MusicalScale) -> [Int] {
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

    deinit {
        stopAllTracks()
    }
}

struct SequenceTrack: Identifiable {
    let id: Int
    var name: String
    var sequence: [Int]
    var isActive: Bool
    var tempo: Double = 120.0
    var octaveOffset: Int = 0
    var volume: Double = 0.8
}
