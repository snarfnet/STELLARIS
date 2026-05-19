import SwiftUI
import UIKit
import GoogleMobileAds

private enum WorkspaceTab: CaseIterable {
    case sound
    case perform
    case sequence

    var title: String {
        switch self {
        case .sound:
            return "\u{97F3}\u{4F5C}\u{308A}"
        case .perform:
            return "\u{6F14}\u{594F}"
        case .sequence:
            return "\u{30B7}\u{30FC}\u{30B1}\u{30F3}\u{30B9}"
        }
    }

    var icon: String {
        switch self {
        case .sound:
            return "slider.horizontal.3"
        case .perform:
            return "music.note"
        case .sequence:
            return "square.grid.3x3"
        }
    }

    var color: Color {
        switch self {
        case .sound:
            return .stellarisTeal
        case .perform:
            return .stellarisAmber
        case .sequence:
            return .stellarisRed
        }
    }
}

struct ContentView: View {
    @StateObject private var synth = SynthEngine()
    @StateObject private var sequencer = SequencerEngine()
    @StateObject private var chords = ChordProgressionEngine()
    @StateObject private var lfo = LFOEngine()
    @StateObject private var arpeggiator = ArpeggiatorEngine()
    @StateObject private var macro = MacroControl()
    @StateObject private var xyPad = XYPadControl()
    @StateObject private var multiTrack = MultiTrackEngine()
    @StateObject private var wavetable = WavetableEngine()
    @StateObject private var pitchShift = PitchShiftEngine()
    @StateObject private var sampler = SamplerEngine()
    @StateObject private var presets = PresetManager()

    @State private var midiEngine: MIDIEngine?
    @State private var midiFileURL: URL?
    @State private var showShareSheet = false
    @State private var useChordProgression = false
    @State private var presetName = ""
    @State private var selectedTab: WorkspaceTab = .sound
    @State private var canLoadAds = false

    var body: some View {
        ZStack {
            StellarStageBackground()

            VStack(spacing: 0) {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 14) {
                        heroDeck
                        workspaceTabs
                        tabContent
                    }
                    .padding(.horizontal, 14)
                    .padding(.top, 12)
                    .padding(.bottom, 18)
                }

                if canLoadAds {
                    AdMobBannerView(adUnitID: "ca-app-pub-9404799280370656/8586668694")
                        .frame(width: 320, height: 50)
                        .padding(.top, 8)
                        .padding(.bottom, 10)
                        .frame(maxWidth: .infinity)
                        .background(Color.black.opacity(0.72))
                }
            }
        }
        .onAppear {
            prepareAdsAfterLaunch()
        }
        .sheet(isPresented: $showShareSheet) {
            if let url = midiFileURL {
                ShareSheet(items: [url])
            }
        }
    }

    private func prepareAdsAfterLaunch() {
        guard UIDevice.current.userInterfaceIdiom == .phone else { return }
        guard !ProcessInfo.processInfo.isiOSAppOnMac else { return }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            MobileAds.shared.start { _ in
                DispatchQueue.main.async {
                    canLoadAds = true
                }
            }
        }
    }

    @ViewBuilder
    private var tabContent: some View {
        switch selectedTab {
        case .sound:
            presetRail
            performanceDeck
            modulationDeck
            utilityDeck
        case .perform:
            presetRail
            livePerformanceDeck
            modulationDeck
        case .sequence:
            sequencerDeck
        }
    }

    private var workspaceTabs: some View {
        HStack(spacing: 8) {
            ForEach(WorkspaceTab.allCases, id: \.self) { tab in
                Button {
                    selectedTab = tab
                } label: {
                    HStack(spacing: 7) {
                        Image(systemName: tab.icon)
                            .font(.system(size: 12, weight: .black))

                        Text(tab.title)
                            .font(.system(size: 11, weight: .black, design: .monospaced))
                            .lineLimit(1)
                            .minimumScaleFactor(0.72)
                    }
                    .foregroundColor(selectedTab == tab ? .black : tab.color)
                    .frame(maxWidth: .infinity)
                    .frame(height: 42)
                    .background(selectedTab == tab ? tab.color : Color.black.opacity(0.26))
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(selectedTab == tab ? Color.white.opacity(0.18) : tab.color.opacity(0.22), lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(6)
        .background(Color.stellarisPanel.opacity(0.72))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
    }

    private var heroDeck: some View {
        ZStack(alignment: .bottomLeading) {
            Image("CollisionBackdrop")
                .resizable()
                .scaledToFill()
                .frame(height: 330)
                .clipped()
                .overlay(
                    LinearGradient(
                        colors: [
                            Color.black.opacity(0.12),
                            Color.black.opacity(0.48),
                            Color.black.opacity(0.86)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .overlay(
                    RadialGradient(
                        colors: [.white.opacity(0.22), .clear],
                        center: .center,
                        startRadius: 8,
                        endRadius: 220
                    )
                    .blendMode(.screen)
                )

            VStack(spacing: 14) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 5) {
                        Text("STELLARIS")
                            .font(.system(size: 34, weight: .black, design: .rounded))
                            .tracking(5)
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.stellarisFrost, .stellarisTeal, .stellarisAmber],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .shadow(color: .stellarisTeal.opacity(0.75), radius: 16)

                        Text("PLANETARY COLLISION SYNTH")
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .tracking(2)
                            .foregroundColor(.stellarisAmber)
                    }

                    Spacer()

                    StatusChip(isActive: synth.isPlaying, frequency: synth.frequency)
                }

                HStack(spacing: 12) {
                    VisualReadout(
                        title: synth.waveform.rawValue,
                        value: "\(Int(synth.frequency)) Hz",
                        color: .stellarisTeal
                    )

                    VisualReadout(
                        title: "CUT",
                        value: "\(Int(synth.cutoff))",
                        color: .stellarisAmber
                    )

                    VisualReadout(
                        title: "RES",
                        value: "\(Int(synth.resonance * 100))%",
                        color: .stellarisRed
                    )
                }

                WaveformVisualizer(frequency: synth.frequency, waveform: synth.waveform, color: .stellarisTeal)
                    .frame(height: 96)
                    .background(Color.black.opacity(0.22))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay(alignment: .topTrailing) {
                        Text(wavetable.isEnabled ? "WAVETABLE" : "OSC")
                            .font(.system(size: 9, weight: .bold, design: .monospaced))
                            .foregroundColor(.stellarisAmber)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 5)
                            .background(Color.black.opacity(0.35))
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                            .padding(8)
                    }
            }
            .padding(14)
        }
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(
                    LinearGradient(
                        colors: [.stellarisTeal.opacity(0.55), .white.opacity(0.16), .stellarisAmber.opacity(0.5)],
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    lineWidth: 1.5
                )
        )
        .shadow(color: .stellarisTeal.opacity(0.24), radius: 22, x: -8, y: 10)
        .shadow(color: .stellarisAmber.opacity(0.18), radius: 22, x: 8, y: 10)
    }

    private var presetRail: some View {
        SynthPanel {
            VStack(spacing: 10) {
                HStack {
                    PanelTitle("PRESETS", icon: "star")
                    Spacer()
                    Text(presets.selectedPreset)
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundColor(.stellarisAmber)
                }

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(presets.presets, id: \.id) { preset in
                            CapsuleButton(
                                title: preset.name,
                                isSelected: presets.selectedPreset == preset.name,
                                color: .stellarisTeal
                            ) {
                                loadPreset(preset)
                            }
                        }
                    }
                }

                HStack(spacing: 8) {
                    TextField("Preset name", text: $presetName)
                        .font(.system(size: 12, weight: .semibold, design: .monospaced))
                        .foregroundColor(.stellarisFrost)
                        .textInputAutocapitalization(.characters)
                        .padding(.horizontal, 10)
                        .frame(height: 38)
                        .background(Color.black.opacity(0.28))
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(Color.white.opacity(0.08), lineWidth: 1)
                        )

                    ActionButton(title: "SAVE", icon: "square.and.arrow.down", color: .stellarisAmber) {
                        savePreset()
                    }
                    .frame(width: 104)
                }
            }
        }
    }

    private var performanceDeck: some View {
        SynthPanel {
            VStack(spacing: 16) {
                HStack {
                    PanelTitle("VOICE", icon: "waveform")
                    Spacer()
                    Toggle("WT", isOn: $wavetable.isEnabled)
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundColor(.stellarisFrost.opacity(0.72))
                        .tint(.stellarisTeal)
                }

                if wavetable.isEnabled {
                    WaveformSelector(waveform: $wavetable.waveform1, color: .stellarisTeal)
                } else {
                    WaveformSelector(waveform: $synth.waveform, color: .stellarisTeal)
                }

                if wavetable.isEnabled {
                    WavetableControls(wavetable: wavetable)
                }

                HStack(alignment: .center, spacing: 18) {
                    LabeledDial(
                        label: "PITCH",
                        valueText: "\(Int(synth.frequency)) Hz",
                        value: $synth.frequency,
                        range: 20...2000,
                        color: .stellarisTeal,
                        size: 122
                    )

                    VStack(spacing: 14) {
                        HStack(spacing: 12) {
                            LabeledDial(
                                label: "CUTOFF",
                                valueText: "\(Int(synth.cutoff))",
                                value: $synth.cutoff,
                                range: 100...15000,
                                color: .stellarisAmber,
                                size: 96,
                                onChange: { synth.updateFilter() }
                            )

                            LabeledDial(
                                label: "RESO",
                                valueText: "\(Int(synth.resonance * 100))%",
                                value: $synth.resonance,
                                range: 0...1,
                                color: .stellarisRed,
                                size: 96,
                                onChange: { synth.updateFilter() }
                            )
                        }

                        MiniControlGrid {
                            MiniDialCell(label: "A", value: $synth.attackTime, range: 0.01...2.0, color: .stellarisTeal)
                            MiniDialCell(label: "D", value: $synth.decayTime, range: 0.01...2.0, color: .stellarisTeal)
                            MiniDialCell(label: "S", value: $synth.sustainLevel, range: 0...1, color: .stellarisTeal)
                            MiniDialCell(label: "R", value: $synth.releaseTime, range: 0.01...4.0, color: .stellarisTeal)
                        }
                    }
                }

            }
        }
    }

    private var livePerformanceDeck: some View {
        SynthPanel {
            VStack(spacing: 16) {
                HStack {
                    PanelTitle("PERFORM", icon: "music.note")
                    Spacer()
                    Text(synth.isPlaying ? "ACTIVE" : "READY")
                        .font(.system(size: 10, weight: .black, design: .monospaced))
                        .foregroundColor(synth.isPlaying ? .stellarisRed : .stellarisFrost.opacity(0.58))
                }

                HStack(spacing: 12) {
                    LabeledDial(
                        label: "PITCH",
                        valueText: "\(Int(synth.frequency)) Hz",
                        value: $synth.frequency,
                        range: 20...2000,
                        color: .stellarisTeal,
                        size: 104
                    )

                    VStack(spacing: 12) {
                        HStack(spacing: 10) {
                            VisualReadout(title: "WAVE", value: synth.waveform.rawValue, color: .stellarisTeal)
                            VisualReadout(title: "CUT", value: "\(Int(synth.cutoff))", color: .stellarisAmber)
                        }

                        WaveformSelector(waveform: $synth.waveform, color: .stellarisTeal)
                    }
                }

                KeyboardDeck(synth: synth)

                HStack(spacing: 10) {
                    ActionButton(
                        title: sequencer.isSequencerPlaying ? "STOP SEQ" : "PLAY SEQ",
                        icon: sequencer.isSequencerPlaying ? "stop.fill" : "play.fill",
                        color: sequencer.isSequencerPlaying ? .stellarisRed : .stellarisAmber
                    ) {
                        toggleSequencer()
                    }

                    ActionButton(title: "RANDOM", icon: "shuffle", color: .stellarisTeal) {
                        generateSequence()
                    }
                }
            }
        }
    }

    private var modulationDeck: some View {
        SynthPanel {
            VStack(spacing: 14) {
                HStack {
                    PanelTitle("MODULATION", icon: "slider.horizontal.3")
                    Spacer()
                    Toggle("XY", isOn: $xyPad.isEnabled)
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundColor(.stellarisFrost.opacity(0.72))
                        .tint(.stellarisAmber)
                }

                HStack(alignment: .top, spacing: 14) {
                    VStack(spacing: 12) {
                        ToggleRow(title: "LFO", isOn: $lfo.isEnabled, color: .stellarisTeal)

                        if lfo.isEnabled {
                            MiniControlGrid {
                                MiniDialCell(label: "RATE", value: $lfo.rate, range: 0.1...20, color: .stellarisTeal)
                                MiniDialCell(label: "DEPTH", value: $lfo.depth, range: 0...1, color: .stellarisTeal)
                            }

                            SegmentedCapsules(
                                items: LFOWaveform.allCases.map(\.rawValue),
                                selected: lfo.waveform.rawValue,
                                color: .stellarisTeal
                            ) { raw in
                                if let waveform = LFOWaveform.allCases.first(where: { $0.rawValue == raw }) {
                                    lfo.waveform = waveform
                                }
                            }
                        }

                        DividerLine()

                        ToggleRow(title: "MACRO", isOn: $macro.isEnabled, color: .stellarisAmber)
                        LabeledDial(
                            label: "MACRO",
                            valueText: "\(Int(macro.value * 100))%",
                            value: $macro.value,
                            range: 0...1,
                            color: .stellarisAmber,
                            size: 86,
                            onChange: applyMacro
                        )
                    }

                    VStack(spacing: 12) {
                        if xyPad.isEnabled {
                            XYPadView(control: xyPad)
                                .frame(maxWidth: .infinity)
                                .onChange(of: xyPad.xValue) { newValue in
                                    applyXY(target: xyPad.xTarget, value: newValue)
                                }
                                .onChange(of: xyPad.yValue) { newValue in
                                    applyXY(target: xyPad.yTarget, value: newValue)
                                }

                            HStack(spacing: 8) {
                                TargetPicker(title: "X", selection: $xyPad.xTarget)
                                TargetPicker(title: "Y", selection: $xyPad.yTarget)
                            }
                        } else {
                            XYPreview()
                        }
                    }
                    .frame(maxWidth: .infinity)
                }

                EffectStrip(synth: synth)
            }
        }
    }

    private var sequencerDeck: some View {
        SynthPanel {
            VStack(spacing: 14) {
                HStack {
                    PanelTitle("SEQUENCER", icon: "square.grid.3x3")
                    Spacer()
                    Text("\(Int(sequencer.tempo)) BPM")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundColor(.stellarisAmber)
                }

                HStack(spacing: 10) {
                    CapsuleButton(title: "16", isSelected: sequencer.stepCount == 16, color: .stellarisAmber) {
                        sequencer.setStepCount(16)
                    }

                    CapsuleButton(title: "32", isSelected: sequencer.stepCount == 32, color: .stellarisAmber) {
                        sequencer.setStepCount(32)
                    }

                    Picker("", selection: $sequencer.scale) {
                        ForEach(MusicalScale.allCases, id: \.self) { scale in
                            Text(scale.rawValue).tag(scale)
                        }
                    }
                    .pickerStyle(.menu)
                    .tint(.stellarisTeal)
                    .frame(maxWidth: .infinity)
                    .frame(height: 34)
                    .background(Color.black.opacity(0.25))
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                }

                ToggleRow(title: "CHORD PROGRESSION", isOn: $useChordProgression, color: .stellarisAmber)

                if useChordProgression {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(ChordProgression.allCases, id: \.self) { progression in
                                CapsuleButton(
                                    title: progression.rawValue,
                                    isSelected: chords.selectedProgression == progression,
                                    color: .stellarisAmber
                                ) {
                                    chords.selectedProgression = progression
                                }
                            }
                        }
                    }
                }

                StepLane(sequencer: sequencer)

                HStack(spacing: 10) {
                    ActionButton(title: "RANDOM", icon: "shuffle", color: .stellarisTeal) {
                        generateSequence()
                    }

                    ActionButton(
                        title: sequencer.isSequencerPlaying ? "STOP" : "PLAY",
                        icon: sequencer.isSequencerPlaying ? "stop.fill" : "play.fill",
                        color: sequencer.isSequencerPlaying ? .stellarisRed : .stellarisAmber
                    ) {
                        toggleSequencer()
                    }
                }

                HStack(spacing: 10) {
                    ActionButton(title: "EXPORT", icon: "square.and.arrow.up", color: .stellarisTeal) {
                        exportMIDI()
                    }

                    ActionButton(title: "MIDI OUT", icon: "cable.connector", color: .stellarisAmber) {
                        sequencer.startSequencer { midiNote, _ in
                            midiEngine.sendNoteOn(note: UInt8(midiNote), velocity: 100)
                        }
                    }
                }
            }
        }
    }

    private var utilityDeck: some View {
        SynthPanel {
            VStack(spacing: 14) {
                HStack {
                    PanelTitle("EXTENSIONS", icon: "rectangle.stack")
                    Spacer()
                    Text("LAB")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundColor(.stellarisFrost.opacity(0.6))
                }

                ToggleRow(title: "PITCH SHIFT", isOn: $pitchShift.isEnabled, color: .stellarisTeal)
                if pitchShift.isEnabled {
                    HStack(spacing: 12) {
                        LabeledDial(
                            label: "SHIFT",
                            valueText: pitchShift.getPitchShiftName(),
                            value: $pitchShift.amount,
                            range: -12...12,
                            color: .stellarisTeal,
                            size: 86
                        )

                        Picker("QUALITY", selection: $pitchShift.quality) {
                            ForEach(PitchShiftEngine.PitchQuality.allCases, id: \.self) { quality in
                                Text(quality.rawValue).tag(quality)
                            }
                        }
                        .pickerStyle(.menu)
                        .tint(.stellarisAmber)

                        Picker("VOICES", selection: $pitchShift.voiceCount) {
                            ForEach(1...3, id: \.self) { voice in
                                Text("\(voice)").tag(voice)
                            }
                        }
                        .pickerStyle(.menu)
                        .tint(.stellarisRed)
                    }
                }

                DividerLine()

                ToggleRow(title: "SAMPLER", isOn: $sampler.isEnabled, color: .stellarisAmber)
                HStack {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(sampler.sampleName)
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .foregroundColor(.stellarisFrost)
                            .lineLimit(1)

                        Text(sampler.getSampleInfoString())
                            .font(.system(size: 9, weight: .bold, design: .monospaced))
                            .foregroundColor(.stellarisAmber)
                    }

                    Spacer()

                    if sampler.isEnabled {
                        MiniDialCell(label: "RATE", value: $sampler.playbackRate, range: 0.5...2.0, color: .stellarisTeal)
                        MiniDialCell(label: "VOL", value: $sampler.volume, range: 0...1, color: .stellarisAmber)
                    }
                }

                DividerLine()

                ToggleRow(title: "ARPEGGIATOR", isOn: $arpeggiator.isEnabled, color: .stellarisTeal)
                if arpeggiator.isEnabled {
                    HStack(spacing: 10) {
                        Picker("", selection: $arpeggiator.pattern) {
                            ForEach(ArpPattern.allCases, id: \.self) { pattern in
                                Text(pattern.rawValue).tag(pattern)
                            }
                        }
                        .pickerStyle(.menu)
                        .tint(.stellarisTeal)

                        MiniDialCell(label: "SPD", value: $arpeggiator.speed, range: 0.5...2.0, color: .stellarisRed)
                    }
                }

                DividerLine()

                ToggleRow(title: "MULTI-TRACK", isOn: $multiTrack.isEnabled, color: .stellarisAmber)
                if multiTrack.isEnabled {
                    HStack(spacing: 8) {
                        ForEach(0..<multiTrack.tracks.count, id: \.self) { index in
                            TrackButton(
                                index: index,
                                isSelected: multiTrack.selectedTrack == index,
                                isActive: multiTrack.tracks[index].isActive
                            ) {
                                multiTrack.selectedTrack = index
                            }
                        }

                        ActionButton(
                            title: multiTrack.tracks[multiTrack.selectedTrack].isActive ? "MUTE" : "ON",
                            icon: "speaker.wave.2",
                            color: multiTrack.tracks[multiTrack.selectedTrack].isActive ? .stellarisRed : .stellarisTeal
                        ) {
                            multiTrack.toggleTrack(multiTrack.selectedTrack)
                        }
                        .frame(width: 92)
                    }
                }
            }
        }
    }

    private func loadPreset(_ preset: SynthPreset) {
        synth.frequency = preset.frequency
        synth.waveform = preset.waveform
        synth.cutoff = preset.cutoff
        synth.resonance = preset.resonance
        synth.drive = preset.drive
        synth.attackTime = preset.attackTime
        synth.decayTime = preset.decayTime
        synth.sustainLevel = preset.sustainLevel
        synth.releaseTime = preset.releaseTime
        synth.reverbMix = preset.reverbMix
        synth.delayMix = preset.delayMix
        synth.chorusMix = preset.chorusMix
        presets.selectedPreset = preset.name
        synth.updateFilter()
    }

    private func savePreset() {
        let name = presetName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return }

        presets.savePreset(
            name: name,
            frequency: synth.frequency,
            waveform: synth.waveform,
            cutoff: synth.cutoff,
            resonance: synth.resonance,
            drive: synth.drive,
            attackTime: synth.attackTime,
            decayTime: synth.decayTime,
            sustainLevel: synth.sustainLevel,
            releaseTime: synth.releaseTime,
            reverbMix: synth.reverbMix,
            delayMix: synth.delayMix,
            chorusMix: synth.chorusMix
        )

        presets.selectedPreset = name
        presetName = ""
    }

    private func applyMacro() {
        guard macro.isEnabled else { return }
        applyMacroValue(target: macro.target1)
        applyMacroValue(target: macro.target2)
        applyMacroValue(target: macro.target3)
        synth.updateFilter()
    }

    private func applyMacroValue(target: MacroControl.MacroTarget) {
        let mapped = macro.getValueForTarget(target)

        switch target {
        case .cutoff:
            synth.cutoff = mapped
        case .resonance:
            synth.resonance = mapped
        case .drive:
            synth.drive = mapped
        case .reverbMix:
            synth.reverbMix = mapped
        case .delayMix:
            synth.delayMix = mapped
        case .chorusMix:
            synth.chorusMix = mapped
        case .attackTime:
            synth.attackTime = mapped
        case .decayTime:
            synth.decayTime = mapped
        case .sustainLevel:
            synth.sustainLevel = mapped
        case .releaseTime:
            synth.releaseTime = mapped
        case .lfoRate:
            lfo.rate = mapped
        case .lfoDepth:
            lfo.depth = mapped
        }
    }

    private func applyXY(target: XYPadControl.XYTarget, value: Double) {
        guard xyPad.isEnabled else { return }
        let mapped = xyPad.getValueForTarget(target, axisValue: value)

        switch target {
        case .cutoff:
            synth.cutoff = mapped
            synth.updateFilter()
        case .resonance:
            synth.resonance = mapped
            synth.updateFilter()
        case .drive:
            synth.drive = mapped
        case .reverbMix:
            synth.reverbMix = mapped
        case .delayMix:
            synth.delayMix = mapped
        case .chorusMix:
            synth.chorusMix = mapped
        case .attackTime:
            synth.attackTime = mapped
        case .releaseTime:
            synth.releaseTime = mapped
        case .lfoRate:
            lfo.rate = mapped
        case .lfoDepth:
            lfo.depth = mapped
        case .frequency:
            synth.frequency = mapped
        case .sustain:
            synth.sustainLevel = mapped
        }
    }

    private func generateSequence() {
        if useChordProgression {
            sequencer.sequence = chords.generateChordProgression(steps: sequencer.stepCount)
        } else {
            sequencer.generateMelody()
        }
    }

    private func toggleSequencer() {
        if sequencer.isSequencerPlaying {
            sequencer.stopSequencer()
        } else {
            sequencer.startSequencer { midiNote, _ in
                synth.startNote(frequency: sequencer.frequencyFromMidiNote(midiNote))
            }
        }
    }

    private func exportMIDI() {
        let engine = midiEngine ?? MIDIEngine()
        midiEngine = engine

        if let url = engine.generateMIDIFile(
            sequence: sequencer.sequence,
            tempo: sequencer.tempo,
            fileName: "STELLARIS_\(Date().timeIntervalSince1970).mid"
        ) {
            midiFileURL = url
            showShareSheet = true
        }
    }
}

private struct AdMobBannerView: UIViewRepresentable {
    let adUnitID: String

    func makeUIView(context: Context) -> UIView {
        let container = UIView(frame: .zero)
        container.backgroundColor = .clear

        DispatchQueue.main.async {
            guard container.subviews.isEmpty else { return }
            guard let rootViewController = UIApplication.shared.stellarisRootViewController else { return }

            let banner = BannerView(adSize: AdSizeBanner)
            banner.adUnitID = adUnitID
            banner.rootViewController = rootViewController
            banner.translatesAutoresizingMaskIntoConstraints = false
            container.addSubview(banner)
            NSLayoutConstraint.activate([
                banner.centerXAnchor.constraint(equalTo: container.centerXAnchor),
                banner.centerYAnchor.constraint(equalTo: container.centerYAnchor),
                banner.widthAnchor.constraint(equalToConstant: 320),
                banner.heightAnchor.constraint(equalToConstant: 50),
            ])
            banner.load(Request())
        }

        return container
    }

    func updateUIView(_ uiView: UIView, context: Context) {}
}

private extension UIApplication {
    var stellarisRootViewController: UIViewController? {
        connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
            .first { $0.isKeyWindow }?
            .rootViewController
    }
}

private struct StellarStageBackground: View {
    var body: some View {
        ZStack {
            Image("CollisionBackdrop")
                .resizable()
                .scaledToFill()
                .overlay(Color.black.opacity(0.58))
                .overlay(
                    LinearGradient(
                        colors: [
                            Color.black.opacity(0.12),
                            Color(red: 0.005, green: 0.008, blue: 0.012).opacity(0.72),
                            Color.black.opacity(0.9)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            .ignoresSafeArea()

            Canvas { context, size in
                for index in 0..<70 {
                    let x = CGFloat((index * 47) % Int(max(size.width, 1)))
                    let y = CGFloat((index * 83) % Int(max(size.height, 1)))
                    let dotSize = CGFloat(index % 3 + 1)
                    let rect = CGRect(x: x, y: y, width: dotSize, height: dotSize)
                    context.opacity = Double((index % 5) + 2) / 18.0
                    context.fill(Path(ellipseIn: rect), with: .color(.white))
                }

                var path = Path()
                for row in stride(from: 80.0, through: Double(size.height), by: 96.0) {
                    path.move(to: CGPoint(x: 0, y: row))
                    path.addLine(to: CGPoint(x: size.width, y: row + 18))
                }
                context.stroke(path, with: .color(Color.stellarisTeal.opacity(0.08)), lineWidth: 1)
            }
            .ignoresSafeArea()

            RadialGradient(
                colors: [.stellarisAmber.opacity(0.2), .clear],
                center: .trailing,
                startRadius: 30,
                endRadius: 520
            )
            .ignoresSafeArea()

            RadialGradient(
                colors: [.stellarisTeal.opacity(0.24), .clear],
                center: .leading,
                startRadius: 40,
                endRadius: 560
            )
            .ignoresSafeArea()
        }
    }
}

private struct SynthPanel<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        content
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.stellarisPanel.opacity(0.78))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(
                                LinearGradient(
                                    colors: [Color.stellarisTeal.opacity(0.22), Color.white.opacity(0.12), Color.stellarisAmber.opacity(0.16)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
            )
            .shadow(color: .black.opacity(0.45), radius: 18, x: 0, y: 12)
    }
}

private struct PanelTitle: View {
    let title: String
    let icon: String

    init(_ title: String, icon: String) {
        self.title = title
        self.icon = icon
    }

    var body: some View {
        HStack(spacing: 7) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.stellarisTeal)

            Text(title)
                .font(.system(size: 11, weight: .black, design: .monospaced))
                .tracking(1.3)
                .foregroundColor(.stellarisFrost.opacity(0.82))
        }
    }
}

private struct StatusChip: View {
    let isActive: Bool
    let frequency: Double

    var body: some View {
        VStack(alignment: .trailing, spacing: 8) {
            HStack(spacing: 7) {
                Circle()
                    .fill(isActive ? Color.stellarisRed : Color.white.opacity(0.22))
                    .frame(width: 8, height: 8)
                    .shadow(color: isActive ? .stellarisRed.opacity(0.7) : .clear, radius: 8)

                Text(isActive ? "ACTIVE" : "IDLE")
                    .font(.system(size: 10, weight: .black, design: .monospaced))
                    .tracking(1.1)
                    .foregroundColor(isActive ? .stellarisRed : .stellarisFrost.opacity(0.55))
            }

            Text("\(frequency, specifier: "%.1f") Hz")
                .font(.system(size: 12, weight: .bold, design: .monospaced))
                .foregroundColor(.stellarisTeal)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 9)
        .background(Color.black.opacity(0.26))
        .clipShape(RoundedRectangle(cornerRadius: 7))
    }
}

private struct VisualReadout: View {
    let title: String
    let value: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title)
                .font(.system(size: 9, weight: .bold, design: .monospaced))
                .foregroundColor(.stellarisFrost.opacity(0.55))

            Text(value)
                .font(.system(size: 15, weight: .black, design: .monospaced))
                .minimumScaleFactor(0.72)
                .lineLimit(1)
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 10)
        .padding(.vertical, 9)
        .background(Color.black.opacity(0.25))
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }
}

private struct CapsuleButton: View {
    let title: String
    let isSelected: Bool
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 10, weight: .black, design: .monospaced))
                .lineLimit(1)
                .minimumScaleFactor(0.72)
                .foregroundColor(isSelected ? .black : color)
                .padding(.horizontal, 12)
                .frame(height: 34)
                .background(isSelected ? color : Color.black.opacity(0.26))
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(isSelected ? Color.white.opacity(0.18) : color.opacity(0.24), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
}

private struct ActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 7) {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .black))

                Text(title)
                    .font(.system(size: 11, weight: .black, design: .monospaced))
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
            }
            .foregroundColor(.black)
            .frame(maxWidth: .infinity)
            .frame(height: 42)
            .background(color)
            .clipShape(RoundedRectangle(cornerRadius: 6))
            .shadow(color: color.opacity(0.18), radius: 10, x: 0, y: 5)
        }
        .buttonStyle(.plain)
    }
}

private struct WaveformSelector: View {
    @Binding var waveform: Waveform
    let color: Color

    var body: some View {
        HStack(spacing: 7) {
            ForEach(Waveform.allCases, id: \.self) { item in
                CapsuleButton(title: item.rawValue, isSelected: waveform == item, color: color) {
                    waveform = item
                }
            }
        }
    }
}

private struct WavetableControls: View {
    @ObservedObject var wavetable: WavetableEngine

    var body: some View {
        VStack(spacing: 10) {
            HStack(spacing: 10) {
                Picker("FROM", selection: $wavetable.waveform1) {
                    ForEach(Waveform.allCases, id: \.self) { wave in
                        Text(wave.rawValue).tag(wave)
                    }
                }
                .pickerStyle(.menu)
                .tint(.stellarisTeal)

                Picker("TO", selection: $wavetable.waveform2) {
                    ForEach(Waveform.allCases, id: \.self) { wave in
                        Text(wave.rawValue).tag(wave)
                    }
                }
                .pickerStyle(.menu)
                .tint(.stellarisAmber)

                MiniDialCell(label: "MRP", value: $wavetable.morphAmount, range: 0...1, color: .stellarisRed)
                MiniDialCell(label: "DET", value: $wavetable.detune, range: 0...0.1, color: .stellarisFrost.opacity(0.75))
            }

            Picker("UNISON", selection: $wavetable.unison) {
                ForEach(1...7, id: \.self) { voice in
                    Text("\(voice)x").tag(voice)
                }
            }
            .pickerStyle(.segmented)
            .tint(.stellarisTeal)
        }
    }
}

private struct LabeledDial: View {
    let label: String
    let valueText: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    let color: Color
    let size: CGFloat
    var onChange: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: 8) {
            Text(label)
                .font(.system(size: 10, weight: .black, design: .monospaced))
                .foregroundColor(.stellarisFrost.opacity(0.65))

            StellarDial(value: $value, range: range, color: color, size: size)
                .onChange(of: value) { _ in onChange?() }

            Text(valueText)
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .lineLimit(1)
                .minimumScaleFactor(0.62)
                .foregroundColor(color)
                .frame(maxWidth: size + 12)
        }
    }
}

private struct StellarDial: View {
    @Binding var value: Double
    let range: ClosedRange<Double>
    let color: Color
    let size: CGFloat

    private var progress: Double {
        guard range.upperBound > range.lowerBound else { return 0 }
        return min(1, max(0, (value - range.lowerBound) / (range.upperBound - range.lowerBound)))
    }

    private var angle: Double {
        -132 + progress * 264
    }

    var body: some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color.white.opacity(0.12), Color.black.opacity(0.68)],
                        center: .topLeading,
                        startRadius: 2,
                        endRadius: size * 0.64
                    )
                )
                .overlay(Circle().stroke(Color.white.opacity(0.12), lineWidth: 1))

            ForEach(0..<44, id: \.self) { index in
                Rectangle()
                    .fill(index % 4 == 0 ? color.opacity(0.76) : Color.white.opacity(0.14))
                    .frame(width: index % 4 == 0 ? 2 : 1, height: index % 4 == 0 ? 10 : 5)
                    .offset(y: -(size / 2) + 9)
                    .rotationEffect(.degrees(-132 + Double(index) * (264 / 43)))
            }

            Circle()
                .trim(from: 0, to: progress)
                .stroke(color, style: StrokeStyle(lineWidth: 3.5, lineCap: .round))
                .rotationEffect(.degrees(136))
                .padding(5)
                .shadow(color: color.opacity(0.5), radius: 8)

            RoundedRectangle(cornerRadius: 2)
                .fill(color)
                .frame(width: 4, height: size * 0.27)
                .offset(y: -size * 0.16)
                .rotationEffect(.degrees(angle))

            Circle()
                .fill(Color.stellarisPanel)
                .frame(width: size * 0.28, height: size * 0.28)
                .overlay(Circle().stroke(color.opacity(0.8), lineWidth: 1.5))
        }
        .frame(width: size, height: size)
        .contentShape(Circle())
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { gesture in
                    updateValue(with: gesture.location)
                }
        )
    }

    private func updateValue(with location: CGPoint) {
        let center = CGPoint(x: size / 2, y: size / 2)
        var degrees = Double(atan2(location.y - center.y, location.x - center.x)) * 180 / .pi + 90
        if degrees > 180 { degrees -= 360 }
        let clamped = min(132, max(-132, degrees))
        let nextProgress = (clamped + 132) / 264
        value = range.lowerBound + nextProgress * (range.upperBound - range.lowerBound)
    }
}

private struct MiniControlGrid<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        HStack(spacing: 10) {
            content
        }
    }
}

private struct MiniDialCell: View {
    let label: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    let color: Color

    var body: some View {
        VStack(spacing: 5) {
            Text(label)
                .font(.system(size: 9, weight: .black, design: .monospaced))
                .foregroundColor(color)

            StellarDial(value: $value, range: range, color: color, size: 54)
        }
        .frame(minWidth: 54)
    }
}

private struct ToggleRow: View {
    let title: String
    @Binding var isOn: Bool
    let color: Color

    var body: some View {
        HStack {
            Text(title)
                .font(.system(size: 10, weight: .black, design: .monospaced))
                .tracking(0.8)
                .foregroundColor(.stellarisFrost.opacity(0.7))

            Spacer()

            Toggle("", isOn: $isOn)
                .labelsHidden()
                .tint(color)
        }
    }
}

private struct DividerLine: View {
    var body: some View {
        Rectangle()
            .fill(Color.white.opacity(0.08))
            .frame(height: 1)
    }
}

private struct SegmentedCapsules: View {
    let items: [String]
    let selected: String
    let color: Color
    let action: (String) -> Void

    var body: some View {
        HStack(spacing: 6) {
            ForEach(items, id: \.self) { item in
                CapsuleButton(title: item, isSelected: selected == item, color: color) {
                    action(item)
                }
            }
        }
    }
}

private struct TargetPicker: View {
    let title: String
    @Binding var selection: XYPadControl.XYTarget

    var body: some View {
        Picker(title, selection: $selection) {
            ForEach(XYPadControl.XYTarget.allCases, id: \.self) { target in
                Text(target.rawValue).tag(target)
            }
        }
        .pickerStyle(.menu)
        .tint(.stellarisTeal)
        .frame(maxWidth: .infinity)
        .frame(height: 34)
        .background(Color.black.opacity(0.24))
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }
}

private struct XYPreview: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.black.opacity(0.25))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                )

            VStack(spacing: 8) {
                Image(systemName: "scope")
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundColor(.stellarisTeal.opacity(0.72))

                Text("XY OFF")
                    .font(.system(size: 10, weight: .black, design: .monospaced))
                    .foregroundColor(.stellarisFrost.opacity(0.48))
            }
        }
        .frame(height: 220)
    }
}

private struct EffectStrip: View {
    @ObservedObject var synth: SynthEngine

    var body: some View {
        HStack(spacing: 10) {
            EffectMeter(label: "REV", value: synth.reverbMix, color: .stellarisTeal)
            EffectMeter(label: "DLY", value: synth.delayMix, color: .stellarisAmber)
            EffectMeter(label: "CHR", value: synth.chorusMix, color: .stellarisRed)
        }
    }
}

private struct EffectMeter: View {
    let label: String
    let value: Double
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack {
                Text(label)
                    .font(.system(size: 9, weight: .black, design: .monospaced))
                    .foregroundColor(.stellarisFrost.opacity(0.58))

                Spacer()

                Text("\(Int(value * 100))%")
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                    .foregroundColor(color)
            }

            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.black.opacity(0.32))

                    RoundedRectangle(cornerRadius: 3)
                        .fill(color)
                        .frame(width: proxy.size.width * CGFloat(min(1, max(0, value))))
                }
            }
            .frame(height: 7)
        }
        .frame(maxWidth: .infinity)
    }
}

private struct KeyboardDeck: View {
    @ObservedObject var synth: SynthEngine
    private let notes = [
        ("C", 261.63), ("D", 293.66), ("E", 329.63), ("F", 349.23),
        ("G", 392.00), ("A", 440.00), ("B", 493.88)
    ]

    var body: some View {
        HStack(spacing: 6) {
            ForEach(notes.indices, id: \.self) { index in
                KeyButton(label: notes[index].0, isActive: synth.isPlaying && abs(synth.frequency - notes[index].1) < 0.1) {
                    synth.startNote(frequency: notes[index].1)
                } release: {
                    synth.stopNote()
                }
            }

            Button {
                synth.stopNote()
            } label: {
                Image(systemName: "stop.fill")
                    .font(.system(size: 12, weight: .black))
                    .foregroundColor(.black)
                    .frame(width: 46, height: 74)
                    .background(Color.stellarisRed)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
            }
            .buttonStyle(.plain)
        }
    }
}

private struct KeyButton: View {
    let label: String
    let isActive: Bool
    let press: () -> Void
    let release: () -> Void

    var body: some View {
        Text(label)
            .font(.system(size: 14, weight: .black, design: .monospaced))
            .foregroundColor(isActive ? .black : .stellarisTeal)
            .frame(maxWidth: .infinity)
            .frame(height: 74)
            .background(isActive ? Color.stellarisAmber : Color.black.opacity(0.28))
            .clipShape(RoundedRectangle(cornerRadius: 6))
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(Color.white.opacity(isActive ? 0.2 : 0.08), lineWidth: 1)
            )
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in press() }
                    .onEnded { _ in release() }
            )
    }
}

private struct StepLane: View {
    @ObservedObject var sequencer: SequencerEngine

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(alignment: .bottom, spacing: 4) {
                ForEach(0..<sequencer.stepCount, id: \.self) { index in
                    let midi = index < sequencer.sequence.count ? sequencer.sequence[index] : 0
                    let height = CGFloat(18 + (midi % 36))

                    VStack(spacing: 4) {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(sequencer.currentStep == index ? Color.stellarisAmber : Color.stellarisTeal.opacity(0.66))
                            .frame(width: sequencer.stepCount > 16 ? 12 : 18, height: height)

                        Circle()
                            .fill(sequencer.currentStep == index ? Color.stellarisRed : Color.white.opacity(0.16))
                            .frame(width: 5, height: 5)
                    }
                    .frame(height: 62, alignment: .bottom)
                }
            }
            .padding(.horizontal, 2)
            .padding(.vertical, 8)
        }
        .background(Color.black.opacity(0.24))
        .clipShape(RoundedRectangle(cornerRadius: 7))
    }
}

private struct TrackButton: View {
    let index: Int
    let isSelected: Bool
    let isActive: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 5) {
                Text("\(index + 1)")
                    .font(.system(size: 11, weight: .black, design: .monospaced))

                Circle()
                    .fill(isActive ? Color.stellarisAmber : Color.white.opacity(0.2))
                    .frame(width: 7, height: 7)
            }
            .foregroundColor(isSelected ? .black : .stellarisTeal)
            .frame(maxWidth: .infinity)
            .frame(height: 44)
            .background(isSelected ? Color.stellarisTeal : Color.black.opacity(0.26))
            .clipShape(RoundedRectangle(cornerRadius: 6))
        }
        .buttonStyle(.plain)
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

extension Color {
    static let stellarisTeal = Color(red: 0.25, green: 0.95, blue: 0.87)
    static let stellarisAmber = Color(red: 1.0, green: 0.72, blue: 0.24)
    static let stellarisAcid = Color.stellarisAmber
    static let stellarisRed = Color(red: 1.0, green: 0.22, blue: 0.18)
    static let stellarisFrost = Color(red: 0.82, green: 0.91, blue: 0.94)
    static let stellarisPanel = Color(red: 0.055, green: 0.072, blue: 0.083)
}
