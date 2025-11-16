import AVFoundation
import Accelerate
import Combine

class AudioEngineManager: ObservableObject {
    private let engine = AVAudioEngine()
    private let inputNode: AVAudioInputNode
    private let mainMixer: AVAudioMixerNode
    
    // Effects nodes
    private let distortionNode = AVAudioUnitDistortion()
    private let reverbNode = AVAudioUnitReverb()
    private let delayNode = AVAudioUnitDelay()
    private let eqNode = AVAudioUnitEQ(numberOfBands: 3)
    
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
    }
    
    private func setupAudioSession() {
        #if os(macOS)
        // macOS doesn't require audio session configuration like iOS
        #endif
    }
    
    private func setupEffectsChain() {
        // Attach all nodes
        engine.attach(distortionNode)
        engine.attach(eqNode)
        engine.attach(delayNode)
        engine.attach(reverbNode)
        
        // Get the input format
        let inputFormat = inputNode.outputFormat(forBus: 0)
        
        // Create the effects chain: Input -> Distortion -> EQ -> Delay -> Reverb -> Output
        engine.connect(inputNode, to: distortionNode, format: inputFormat)
        engine.connect(distortionNode, to: eqNode, format: inputFormat)
        engine.connect(eqNode, to: delayNode, format: inputFormat)
        engine.connect(delayNode, to: reverbNode, format: inputFormat)
        engine.connect(reverbNode, to: mainMixer, format: inputFormat)
        
        // Install taps for level monitoring
        installLevelTaps()
    }
    
    private func configureInitialSettings() {
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
    
    private func installLevelTaps() {
        // Input level monitoring
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: inputNode.outputFormat(forBus: 0)) { [weak self] buffer, _ in
            guard let self = self else { return }
            let level = self.calculateLevel(from: buffer)
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
