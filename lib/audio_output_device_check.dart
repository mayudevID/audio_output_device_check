import 'audio_output_device_check_platform_interface.dart';
import 'models/audio_device_info.dart';
import 'models/bluetooth_permission_status.dart';
import 'package:flutter/foundation.dart';

export 'models/audio_device_info.dart';
export 'models/bluetooth_permission_status.dart';

/// Flutter plugin for detecting audio output devices in real-time.
///
/// Provides a permission-aware stream of audio output device changes
/// across supported platforms.
class AudioOutputDeviceCheck {
  /// Creates an audio output device checker.
  ///
  /// On Android, [autoRequestBluetoothPermission] controls whether the plugin
  /// requests Bluetooth permission once before the first device query.
  AudioOutputDeviceCheck({this.autoRequestBluetoothPermission = true});

  /// Whether Android Bluetooth permission is requested automatically.
  final bool autoRequestBluetoothPermission;

  bool _didAutoRequestBluetoothPermission = false;

  /// Returns the current Android Bluetooth permission status.
  ///
  /// Other platforms return [BluetoothPermissionStatus.notApplicable].
  Future<BluetoothPermissionStatus> getBluetoothConnectPermissionStatus() {
    return AudioOutputDeviceCheckPlatform.instance
        .getBluetoothConnectPermissionStatus();
  }

  /// Requests Android Bluetooth permission.
  ///
  /// Other platforms return [BluetoothPermissionStatus.notApplicable].
  Future<BluetoothPermissionStatus> requestBluetoothConnectPermission() {
    return AudioOutputDeviceCheckPlatform.instance
        .requestBluetoothConnectPermission();
  }

  /// Emits the current audio output device and subsequent distinct changes.
  Stream<AudioDeviceInfo> get deviceStream {
    return Stream<AudioDeviceInfo>.multi((controller) {
      final sub = AudioOutputDeviceCheckPlatform.instance.audioDeviceStream
          .listen(controller.add, onError: controller.addError);
      controller.onCancel = sub.cancel;

      _refreshAfterPermission();
    }).distinct();
  }

  /// Returns a snapshot of the current audio output device.
  Future<AudioDeviceInfo> currentDevice() async {
    await _requestPermissionIfNeeded();
    return AudioOutputDeviceCheckPlatform.instance.getCurrentDevice();
  }

  Future<void> _refreshAfterPermission() async {
    try {
      await _requestPermissionIfNeeded();
      await AudioOutputDeviceCheckPlatform.instance.getCurrentDevice();
    } catch (_) {
      // Keep stream alive when a platform operation fails.
    }
  }

  Future<void> _requestPermissionIfNeeded() async {
    if (kIsWeb ||
        defaultTargetPlatform != TargetPlatform.android ||
        !autoRequestBluetoothPermission ||
        _didAutoRequestBluetoothPermission) {
      return;
    }

    _didAutoRequestBluetoothPermission = true;
    await requestBluetoothConnectPermission();
  }
}
