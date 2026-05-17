import Foundation

class ChordProgressionEngine: NSObject, ObservableObject {
    @Published var selectedProgression: ChordProgression = .classic1
    @Published var currentChordIndex: Int = 0

    // コード進行の「特性」を定義（参考用）
    let progressionCharacteristics: [ChordProgression: ProgressionCharacteristic] = [
        .classic1: ProgressionCharacteristic(name: "CLASSIC 1", emotion: .balanced, tendency: .mixed, intervalPreference: [3, 4, 5, 7], darkness: 0.4),
        .classic2: ProgressionCharacteristic(name: "CLASSIC 2", emotion: .sad, tendency: .downward, intervalPreference: [2, 3, 5, 7], darkness: 0.6),
        .classic3: ProgressionCharacteristic(name: "CLASSIC 3", emotion: .balanced, tendency: .mixed, intervalPreference: [3, 4, 5, 7], darkness: 0.4),
        .sadMinor: ProgressionCharacteristic(name: "SAD MINOR", emotion: .sad, tendency: .downward, intervalPreference: [2, 3, 6, 8], darkness: 0.8),
        .dramatic: ProgressionCharacteristic(name: "DRAMATIC", emotion: .tense, tendency: .upward, intervalPreference: [4, 5, 7, 9], darkness: 0.5),
        .hopeful: ProgressionCharacteristic(name: "HOPEFUL", emotion: .happy, tendency: .upward, intervalPreference: [3, 4, 5, 7], darkness: 0.2),
        .melancholic: ProgressionCharacteristic(name: "MELANCHOLIC", emotion: .sad, tendency: .downward, intervalPreference: [2, 3, 5, 7], darkness: 0.7),
        .tense: ProgressionCharacteristic(name: "TENSE", emotion: .tense, tendency: .chaotic, intervalPreference: [1, 3, 6, 8], darkness: 0.9),
        .peaceful: ProgressionCharacteristic(name: "PEACEFUL", emotion: .calm, tendency: .smooth, intervalPreference: [2, 4, 5, 7], darkness: 0.3),
        .power: ProgressionCharacteristic(name: "POWER", emotion: .happy, tendency: .upward, intervalPreference: [5, 7, 12], darkness: 0.1)
    ]

    func generateChordProgression(steps: Int) -> [Int] {
        guard let characteristic = progressionCharacteristics[selectedProgression] else { return [] }

        var result: [Int] = []
        var currentNote = Int.random(in: 0...11)

        for _ in 0..<steps {
            // 特性に基づいてランダムに次のノートを選択
            let nextNote = selectNextNote(
                from: currentNote,
                emotion: characteristic.emotion,
                tendency: characteristic.tendency,
                intervalPreference: characteristic.intervalPreference,
                darkness: characteristic.darkness
            )

            result.append(nextNote)
            currentNote = nextNote
        }

        return result
    }

    private func selectNextNote(
        from current: Int,
        emotion: Emotion,
        tendency: Tendency,
        intervalPreference: [Int],
        darkness: Double
    ) -> Int {
        var candidates: [Int] = []

        // テンデンシーに基づいて候補を生成
        switch tendency {
        case .upward:
            // 上昇傾向：上の音を優先
            for offset in 1...12 {
                if intervalPreference.contains(offset % 12) {
                    candidates.append((current + offset) % 24)
                }
            }

        case .downward:
            // 下降傾向：下の音を優先
            for offset in 1...12 {
                if intervalPreference.contains(offset % 12) {
                    candidates.append((current - offset + 24) % 24)
                }
            }

        case .smooth:
            // スムーズ：小さなインターバル
            for offset in [-2, -1, 1, 2] {
                let candidate = (current + offset + 24) % 24
                if intervalPreference.contains(abs(offset) % 12) {
                    candidates.append(candidate)
                }
            }

        case .mixed:
            // ミックス：様々なインターバル
            for offset in intervalPreference {
                candidates.append((current + offset) % 24)
                candidates.append((current - offset + 24) % 24)
            }

        case .chaotic:
            // カオティック：ランダムなジャンプ
            for _ in 0..<8 {
                candidates.append(Int.random(in: 0...23))
            }
        }

        // ダークネスに基づいてフィルター
        let filtered = candidates.filter { note in
            let isLow = note < 8
            let isDarkness = Double.random(in: 0...1) < darkness
            return isDarkness == isLow
        }

        return filtered.randomElement() ?? Int.random(in: 0...23)
    }
}

struct ProgressionCharacteristic {
    let name: String
    let emotion: Emotion
    let tendency: Tendency
    let intervalPreference: [Int]
    let darkness: Double  // 0=bright, 1=dark
}

enum Emotion: String {
    case happy, sad, calm, tense, balanced
}

enum Tendency: String {
    case upward, downward, smooth, mixed, chaotic
}

enum ChordProgression: String, CaseIterable {
    case classic1 = "CLASSIC 1"      // I-V-vi-IV
    case classic2 = "CLASSIC 2"      // vi-IV-I-V
    case classic3 = "CLASSIC 3"      // I-vi-IV-V
    case sadMinor = "SAD MINOR"      // vi-ii-V-vi
    case dramatic = "DRAMATIC"       // I-IV-V-I
    case hopeful = "HOPEFUL"         // V-I-IV-I
    case melancholic = "MELANCHOLIC" // vi-IV-I-V
    case tense = "TENSE"            // I-IV(dim)-vi-V(dim)
    case peaceful = "PEACEFUL"       // IV-I-vi-IV
    case power = "POWER"            // I-V-I-V
}
