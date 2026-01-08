import AVFoundation
import Accelerate
import Combine

class AudioEngineManager: ObservableObject {
    private let engine = AVAudioEngine()
    private let inputNode: AVAudioInputNode
    private let mainMixer: AVAudioMixerNode
    
    // Managers
    let deviceManager = AudioDeviceManager()
    let tuner = Tuner()
    let cabSim = CabSimulator()

    // Effects nodes
    private let noiseGateNode = AVAudioUnitDynamicsProcessor()
    private let compressorNode = AVAudioUnitDynamicsProcessor()
    private let distortionNode = AVAudioUnitDistortion()
    private let reverbNode = AVAudioUnitReverb()
    private let delayNode = AVAudioUnitDelay()
    private let eqNode = AVAudioUnitEQ(numberOfBands: 3)
    
    // Modulation Nodes
    private let modDelayNode = AVAudioUnitDelay() // For Chorus/Flanger
    private let tremoloNode = AVAudioMixerNode()  // For Tremolo volume modulation

    private var isTunerTapInstalled = false
    private var lfoTimer: Timer?
    private var lfoPhase: Double = 0.0

    // Published properties for UI binding
    @Published var isEngineRunning = false
    @Published var inputLevel: Float = 0.0
    @Published var outputLevel: Float = 0.0
    
    // Effect parameters
    @Published var distortionAmount: Float = 0.0 {
        didSet { updateDistortion() }
    }
    
    @Published var distortionEnabled: Bool = false {
        didSet { distortionNode.bypass = !distortionEnabled }
    }
    
    @Published var reverbAmount: Float = 0.0 {
        didSet { updateReverb() }
    }
    
    @Published var reverbEnabled: Bool = false {
        didSet { reverbNode.bypass = !reverbEnabled }
    }
    
    @Published var delayTime: Float = 0.3 {
        didSet { updateDelay() }
    }
    
    @Published var delayFeedback: Float = 0.3 {
        didSet { updateDelay() }
    }
    
    @Published var delayEnabled: Bool = false {
        didSet { delayNode.bypass = !delayEnabled }
    }
    
    // New Effects Parameters

    // Noise Gate
    @Published var gateThreshold: Float = 0.0 { // 0.0 to 1.0 mapping to -80dB to 0dB
        didSet { updateGate() }
    }

    // Compressor
    @Published var compSustain: Float = 0.0 { // Maps to Threshold + Ratio
        didSet { updateCompressor() }
    }
    @Published var compLevel: Float = 0.5 { // Maps to Makeup Gain
        didSet { updateCompressor() }
    }
    @Published var compEnabled: Bool = false {
        didSet { compressorNode.bypass = !compEnabled }
    }

    // Modulation
    enum ModulationType: String, CaseIterable, Identifiable {
        case chorus = "Chorus"
        case flanger = "Flanger"
        case tremolo = "Tremolo"
        var id: String { rawValue }
    }

    @Published var modType: ModulationType = .chorus {
        didSet { updateModulationSettings() }
    }
    @Published var modRate: Float = 0.3 { // 0.1Hz to 5Hz
        didSet { updateModulationSettings() }
    }
    @Published var modDepth: Float = 0.5 {
        didSet { updateModulationSettings() }
    }
    @Published var modEnabled: Bool = false {
        didSet {
            modDelayNode.bypass = !modEnabled || modType == .tremolo
            // Tremolo is handled by the LFO updating the mixer volume, so we "bypass" it by setting vol to 1.0
            if !modEnabled { tremoloNode.outputVolume = 1.0 }
        }
    }

    // Amp EQ controls
    @Published var bassLevel: Float = 0.0 {
        didSet { updateEQ() }
    }
    
    @Published var midLevel: Float = 0.0 {
        didSet { updateEQ() }
    }
    
    @Published var trebleLevel: Float = 0.0 {
        didSet { updateEQ() }
    }
    
    init() {
        inputNode = engine.inputNode
        mainMixer = engine.mainMixerNode
        
        setupAudioSession()
        setupEffectsChain()
        configureInitialSettings()

        // Listen to device changes
        setupDeviceListeners()
    }

    private var cancellables = Set<AnyCancellable>()

    private func setupDeviceListeners() {
        // Observe Input Device changes
        deviceManager.$currentInputDeviceID
            .dropFirst()
            .sink { [weak self] newID in
                guard let self = self, let id = newID else { return }
                self.setInputDevice(id: id)
            }
            .store(in: &cancellables)

        // Observe Output Device changes
        deviceManager.$currentOutputDeviceID
            .dropFirst()
            .sink { [weak self] newID in
                guard let self = self, let id = newID else { return }
                self.setOutputDevice(id: id)
            }
            .store(in: &cancellables)
    }

    func setInputDevice(id: AudioObjectID) {
        // Changing devices requires restarting the engine to handle format changes
        let wasRunning = engine.isRunning
        if wasRunning { engine.stop() }

        deviceManager.setInputDevice(id: id, for: inputNode)

        // Give CoreAudio a moment to switch
        if wasRunning {
            try? engine.start()
        }
    }

    func setOutputDevice(id: AudioObjectID) {
        let wasRunning = engine.isRunning
        if wasRunning { engine.stop() }

        // We set the device on engine.outputNode
        deviceManager.setOutputDevice(id: id, for: engine.outputNode)

        if wasRunning {
            try? engine.start()
        }
    }
    
    private func setupAudioSession() {
        #if os(macOS)
        // macOS doesn't require audio session configuration like iOS
        #endif
    }
    
    private func setupEffectsChain() {
        // Attach all nodes
        engine.attach(noiseGateNode)
        engine.attach(compressorNode)
        engine.attach(distortionNode)
        engine.attach(eqNode)
        engine.attach(modDelayNode)
        engine.attach(tremoloNode)
        engine.attach(cabSim.eqNode)
        engine.attach(delayNode)
        engine.attach(reverbNode)
        
        // Get the input format
        let inputFormat = inputNode.outputFormat(forBus: 0)
        
        // Create the effects chain:
        // Input -> Gate -> Comp -> Dist -> AmpEQ -> ModDelay -> Tremolo -> CabSim -> Delay -> Reverb -> Output

        engine.connect(inputNode, to: noiseGateNode, format: inputFormat)
        engine.connect(noiseGateNode, to: compressorNode, format: inputFormat)
        engine.connect(compressorNode, to: distortionNode, format: inputFormat)
        engine.connect(distortionNode, to: eqNode, format: inputFormat)

        // Effects Loop (Modulation)
        engine.connect(eqNode, to: modDelayNode, format: inputFormat)
        engine.connect(modDelayNode, to: tremoloNode, format: inputFormat)
        engine.connect(tremoloNode, to: cabSim.eqNode, format: inputFormat)

        engine.connect(cabSim.eqNode, to: delayNode, format: inputFormat)
        engine.connect(delayNode, to: reverbNode, format: inputFormat)
        engine.connect(reverbNode, to: mainMixer, format: inputFormat)
        
        // Install taps for level monitoring
        installLevelTaps()
        installTunerTap()

        // Start LFO
        startLFO()
    }
    
    private func configureInitialSettings() {
        // Gate defaults
        // Acts as expander: High Threshold, High Ratio
        noiseGateNode.threshold = -80 // Start open
        noiseGateNode.expansionRatio = 20.0
        noiseGateNode.attackTime = 0.001
        noiseGateNode.releaseTime = 0.1
        noiseGateNode.masterGain = 0

        // Compressor defaults
        compressorNode.bypass = true
        compressorNode.headRoom = 5
        compressorNode.expansionRatio = 1 // No expansion
        updateCompressor()

        // Mod Delay defaults
        modDelayNode.bypass = true

        // Distortion defaults
        distortionNode.loadFactoryPreset(.multiDistortedFunk)
        distortionNode.bypass = true
        distortionNode.wetDryMix = 50
        
        // Reverb defaults
        reverbNode.loadFactoryPreset(.mediumHall)
        reverbNode.bypass = true
        reverbNode.wetDryMix = 30
        
        // Delay defaults
        delayNode.bypass = true
        delayNode.delayTime = 0.3
        delayNode.feedback = 30
        delayNode.wetDryMix = 30
        
        // EQ setup (3-band: Bass, Mid, Treble)
        setupEQBands()
    }
    
    private func setupEQBands() {
        // Bass - 100 Hz
        eqNode.bands[0].filterType = .parametric
        eqNode.bands[0].frequency = 100
        eqNode.bands[0].bandwidth = 1.0
        eqNode.bands[0].gain = 0
        eqNode.bands[0].bypass = false
        
        // Mid - 1000 Hz
        eqNode.bands[1].filterType = .parametric
        eqNode.bands[1].frequency = 1000
        eqNode.bands[1].bandwidth = 1.0
        eqNode.bands[1].gain = 0
        eqNode.bands[1].bypass = false
        
        // Treble - 5000 Hz
        eqNode.bands[2].filterType = .parametric
        eqNode.bands[2].frequency = 5000
        eqNode.bands[2].bandwidth = 1.0
        eqNode.bands[2].gain = 0
        eqNode.bands[2].bypass = false
    }
    
    private func updateDistortion() {
        // Map 0-1 to more useful range for distortion
        let preGain = -6.0 + (distortionAmount * 42.0) // -6 to +36 dB
        distortionNode.preGain = preGain
        
        // Adjust wet/dry mix based on amount
        distortionNode.wetDryMix = 50 + (distortionAmount * 50) // 50% to 100%
    }
    
    private func updateReverb() {
        reverbNode.wetDryMix = reverbAmount * 100
    }
    
    private func updateDelay() {
        delayNode.delayTime = TimeInterval(delayTime)
        delayNode.feedback = delayFeedback * 100
    }
    
    private func updateEQ() {
        // Map 0-1 to -12 to +12 dB
        eqNode.bands[0].gain = (bassLevel - 0.5) * 24
        eqNode.bands[1].gain = (midLevel - 0.5) * 24
        eqNode.bands[2].gain = (trebleLevel - 0.5) * 24
    }
    
    private func updateGate() {
        // Threshold: 0.0 -> -80dB, 1.0 -> -10dB
        let db = -80.0 + (gateThreshold * 70.0)
        noiseGateNode.expansionThreshold = db
    }

    private func updateCompressor() {
        // Sustain (Threshold): 0.0 -> -10dB, 1.0 -> -40dB
        // High sustain = low threshold
        let thresh = -10.0 - (compSustain * 30.0)
        compressorNode.threshold = thresh

        // Ratio: 2:1 to 10:1 based on sustain
        compressorNode.ratio = 2.0 + (compSustain * 8.0)

        // Level (Gain): -10dB to +20dB
        let gain = -10.0 + (compLevel * 30.0)
        compressorNode.masterGain = gain
    }

    private func updateModulationSettings() {
        // Reset nodes based on type
        if !modEnabled { return }

        modDelayNode.bypass = (modType == .tremolo)
        tremoloNode.outputVolume = 1.0 // Reset tremolo when not used

        switch modType {
        case .chorus:
            modDelayNode.wetDryMix = 50
            modDelayNode.feedback = 0
        case .flanger:
            modDelayNode.wetDryMix = 50
            modDelayNode.feedback = 50
        case .tremolo:
            break
        }
    }

    private func startLFO() {
        stopLFO()
        // Run at 30Hz for smooth updates
        lfoTimer = Timer.scheduledTimer(withTimeInterval: 0.033, repeats: true) { [weak self] _ in
            self?.updateLFO()
        }
    }

    private func stopLFO() {
        lfoTimer?.invalidate()
        lfoTimer = nil
    }

    private func updateLFO() {
        guard modEnabled else { return }

        // LFO Phase update
        // Rate: 0.0 -> 0.1Hz, 1.0 -> 5.0Hz
        let frequency = 0.1 + (Double(modRate) * 4.9)
        let increment = (frequency * 2.0 * .pi) * 0.033 // freq * 2pi * dt
        lfoPhase += increment
        if lfoPhase > 2.0 * .pi { lfoPhase -= 2.0 * .pi }

        let sineVal = sin(lfoPhase) // -1 to 1

        switch modType {
        case .chorus:
            // Vary delay time between 5ms and 25ms
            // Depth controls width
            let baseDelay = 0.015
            let width = 0.005 + (Double(modDepth) * 0.010)
            let newDelay = baseDelay + (sineVal * width)
            modDelayNode.delayTime = newDelay

        case .flanger:
            // Vary delay time between 1ms and 5ms
            let baseDelay = 0.003
            let width = 0.001 + (Double(modDepth) * 0.002)
            let newDelay = baseDelay + (sineVal * width)
            modDelayNode.delayTime = newDelay

        case .tremolo:
            // Vary volume between (1-Depth) and 1.0
            // Sine (-1 to 1) -> Normalize to (0 to 1) -> Invert logic?
            // Standard Trem: 1.0 -> drop -> 1.0
            let normSine = (sineVal + 1.0) / 2.0 // 0 to 1
            let depth = Double(modDepth)
            // If depth 1.0, vol goes 0 to 1. If depth 0, vol stays 1.
            let vol = 1.0 - (depth * (1.0 - normSine))
            tremoloNode.outputVolume = Float(vol)
        }
    }

    private func installLevelTaps() {
        // We combine Input Level and Tuner if possible, or use separate taps.
        // AVAudioNode supports only one tap per bus.
        // So we must do Tuner processing inside the same block or tap.
        // But inputNode has only bus 0 usually.

        // Input monitoring & Tuner
        inputNode.installTap(onBus: 0, bufferSize: 4096, format: inputNode.outputFormat(forBus: 0)) { [weak self] buffer, _ in
            guard let self = self else { return }

            // 1. Level Meter
            let level = self.calculateLevel(from: buffer)

            // 2. Tuner Processing
            // We always process the tuner so it's responsive immediately when the view opens.
            // The Tuner class handles silence/noise gating internally.
            self.tuner.process(buffer: buffer)

            DispatchQueue.main.async {
                self.inputLevel = level
            }
        }
        
        // Output level monitoring
        mainMixer.installTap(onBus: 0, bufferSize: 1024, format: mainMixer.outputFormat(forBus: 0)) { [weak self] buffer, _ in
            guard let self = self else { return }
            let level = self.calculateLevel(from: buffer)
            DispatchQueue.main.async {
                self.outputLevel = level
            }
        }
    }
    
    private func installTunerTap() {
        // Integrated into installLevelTaps to avoid "Tap already installed" error
    }

    private func calculateLevel(from buffer: AVAudioPCMBuffer) -> Float {
        guard let channelData = buffer.floatChannelData else { return 0.0 }
        
        let channelDataValue = channelData.pointee
        let channelDataValueArray = stride(from: 0, to: Int(buffer.frameLength), by: buffer.stride).map { channelDataValue[$0] }
        
        let rms = sqrt(channelDataValueArray.map { $0 * $0 }.reduce(0, +) / Float(buffer.frameLength))
        let avgPower = 20 * log10(rms)
        let normalizedPower = max(0, (avgPower + 50) / 50) // Normalize to 0-1 range
        
        return normalizedPower
    }
    
    func start() {
        do {
            try engine.start()
            isEngineRunning = true
            print("Audio engine started successfully")
        } catch {
            print("Error starting audio engine: \(error.localizedDescription)")
            isEngineRunning = false
        }
    }
    
    func stop() {
        engine.stop()
        isEngineRunning = false
        print("Audio engine stopped")
    }
    
    func requestMicrophonePermission(completion: @escaping (Bool) -> Void) {
        #if os(macOS)
        AVCaptureDevice.requestAccess(for: .audio) { granted in
            DispatchQueue.main.async {
                completion(granted)
            }
        }
        #endif
    }
    
    deinit {
        stop()
    }
}
