import SwiftUI
import CoreAudio

struct SettingsView: View {
    @ObservedObject var audioEngine: AudioEngineManager
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        VStack(spacing: 20) {
            Text("Audio Settings")
                .font(.headline)
                .padding()

            Form {
                Section(header: Text("Input Device")) {
                    Picker("Input", selection: $audioEngine.deviceManager.currentInputDeviceID) {
                        ForEach(audioEngine.deviceManager.inputDevices, id: \.id) { device in
                            Text(device.name).tag(device.id as AudioObjectID?)
                        }
                    }

                    Picker("Input Channel", selection: $audioEngine.inputChannel) {
                        Text("Channel 1").tag(0)
                        Text("Channel 2").tag(1)
                    }
                }

                Section(header: Text("Output Device")) {
                    Picker("Output", selection: $audioEngine.deviceManager.currentOutputDeviceID) {
                        ForEach(audioEngine.deviceManager.outputDevices, id: \.id) { device in
                            Text(device.name).tag(device.id as AudioObjectID?)
                        }
                    }
                }
            }
            .frame(width: 400, height: 200)

            Button("Done") {
                presentationMode.wrappedValue.dismiss()
            }
            .padding()
        }
        .padding()
    }
}
