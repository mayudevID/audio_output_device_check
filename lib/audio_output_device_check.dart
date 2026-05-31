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
  static bool _didAutoRequestBluetoothPermission = false;

  Future<BluetoothPermissionStatus> getBluetoothConnectPermissionStatus() {
    return AudioOutputDeviceCheckPlatform.instance
        .getBluetoothConnectPermissionStatus();
  }

  Future<BluetoothPermissionStatus> requestBluetoothConnectPermission() {
    return AudioOutputDeviceCheckPlatform.instance
        .requestBluetoothConnectPermission();
  }

  Stream<AudioDeviceInfo> audioDeviceStreamWithPermission({
    bool autoRequestAndroidBluetoothPermission = true,
  }) {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return AudioOutputDeviceCheckPlatform.instance.audioDeviceStream;
    }

    if (!autoRequestAndroidBluetoothPermission) {
      return AudioOutputDeviceCheckPlatform.instance.audioDeviceStream;
    }

    return Stream.multi((controller) {
      final sub = AudioOutputDeviceCheckPlatform.instance.audioDeviceStream
          .listen(controller.add, onError: controller.addError);
      controller.onCancel = sub.cancel;

      if (!_didAutoRequestBluetoothPermission) {
        _didAutoRequestBluetoothPermission = true;
        Future<void>(() async {
          try {
            await requestBluetoothConnectPermission();
            await AudioOutputDeviceCheckPlatform.instance.getCurrentDevice();
          } catch (_) {
            // Keep stream alive even if permission request fails.
          }
        });
      }
    });
  }
}
