import Flutter
import UIKit
import AVFoundation

public class AudioOutputDeviceCheckPlugin: NSObject, FlutterPlugin, FlutterStreamHandler {
    private var eventSink: FlutterEventSink?

    public static func register(with registrar: FlutterPluginRegistrar) {
        let methodChannel = FlutterMethodChannel(
            name: "audio_output_device_check",
            binaryMessenger: registrar.messenger()
        )
        let eventChannel = FlutterEventChannel(
            name: "audio_output_device_check/events",
            binaryMessenger: registrar.messenger()
        )

        let instance = AudioOutputDeviceCheckPlugin()
        registrar.addMethodCallDelegate(instance, channel: methodChannel)
        eventChannel.setStreamHandler(instance)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "getCurrentDevice":
            result(getCurrentDeviceInfo())
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    // MARK: - FlutterStreamHandler

    public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        self.eventSink = events

        // Register for audio route changes
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleRouteChange),
            name: AVAudioSession.routeChangeNotification,
            object: nil
        )

        // Send initial state immediately
        events(getCurrentDeviceInfo())

        return nil
    }

    public func onCancel(withArguments arguments: Any?) -> FlutterError? {
        NotificationCenter.default.removeObserver(self)
        eventSink = nil
        return nil
    }

    // MARK: - Audio Route Detection

    @objc private func handleRouteChange(notification: Notification) {
        guard let eventSink = eventSink else { return }
        eventSink(getCurrentDeviceInfo())
    }

    private func getCurrentDeviceInfo() -> [String: String] {
        let currentRoute = AVAudioSession.sharedInstance().currentRoute

        guard let output = currentRoute.outputs.first else {
            return ["type": "speaker", "name": "Speaker"]
        }

        let portType = output.portType
        let portName = output.portName

        switch portType {
        case .bluetoothA2DP, .bluetoothHFP, .bluetoothLE:
            return ["type": "bluetooth", "name": portName]

        case .headphones, .headsetMic:
            return ["type": "wired", "name": "Audio output device"]

        case .builtInSpeaker:
            return ["type": "speaker", "name": "Speaker"]

        case .builtInReceiver:
            return ["type": "speaker", "name": "Receiver"]

        case .carAudio:
            return ["type": "bluetooth", "name": "Car Audio"]

        case .airPlay:
            return ["type": "bluetooth", "name": "AirPlay"]

        default:
            return ["type": "unknown", "name": portName]
        }
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

