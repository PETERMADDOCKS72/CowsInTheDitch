import AVFoundation

/// Synthesizes game sound effects using AVAudioEngine (no external audio files needed).
/// Uses `.ambient` audio session category to respect the silent switch and mix with other audio.
final class SoundManager {

    static let shared = SoundManager()

    // MARK: - Audio engine

    private let engine = AVAudioEngine()
    private let playerNode = AVAudioPlayerNode()
    private let mixerNode: AVAudioMixerNode

    // MARK: - Speech

    private let speechSynth = AVSpeechSynthesizer()
    private var lastGiddyUpTime: TimeInterval = 0
    private let giddyUpCooldown: TimeInterval = 4.0

    // MARK: - Format

    private let sampleRate: Double = 44100
    private lazy var audioFormat: AVAudioFormat = {
        AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)!
    }()

    // MARK: - Init

    private init() {
        mixerNode = engine.mainMixerNode

        configureAudioSession()

        engine.attach(playerNode)
        engine.connect(playerNode, to: mixerNode, format: audioFormat)

        do {
            try engine.start()
        } catch {
            print("SoundManager: engine start failed – \(error)")
        }
    }

    private func configureAudioSession() {
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.ambient, mode: .default)
            try session.setActive(true)
        } catch {
            print("SoundManager: audio session config failed – \(error)")
        }
    }

    // MARK: - Moo (~250Hz → ~180Hz sine with vibrato, ~0.6s)

    /// Plays a low-pitched moo sound with slight random pitch variation.
    func playMoo() {
        let pitchVariation = Float.random(in: 0.9...1.1)
        let startFreq: Float = 250 * pitchVariation
        let endFreq: Float = 180 * pitchVariation
        let duration: Float = 0.6
        let frameCount = AVAudioFrameCount(sampleRate * Double(duration))

        guard let buffer = AVAudioPCMBuffer(pcmFormat: audioFormat, frameCapacity: frameCount) else { return }
        buffer.frameLength = frameCount

        guard let data = buffer.floatChannelData?[0] else { return }

        var phase: Float = 0
        let vibratoFreq: Float = 5.0
        let vibratoDepth: Float = 8.0

        for i in 0..<Int(frameCount) {
            let t = Float(i) / Float(sampleRate)
            let progress = t / duration

            // Frequency slides from startFreq to endFreq
            let baseFreq = startFreq + (endFreq - startFreq) * progress
            let vibrato = sin(2.0 * .pi * vibratoFreq * t) * vibratoDepth
            let freq = baseFreq + vibrato

            // Envelope: quick attack, sustained, quick fade
            let envelope: Float
            if progress < 0.05 {
                envelope = progress / 0.05
            } else if progress > 0.8 {
                envelope = (1.0 - progress) / 0.2
            } else {
                envelope = 1.0
            }

            phase += freq / Float(sampleRate)
            if phase > 1.0 { phase -= 1.0 }

            data[i] = sin(2.0 * .pi * phase) * 0.35 * envelope
        }

        scheduleBuffer(buffer)
    }

    // MARK: - Splash (white noise burst, bandpass filtered, ~0.3s)

    /// Plays a quick splash sound using filtered white noise.
    func playSplash() {
        let duration: Float = 0.3
        let frameCount = AVAudioFrameCount(sampleRate * Double(duration))

        guard let buffer = AVAudioPCMBuffer(pcmFormat: audioFormat, frameCapacity: frameCount) else { return }
        buffer.frameLength = frameCount

        guard let data = buffer.floatChannelData?[0] else { return }

        // Simple bandpass via cascaded one-pole filters
        let centerFreq: Float = 2000
        let rc: Float = 1.0 / (2.0 * .pi * centerFreq)
        let dtSample: Float = 1.0 / Float(sampleRate)
        let alpha = dtSample / (rc + dtSample)

        var lpPrev: Float = 0
        var hpPrev: Float = 0

        for i in 0..<Int(frameCount) {
            let t = Float(i) / Float(sampleRate)
            let progress = t / duration

            // Sharp attack, quick decay envelope
            let envelope: Float
            if progress < 0.05 {
                envelope = progress / 0.05
            } else {
                envelope = pow(1.0 - progress, 3.0)
            }

            let noise = Float.random(in: -1.0...1.0)

            // Low-pass
            lpPrev = lpPrev + alpha * (noise - lpPrev)
            // High-pass (subtract low-pass of low-pass)
            let hpInput = lpPrev
            hpPrev = hpPrev + (alpha * 0.5) * (hpInput - hpPrev)
            let bandpassed = lpPrev - hpPrev

            data[i] = bandpassed * 0.5 * envelope
        }

        scheduleBuffer(buffer)
    }

    // MARK: - Giddy Up (speech synthesis, throttled)

    /// Speaks "Giddy up!" with a raised pitch. Throttled to once every 4 seconds.
    func playGiddyUp() {
        let now = CACurrentMediaTime()
        guard now - lastGiddyUpTime >= giddyUpCooldown else { return }
        lastGiddyUpTime = now

        let utterance = AVSpeechUtterance(string: "Giddy up!")
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate * 1.2
        utterance.pitchMultiplier = 1.5
        utterance.volume = 0.6

        if speechSynth.isSpeaking {
            speechSynth.stopSpeaking(at: .immediate)
        }
        speechSynth.speak(utterance)
    }

    // MARK: - Helpers

    private func scheduleBuffer(_ buffer: AVAudioPCMBuffer) {
        if !engine.isRunning {
            do { try engine.start() } catch { return }
        }
        playerNode.scheduleBuffer(buffer, completionHandler: nil)
        if !playerNode.isPlaying {
            playerNode.play()
        }
    }
}
