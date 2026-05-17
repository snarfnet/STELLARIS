# STELLARIS

**Celestial Synthesis Engine** — プロフェッショナル・グレードのマルチエフェクト・ポリフォニック・シンセサイザー。

AVAudioEngine ベースのリアルタイム音声合成、複数の波形、フルエンベロープ、LFO、シーケンサー、MIDI 出力を備えた本格的なシンセサイザーです。

## コア機能

### 🎹 オシレーター
- **4波形** — SIN / SQR / SAW / TRI
- **ピッチ** — 20Hz ～ 2000Hz
- **ポリフォニー** — 最大8音同時発声

### 🎚️ フィルター & エフェクト
- **CUTOFF** — 100Hz ～ 15000Hz
- **RESONANCE** — 0% ～ 100%
- **リバーブ** — WET/DRY ミックス可能
- **ディレイ** — フィードバック調整可能
- **コーラス** — WET/DRY ミックス可能

### 📈 ADSR エンベロープ
- **ATTACK** — 0.01s ～ 2.0s
- **DECAY** — 0.01s ～ 2.0s
- **SUSTAIN** — 0% ～ 100%
- **RELEASE** — 0.01s ～ 4.0s

### 🌊 LFO（Low Frequency Oscillator）
- **レート** — 0.1Hz ～ 20Hz
- **深さ** — 0% ～ 100%
- **波形** — SIN / TRI / SAW / SQR / RND
- **ターゲット** — CUTOFF / RESONANCE / AMPLITUDE / PITCH / ALL

### 🎼 シーケンサー & 作曲
- **16ステップ** — ビジュアル表示
- **スケール選択** — 5つの音階（MAJOR / MINOR / PENTA / BLUES / DORIAN）
- **コード進行** — 10種類の感情パターン + 無限ランダム生成
  - CLASSIC 1～3, SAD MINOR, DRAMATIC, HOPEFUL, MELANCHOLIC, TENSE, PEACEFUL, POWER
- **自動メロディー生成** — スケール/感情ベース

### 🎛️ 回転ダイアル UI
- **大型ダイアル** — PITCH / CUTOFF / RESONANCE（ドラッグで回転）
- **小型ダイアル** — ADSR / テンポ（56px）
- **ティック表示** — 視覚的フィードバック

### 💾 プリセット
- **保存/読込** — UserDefaults で永続化
- **デフォルト3種** — WARM PAD / ACID BASS / LEAD
- **カスタムプリセット** — 任意に追加可能

### 🎹 キーボード & ポリフォニー
- **7つの白鍵** — C / D / E / F / G / A / B
- **8音ポリフォニー** — 複数の音を同時演奏
- **RELEASE ボタン** — 全ノートオフ

### 🎞️ ビジュアライザー
- **波形表示** — リアルタイム波形ビジュアライザー
- **スペクトラム** — 周波数表示
- **メーター** — レベル表示
- **イコライザー** — 周波数別調整ビジュアル

### 🎵 MIDI 出力
- **EXPORT MIDI** — `.mid` ファイル生成＆Share
- **TO MIDI** — CoreMIDI でリアルタイム送信（GarageBand 等）

## 設定

- Bundle ID: `com.tokyonasu.STELLARIS`
- Team ID: `83VGKGSQUH`
- Minimum iOS: 15.0
- Display Name: `STELLARIS`
- Polyphony: 8 voices max

## デザイン

- **背景** — 深紫/青グラデーション + 星パーティクル
- **色彩** — Teal (SIN/CUTOFF) / Acid Yellow (フィルター/DELAY) / Red (RESONANCE)
- **フォント** — Monospaced (プロフェッショナル)
