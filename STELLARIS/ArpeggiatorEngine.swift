import Foundation

class ArpeggiatorEngine: NSObject, ObservableObject {
    @Published var isEnabled: Bool = false
    @Published var pattern: ArpPattern = .up
    @Published var speed: Double = 1.0  // 0.5x to 2x the sequencer tempo
    @Published var octaveRange: Int = 1  // 1-3 octaves
    @Published var noteCount: Int = 0    // Number of notes in current arpeggio

    private var currentNotes: [Int] = []
    private var currentArpIndex = 0

    func startArpeggio(baseNotes: [Int]) {
        currentNotes = baseNotes.sorted()
        currentArpIndex = 0
        noteCount = baseNotes.count
    }

    func getNextArpeggioNote() -> Int? {
        guard !currentNotes.isEmpty && isEnabled else { return nil }

        let notes = generateArpeggio()
        guard !notes.isEmpty else { return nil }

        let note = notes[currentArpIndex % notes.count]
        currentArpIndex += 1

        return note
    }

    private func generateArpeggio() -> [Int] {
        var arpeggioNotes: [Int] = []

        // Generate notes across octave range
        for octave in 0..<octaveRange {
            for baseNote in currentNotes {
                arpeggioNotes.append(baseNote + (octave * 12))
            }
        }

        // Apply pattern
        switch pattern {
        case .up:
            return arpeggioNotes.sorted()

        case .down:
            return arpeggioNotes.sorted(by: >)

        case .upDown:
            let sorted = arpeggioNotes.sorted()
            var upDown = sorted
            upDown.append(contentsOf: sorted.dropFirst().reversed())
            return upDown

        case .random:
            return arpeggioNotes.shuffled()

        case .pingerPong:
            let sorted = arpeggioNotes.sorted()
            var pingPong: [Int] = []
            var forward = true
            for _ in 0..<(sorted.count * 2 - 1) {
                pingPong.append(sorted[forward ? pingPong.count % sorted.count : sorted.count - 1 - (pingPong.count % sorted.count)])
                if pingPong.count % sorted.count == 0 {
                    forward = !forward
                }
            }
            return pingPong
        }
    }

    func reset() {
        currentArpIndex = 0
        currentNotes = []
    }
}

enum ArpPattern: String, CaseIterable {
    case up = "UP"
    case down = "DOWN"
    case upDown = "UP-DN"
    case random = "RND"
    case pingerPong = "PING"
}
