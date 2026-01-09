import Foundation
import AVFoundation
import CoreAudio
import AudioToolbox
import Combine

struct AudioDevice: Identifiable, Hashable {
    let id: AudioObjectID
    let name: String
    let isInput: Bool
    let isOutput: Bool
}

class AudioDeviceManager: ObservableObject {
    @Published var inputDevices: [AudioDevice] = []
    @Published var outputDevices: [AudioDevice] = []

    @Published var currentInputDeviceID: AudioObjectID?
    @Published var currentOutputDeviceID: AudioObjectID?

    init() {
        refreshDevices()
    }

    func refreshDevices() {
        self.inputDevices = getDevices(input: true)
        self.outputDevices = getDevices(input: false)
    }

    private func getDevices(input: Bool) -> [AudioDevice] {
        var propertyAddress = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDevices,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )

        var dataSize: UInt32 = 0
        let status = AudioObjectGetPropertyDataSize(AudioObjectID(kAudioObjectSystemObject),
                                                    &propertyAddress,
                                                    0,
                                                    nil,
                                                    &dataSize)

        guard status == noErr else {
            print("Error getting device list size: \(status)")
            return []
        }

        let deviceCount = Int(dataSize) / MemoryLayout<AudioObjectID>.size
        var deviceIDs = [AudioObjectID](repeating: 0, count: deviceCount)

        let status2 = AudioObjectGetPropertyData(AudioObjectID(kAudioObjectSystemObject),
                                                 &propertyAddress,
                                                 0,
                                                 nil,
                                                 &dataSize,
                                                 &deviceIDs)

        guard status2 == noErr else {
            print("Error getting device list: \(status2)")
            return []
        }

        var devices: [AudioDevice] = []

        for id in deviceIDs {
            // Check if input or output
            let isInput = checkDeviceChannels(id: id, scope: kAudioDevicePropertyScopeInput) > 0
            let isOutput = checkDeviceChannels(id: id, scope: kAudioDevicePropertyScopeOutput) > 0

            // Filter based on request
            if (input && isInput) || (!input && isOutput) {
                if let name = getDeviceName(id: id) {
                    devices.append(AudioDevice(id: id, name: name, isInput: isInput, isOutput: isOutput))
                }
            }
        }

        return devices
    }

    private func checkDeviceChannels(id: AudioObjectID, scope: AudioObjectPropertyScope) -> Int {
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyStreams,
            mScope: scope,
            mElement: kAudioObjectPropertyElementMain
        )

        var size: UInt32 = 0
        AudioObjectGetPropertyDataSize(id, &address, 0, nil, &size)
        return Int(size)
    }

    private func getDeviceName(id: AudioObjectID) -> String? {
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioObjectPropertyName,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )

        var name: CFString = "" as CFString
        var size = UInt32(MemoryLayout<CFString>.size)

        let status = AudioObjectGetPropertyData(id, &address, 0, nil, &size, &name)
        if status == noErr {
            return name as String
        }
        return nil
    }

    func setInputDevice(id: AudioObjectID, for inputNode: AVAudioInputNode) {
        // To set the input device for the engine, we often rely on the system default or use the specific AU
        // But AVAudioEngine's inputNode communicates with the hardware.
        // We set the current device property on the AudioUnit of the inputNode.

        let audioUnit = inputNode.audioUnit!
        var deviceID = id

        let status = AudioUnitSetProperty(audioUnit,
                                          kAudioOutputUnitProperty_CurrentDevice,
                                          kAudioUnitScope_Global,
                                          0,
                                          &deviceID,
                                          UInt32(MemoryLayout<AudioObjectID>.size))

        if status == noErr {
            print("Successfully set input device to ID: \(id)")
            DispatchQueue.main.async {
                self.currentInputDeviceID = id
            }
        } else {
            print("Error setting input device: \(status)")
        }
    }

    func setOutputDevice(id: AudioObjectID, for outputNode: AVAudioOutputNode) {
        let audioUnit = outputNode.audioUnit!
        var deviceID = id

        let status = AudioUnitSetProperty(audioUnit,
                                          kAudioOutputUnitProperty_CurrentDevice,
                                          kAudioUnitScope_Global,
                                          0,
                                          &deviceID,
                                          UInt32(MemoryLayout<AudioObjectID>.size))

        if status == noErr {
            print("Successfully set output device to ID: \(id)")
            DispatchQueue.main.async {
                self.currentOutputDeviceID = id
            }
        } else {
            print("Error setting output device: \(status)")
        }
    }
}
