import SwiftUI

struct ContentView: View {
    @StateObject private var audioEngine = AudioEngineManager()
    @State private var showingPermissionAlert = false
    @State private var showingSettings = false
    @State private var showingTuner = false
    
    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                gradient: Gradient(colors: [Color(red: 0.1, green: 0.1, blue: 0.12), Color(red: 0.15, green: 0.15, blue: 0.17)]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 20) {
                // Header
                headerView
                
                // Signal flow indicator
                signalFlowView
                
                // Pedal board
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 30) {
                        // Pre-Amp
                        NoiseGateView(audioEngine: audioEngine)
                        CompressorPedalView(audioEngine: audioEngine)
                        OverdrivePedalView(audioEngine: audioEngine)

                        Divider().background(Color.gray)

                        // FX Loop (Logically here, visually grouping pedals)
                        ModulationPedalView(audioEngine: audioEngine)
                        DelayPedalView(audioEngine: audioEngine)
                        ReverbPedalView(audioEngine: audioEngine)
                    }
                    .padding(.horizontal, 40)
                    .padding(.vertical, 20)
                }
                .frame(height: 280)
                
                // Amp section
                AmpView(audioEngine: audioEngine)
                
                Spacer()
                
                // Level meters and power
                bottomControlsView
            }
            .padding()
        }
        .frame(minWidth: 900, minHeight: 700)
        .onAppear {
            requestPermissionAndStart()
        }
        .alert("Microphone Permission Required", isPresented: $showingPermissionAlert) {
            Button("OK") {
                // User can grant permission in System Preferences
            }
        } message: {
            Text("Please grant microphone access in System Preferences to use this app.")
        }
    }
    
    private var headerView: some View {
        HStack {
            Image(systemName: "music.note")
                .font(.system(size: 30))
                .foregroundColor(.orange)
            
            Text("Guitar Amp & Effects")
                .font(.system(size: 32, weight: .bold))
                .foregroundColor(.white)
            
            Spacer()
            
            // Power button
            // Settings Button
            Button(action: { showingSettings = true }) {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.gray)
            }
            .buttonStyle(.plain)
            .popover(isPresented: $showingSettings) {
                SettingsView(deviceManager: audioEngine.deviceManager)
            }

            // Tuner Button
            Button(action: { showingTuner = true }) {
                Image(systemName: "tuningfork")
                    .font(.system(size: 20))
                    .foregroundColor(showingTuner ? .orange : .gray)
            }
            .buttonStyle(.plain)
            .sheet(isPresented: $showingTuner) {
                TunerView(tuner: audioEngine.tuner)
            }

            // Power button
            Button(action: {
                if audioEngine.isEngineRunning {
                    audioEngine.stop()
                } else {
                    audioEngine.start()
                }
            }) {
                Image(systemName: audioEngine.isEngineRunning ? "power.circle.fill" : "power.circle")
                    .font(.system(size: 30))
                    .foregroundColor(audioEngine.isEngineRunning ? .green : .red)
            }
            .buttonStyle(.plain)
        }
        .padding()
    }
    
    private var signalFlowView: some View {
        HStack(spacing: 8) {
            Text("IN")
                .font(.caption)
                .foregroundColor(.gray)
            
            Group {
                Image(systemName: "arrow.right").foregroundColor(.gray)
                Text("GATE").font(.caption).foregroundColor(audioEngine.gateThreshold > 0 ? .green : .gray)

                Image(systemName: "arrow.right").foregroundColor(.gray)
                Text("CMP").font(.caption).foregroundColor(audioEngine.compEnabled ? .orange : .gray)

                Image(systemName: "arrow.right").foregroundColor(.gray)
                Text("OD").font(.caption).foregroundColor(audioEngine.distortionEnabled ? .orange : .gray)

                Image(systemName: "arrow.right").foregroundColor(.gray)
                Text("AMP").font(.caption).foregroundColor(.orange)

                Image(systemName: "arrow.right").foregroundColor(.gray)
                Text("MOD").font(.caption).foregroundColor(audioEngine.modEnabled ? .blue : .gray)

                Image(systemName: "arrow.right").foregroundColor(.gray)
                Text("CAB").font(.caption).foregroundColor(audioEngine.cabSim.activeModel != .bypass ? .green : .gray)
            }
            
            Group {
                Image(systemName: "arrow.right").foregroundColor(.gray)
                Text("DLY").font(.caption).foregroundColor(audioEngine.delayEnabled ? .orange : .gray)

                Image(systemName: "arrow.right").foregroundColor(.gray)
                Text("REV").font(.caption).foregroundColor(audioEngine.reverbEnabled ? .orange : .gray)

                Image(systemName: "arrow.right").foregroundColor(.gray)
                Text("OUT").font(.caption).foregroundColor(.gray)
            }
        }
        .padding(8)
        .background(Color.black.opacity(0.3))
        .cornerRadius(8)
    }
    
    private var bottomControlsView: some View {
        HStack(spacing: 40) {
            // Input level meter
            VStack {
                Text("INPUT")
                    .font(.caption)
                    .foregroundColor(.gray)
                LevelMeter(level: audioEngine.inputLevel, color: .green)
                    .frame(width: 100, height: 20)
            }
            
            Spacer()
            
            // Status indicator
            HStack {
                Circle()
                    .fill(audioEngine.isEngineRunning ? Color.green : Color.red)
                    .frame(width: 12, height: 12)
                Text(audioEngine.isEngineRunning ? "ACTIVE" : "BYPASSED")
                    .font(.caption)
                    .foregroundColor(.white)
            }
            
            Spacer()
            
            // Output level meter
            VStack {
                Text("OUTPUT")
                    .font(.caption)
                    .foregroundColor(.gray)
                LevelMeter(level: audioEngine.outputLevel, color: .orange)
                    .frame(width: 100, height: 20)
            }
        }
        .padding()
        .background(Color.black.opacity(0.3))
        .cornerRadius(8)
    }
    
    private func requestPermissionAndStart() {
        audioEngine.requestMicrophonePermission { granted in
            if granted {
                audioEngine.start()
            } else {
                showingPermissionAlert = true
            }
        }
    }
}

// MARK: - Level Meter
struct LevelMeter: View {
    let level: Float
    let color: Color
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(Color.black.opacity(0.5))
                
                Rectangle()
                    .fill(color)
                    .frame(width: geometry.size.width * CGFloat(level))
            }
            .cornerRadius(4)
            .overlay(
                RoundedRectangle(cornerRadius: 4)
                    .stroke(Color.gray.opacity(0.5), lineWidth: 1)
            )
        }
    }
}

#Preview {
    ContentView()
        .frame(width: 900, height: 700)
}
