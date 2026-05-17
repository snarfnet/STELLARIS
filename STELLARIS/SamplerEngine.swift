import Foundation
import AVFoundation

class SamplerEngine: NSObject, ObservableObject {
    @Published var isEnabled: Bool = false
    @Published var sampleName: String = "No Sample"
    @Published var playbackRate: Double = 1.0  // 0.5 to 2.0x
    @Published var loopMode: LoopMode = .off
    @Published var loopStart: Double = 0.0  // percentage
    @Published var loopEnd: Double = 1.0  // percentage
    @Published var reverse: Bool = false
    @Published var volume: Double = 0.8

    private var audioFile: AVAudioFile?
    private var sampleBuffer: AVAudioPCMBuffer?

    enum LoopMode: String, CaseIterable {
        case off = "OFF"
        case forward = "FWD"
        case pingpong = "PING"
    }

    func loadSampleFromURL(_ url: URL) -> Bool {
        do {
            let audioFile = try AVAudioFile(forReading: url)
            self.audioFile = audioFile
            self.sampleBuffer = audioFile.processingFormat.channelCount > 0 ?
                AVAudioPCMBuffer(pcmFormat: audioFile.processingFormat, frameCapacity: AVAudioFrameCount(audioFile.length)) : nil

            // Extract sample name from URL
            self.sampleName = url.lastPathComponent

            return true
        } catch {
            print("Failed to load sample: \(error)")
            return false
        }
    }

    func getSampleDuration() -> TimeInterval {
        guard let audioFile = audioFile else { return 0 }
        return TimeInterval(audioFile.length) / audioFile.processingFormat.sampleRate
    }

    func getLoopStartFrame() -> Int {
        guard let audioFile = audioFile else { return 0 }
        return Int(Double(audioFile.length) * loopStart)
    }

    func getLoopEndFrame() -> Int {
        guard let audioFile = audioFile else { return 0 }
        return Int(Double(audioFile.length) * loopEnd)
    }

    func resetSample() {
        audioFile = nil
        sampleBuffer = nil
        sampleName = "No Sample"
    }

    func getSampleInfoString() -> String {
        let duration = getSampleDuration()
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return "\(minutes):\(String(format: "%02d", seconds))"
    }
}
