import Foundation
import AVFoundation

class SynthEngine: NSObject, ObservableObject {
    @Published var isPlaying = false
    @Published var frequency: Double = 440.0
    @Published var waveform: Waveform = .sine
    @Published var cutoff: Double = 8000.0
    @Published var resonance: Double = 0.5
    @Published var drive: Double = 0.0
    @Published var attackTime: Double = 0.05
    @Published var decayTime: Double = 0.3
    @Published var sustainLevel: Double = 0.7
    @Published var releaseTime: Double = 0.5
    @Published var reverbMix: Double = 0.3
    @Published var delayMix: Double = 0.2
    @Published var chorusMix: Double = 0.1

    private var engine: AVAudioEngine?
    private var mixer: AVAudioMixerNode?
    private var filter: AVAudioUnitEQ?
    private var reverb: AVAudioUnitReverb?
    private var delay: AVAudioUnitDelay?
    private var chorus: AVAudioUnitDistortion?
    private var playerNode: AVAudioPlayerNode?
    private var playerNodes: [AVAudioPlayerNode] = []

    // ポリフォニー対応
    private var activeVoices: [(frequency: Double, playerNode: AVAudioPlayerNode, startTime: Date)] = []
    private let maxVoices = 8

    private var phase: Float = 0
    private var phaseIncrement: Float = 0
    private var sampleRate: Float = 44100
    private var envelopePhase: Double = 0
    private var noteOnTime: Date?
    private var generationID: Int = 0

    override init() {
        super.init()
    }

    private func setupAudio() {
        guard engine == nil else { return }

        engine = AVAudioEngine()
        mixer = engine?.mainMixerNode

        // EQ フィルター
        filter = AVAudioUnitEQ(numberOfBands: 1)
        if let filter = filter {
            filter.bands[0].filterType = .lowPass
            filter.bands[0].frequency = Float(cutoff)
            filter.bands[0].gain = 0
            filter.bands[0].bandwidth = 1
        }

        // リバーブ
        reverb = AVAudioUnitReverb()
        reverb?.loadFactoryPreset(.mediumHall)
        reverb?.wetDryMix = 35

        if let engine = engine, let mixer = mixer, let filter = filter, let reverb = reverb {
            do {
                let session = AVAudioSession.sharedInstance()
                try session.setCategory(.playback, mode: .default, options: [.mixWithOthers])
                try session.setActive(true)
            } catch {
                print("Audio session error: \(error)")
            }

            guard let format = AVAudioFormat(standardFormatWithSampleRate: Double(sampleRate), channels: 1) else {
                print("Failed to create AVAudioFormat")
                return
            }

            engine.attach(filter)
            engine.attach(reverb)

            playerNode = AVAudioPlayerNode()
            if let playerNode = playerNode {
                engine.attach(playerNode)
                engine.connect(playerNode, to: filter, format: format)
                engine.connect(filter, to: reverb, format: format)
                engine.connect(reverb, to: mixer, format: format)
            }

            do {
                try engine.start()
                playerNode?.play()
            } catch {
                print("Audio engine error: \(error)")
            }
        }
    }

    func startNote(frequency: Double) {
        setupAudio()
        self.frequency = frequency
        self.noteOnTime = Date()
        self.envelopePhase = 0
        isPlaying = true
        generationID += 1
        startAudioGeneration(id: generationID)
    }

    func stopNote() {
        isPlaying = false
    }

    private func startAudioGeneration(id: Int) {
        guard let format = AVAudioFormat(standardFormatWithSampleRate: Double(sampleRate), channels: 1) else {
            print("Failed to create AVAudioFormat in startAudioGeneration")
            return
        }
        let bufferSize: AVAudioFrameCount = AVAudioFrameCount(sampleRate)
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: bufferSize) else { return }

        var phase: Float = 0
        let phaseIncrement = Float(frequency) / sampleRate * 2 * .pi

        for i in 0..<Int(bufferSize) {
            let timeInBuffer = Double(i) / Double(sampleRate)

            // ADSR エンベロープ
            let envelope = calculateEnvelope(time: timeInBuffer)

            // 波形生成
            let sample = generateWaveform(phase: phase) * Float(envelope)
            buffer.floatChannelData?[0][i] = sample

            phase += phaseIncrement
            if phase > .pi * 2 {
                phase -= .pi * 2
            }
        }

        buffer.frameLength = bufferSize
        playerNode?.scheduleBuffer(buffer) { [weak self] in
            guard let self = self else { return }
            if self.isPlaying && self.generationID == id {
                self.startAudioGeneration(id: id)
            }
        }
    }

    private func generateWaveform(phase: Float) -> Float {
        switch waveform {
        case .sine:
            return sin(phase)
        case .square:
            return phase < .pi ? 0.8 : -0.8
        case .sawtooth:
            return 2 * (phase / (2 * .pi) - floor(phase / (2 * .pi) + 0.5))
        case .triangle:
            let normalized = phase / (2 * .pi)
            return abs(4 * (normalized - floor(normalized + 0.25))) - 2
        }
    }

    private func calculateEnvelope(time: Double) -> Double {
        let attackEnd = attackTime
        let decayEnd = attackTime + decayTime
        if time < attackEnd && attackEnd > 0 {
            return time / attackEnd
        } else if time < decayEnd {
            let decayProgress = (time - attackEnd) / decayTime
            return 1.0 - (decayProgress * (1.0 - sustainLevel))
        } else {
            return sustainLevel
        }
    }

    func updateFilter() {
        let normalizedResonance = max(0.5, 1.0 + (resonance - 0.5) * 3)
        filter?.bands[0].frequency = Float(cutoff)
        filter?.bands[0].bandwidth = Float(normalizedResonance)
    }

    deinit {
        playerNode?.stop()
        engine?.stop()
    }
}

enum Waveform: String, CaseIterable, Codable {
    case sine = "SIN"
    case square = "SQR"
    case sawtooth = "SAW"
    case triangle = "TRI"
}
