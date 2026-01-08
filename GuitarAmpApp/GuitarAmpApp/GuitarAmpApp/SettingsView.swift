import SwiftUI

struct SettingsView: View {
    @ObservedObject var deviceManager: AudioDeviceManager
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        VStack(spacing: 20) {
            Text("Audio Settings")
                .font(.headline)
                .padding()

            Form {
                Section(header: Text("Input Device")) {
                    Picker("Input", selection: $deviceManager.currentInputDeviceID) {
                        ForEach(deviceManager.inputDevices, id: \.id) { device in
                            Text(device.name).tag(device.id as AudioObjectID?)
                        }
                    }
                    .onChange(of: deviceManager.currentInputDeviceID) { newID in
                        // The actual setting logic happens in AudioEngineManager or via a binding,
                        // but here we just update the ID.
                        // Note: To actually CHANGE the device on the engine, we need to call setInputDevice.
                        // We will handle this in the parent view or AudioEngineManager.
                    }
                }

                Section(header: Text("Output Device")) {
                    Picker("Output", selection: $deviceManager.currentOutputDeviceID) {
                        ForEach(deviceManager.outputDevices, id: \.id) { device in
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
