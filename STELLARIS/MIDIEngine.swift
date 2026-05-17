import Foundation
import CoreMIDI

class MIDIEngine: NSObject {
    private var midiClient = MIDIClientRef()
    private var midiPort = MIDIPortRef()
    private var midiDestination = MIDIEndpointRef()

    override init() {
        super.init()
        setupMIDI()
    }

    private func setupMIDI() {
        // MIDI クライアント作成
        var clientRef = MIDIClientRef()
        MIDIClientCreate("STELLARIS" as CFString, nil, nil, &clientRef)
        midiClient = clientRef

        // MIDI 出力ポート作成
        var portRef = MIDIPortRef()
        MIDIOutputPortCreate(midiClient, "STELLARIS Out" as CFString, &portRef)
        midiPort = portRef

        // MIDI 宛先を取得
        let destCount = MIDIGetNumberOfDestinations()
        if destCount > 0 {
            midiDestination = MIDIGetDestination(0)
        }
    }

    func sendNoteOn(note: UInt8, velocity: UInt8, channel: UInt8 = 0) {
        var status = UInt8(0x90 | channel)  // Note On
        var packet = MIDIPacket()
        packet.timeStamp = mach_absolute_time()
        packet.length = 3
        packet.data.0 = status
        packet.data.1 = note
        packet.data.2 = velocity

        var packetList = MIDIPacketList(numPackets: 1, packet: packet)
        MIDISend(midiPort, midiDestination, &packetList)
    }

    func sendNoteOff(note: UInt8, channel: UInt8 = 0) {
        var status = UInt8(0x80 | channel)  // Note Off
        var packet = MIDIPacket()
        packet.timeStamp = mach_absolute_time()
        packet.length = 3
        packet.data.0 = status
        packet.data.1 = note
        packet.data.2 = 0

        var packetList = MIDIPacketList(numPackets: 1, packet: packet)
        MIDISend(midiPort, midiDestination, &packetList)
    }

    func generateMIDIFile(sequence: [Int], tempo: Double, fileName: String) -> URL? {
        // MIDI ファイルデータ作成
        var data = Data()

        // MThd チャンク（ヘッダー）
        data.append(contentsOf: [0x4D, 0x54, 0x68, 0x64])  // "MThd"
        data.append(contentsOf: [0x00, 0x00, 0x00, 0x06])  // ヘッダーサイズ
        data.append(contentsOf: [0x00, 0x00])              // フォーマット 0
        data.append(contentsOf: [0x00, 0x01])              // トラック数
        data.append(contentsOf: [0x00, 0x60])              // 分解能（96）

        // MTrk チャンク（トラック）
        var trackData = Data()

        // テンポ設定
        let microsecondsPerBeat = UInt32(60_000_000 / tempo)
        trackData.append(0xFF)  // メタイベント
        trackData.append(0x51)  // テンポ設定
        trackData.append(0x03)  // 長さ
        trackData.append(UInt8((microsecondsPerBeat >> 16) & 0xFF))
        trackData.append(UInt8((microsecondsPerBeat >> 8) & 0xFF))
        trackData.append(UInt8(microsecondsPerBeat & 0xFF))

        // シーケンス追加
        let stepDuration: UInt8 = 24  // 1ステップ = 96/4 = 24

        for (index, midiNote) in sequence.enumerated() {
            let time = UInt32(index * Int(stepDuration))

            // デルタタイム
            appendVariableLength(&trackData, value: index == 0 ? UInt32(0) : UInt32(stepDuration))

            // Note On
            trackData.append(0x90)              // Note On, Channel 0
            trackData.append(UInt8(midiNote))  // Note
            trackData.append(0x64)              // Velocity

            // Note Off（次のステップで）
            appendVariableLength(&trackData, value: UInt32(stepDuration))
            trackData.append(0x80)              // Note Off, Channel 0
            trackData.append(UInt8(midiNote))  // Note
            trackData.append(0x00)              // Velocity
        }

        // トラック終了
        trackData.append(0x00)  // デルタタイム 0
        trackData.append(0xFF)  // メタイベント
        trackData.append(0x2F)  // トラック終了
        trackData.append(0x00)  // 長さ 0

        // MTrk ヘッダーを追加
        data.append(contentsOf: [0x4D, 0x54, 0x72, 0x6B])  // "MTrk"
        appendLongBE(&data, value: UInt32(trackData.count))
        data.append(trackData)

        // ファイル保存
        let fileManager = FileManager.default
        let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileURL = documentsURL.appendingPathComponent(fileName)

        do {
            try data.write(to: fileURL)
            return fileURL
        } catch {
            print("MIDI file save error: \(error)")
            return nil
        }
    }

    private func appendVariableLength(_ data: inout Data, value: UInt32) {
        var val = value
        var bytes: [UInt8] = []

        bytes.append(UInt8(val & 0x7F))
        val >>= 7

        while val > 0 {
            bytes.insert(UInt8((val & 0x7F) | 0x80), at: 0)
            val >>= 7
        }

        data.append(contentsOf: bytes)
    }

    private func appendLongBE(_ data: inout Data, value: UInt32) {
        data.append(UInt8((value >> 24) & 0xFF))
        data.append(UInt8((value >> 16) & 0xFF))
        data.append(UInt8((value >> 8) & 0xFF))
        data.append(UInt8(value & 0xFF))
    }

    deinit {
        MIDIPortDispose(midiPort)
        MIDIClientDispose(midiClient)
    }
}
