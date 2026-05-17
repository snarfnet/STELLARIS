import Foundation

class PresetManager: NSObject, ObservableObject {
    @Published var presets: [SynthPreset] = []
    @Published var selectedPreset: String = "DEFAULT"

    private let userDefaults = UserDefaults.standard
    private let presetsKey = "STELLARIS_PRESETS"

    override init() {
        super.init()
        loadPresets()
    }

    func savePreset(
        name: String,
        frequency: Double,
        waveform: Waveform,
        cutoff: Double,
        resonance: Double,
        drive: Double,
        attackTime: Double,
        decayTime: Double,
        sustainLevel: Double,
        releaseTime: Double,
        reverbMix: Double,
        delayMix: Double,
        chorusMix: Double
    ) {
        let preset = SynthPreset(
            id: UUID().uuidString,
            name: name,
            frequency: frequency,
            waveform: waveform,
            cutoff: cutoff,
            resonance: resonance,
            drive: drive,
            attackTime: attackTime,
            decayTime: decayTime,
            sustainLevel: sustainLevel,
            releaseTime: releaseTime,
            reverbMix: reverbMix,
            delayMix: delayMix,
            chorusMix: chorusMix,
            createdAt: Date()
        )

        // 同名のプリセットがあれば削除
        presets.removeAll { $0.name == name }
        presets.append(preset)

        persistPresets()
    }

    func loadPreset(name: String) -> SynthPreset? {
        return presets.first { $0.name == name }
    }

    func deletePreset(name: String) {
        presets.removeAll { $0.name == name }
        persistPresets()
    }

    private func persistPresets() {
        if let encoded = try? JSONEncoder().encode(presets) {
            userDefaults.set(encoded, forKey: presetsKey)
        }
    }

    private func loadPresets() {
        if let data = userDefaults.data(forKey: presetsKey),
           let decoded = try? JSONDecoder().decode([SynthPreset].self, from: data) {
            presets = decoded
        } else {
            // デフォルトプリセット
            createDefaultPresets()
        }
    }

    private func createDefaultPresets() {
        let defaults = [
            SynthPreset(
                id: UUID().uuidString,
                name: "WARM PAD",
                frequency: 440,
                waveform: .sine,
                cutoff: 4000,
                resonance: 0.3,
                drive: 0.1,
                attackTime: 0.5,
                decayTime: 0.8,
                sustainLevel: 0.7,
                releaseTime: 1.5,
                reverbMix: 0.5,
                delayMix: 0.2,
                chorusMix: 0.3,
                createdAt: Date()
            ),
            SynthPreset(
                id: UUID().uuidString,
                name: "ACID BASS",
                frequency: 220,
                waveform: .sawtooth,
                cutoff: 3000,
                resonance: 0.8,
                drive: 0.6,
                attackTime: 0.01,
                decayTime: 0.4,
                sustainLevel: 0.5,
                releaseTime: 0.2,
                reverbMix: 0.2,
                delayMix: 0.1,
                chorusMix: 0.0,
                createdAt: Date()
            ),
            SynthPreset(
                id: UUID().uuidString,
                name: "LEAD",
                frequency: 880,
                waveform: .square,
                cutoff: 8000,
                resonance: 0.6,
                drive: 0.3,
                attackTime: 0.05,
                decayTime: 0.2,
                sustainLevel: 0.8,
                releaseTime: 0.3,
                reverbMix: 0.3,
                delayMix: 0.4,
                chorusMix: 0.2,
                createdAt: Date()
            )
        ]

        presets = defaults
        persistPresets()
    }
}

struct SynthPreset: Codable, Identifiable {
    let id: String
    let name: String
    let frequency: Double
    let waveform: Waveform
    let cutoff: Double
    let resonance: Double
    let drive: Double
    let attackTime: Double
    let decayTime: Double
    let sustainLevel: Double
    let releaseTime: Double
    let reverbMix: Double
    let delayMix: Double
    let chorusMix: Double
    let createdAt: Date
}
