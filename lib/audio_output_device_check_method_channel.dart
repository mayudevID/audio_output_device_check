import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'audio_output_device_check_platform_interface.dart';
import 'models/audio_device_info.dart';
import 'models/bluetooth_permission_status.dart';

/// An implementation of [AudioOutputDeviceCheckPlatform] that uses method channels.
class MethodChannelAudioOutputDeviceCheck
    extends AudioOutputDeviceCheckPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('audio_output_device_check');

  /// The event channel used to receive audio device change events.
  @visibleForTesting
  final eventChannel = const EventChannel('audio_output_device_check/events');

  /// Cache for the audio device stream
  Stream<AudioDeviceInfo>? _eventStream;
  AudioDeviceInfo? _lastKnown;

  @override
  Stream<AudioDeviceInfo> get audioDeviceStream {
    _eventStream ??= eventChannel
        .receiveBroadcastStream()
        .map((event) {
          try {
            if (event is Map) {
              final info = AudioDeviceInfo.fromMap(event);
              _lastKnown = info;
              return info;
            }

            debugPrint('Unexpected event type: ${event.runtimeType}');
            const info = AudioDeviceInfo(
              type: AudioDeviceType.unknown,
              name: 'Unknown device',
            );
            _lastKnown = info;
            return info;
          } catch (e) {
            debugPrint('Error parsing audio device info: $e');
            const info = AudioDeviceInfo(
              type: AudioDeviceType.unknown,
              name: 'Unknown device',
            );
            _lastKnown = info;
            return info;
          }
        })
        .handleError((error) {
          debugPrint('Audio device stream error: $error');
        });

    // Important: EventChannel's onListen only fires for the FIRST Dart listener.
    // If another page adds a new listener while the stream is already active,
    // it may never receive the initial "current device" event. To fix that,
    // replay the last known value (or fetch it) for each listener.
    return Stream.multi((controller) {
      final cached = _lastKnown;
      if (cached != null) {
        controller.add(cached);
      } else {
        getCurrentDevice()
            .then((value) {
              _lastKnown = value;
              controller.add(value);
            })
            .catchError((_) {
              // Ignore; the event stream below may still emit.
            });
      }

      final sub = _eventStream!.listen(
        controller.add,
        onError: controller.addError,
      );
      controller.onCancel = sub.cancel;
    });
  }

  @override
  Future<AudioDeviceInfo> getCurrentDevice() async {
    try {
      final result = await methodChannel.invokeMethod<Map>('getCurrentDevice');
      if (result == null) {
        return const AudioDeviceInfo(
          type: AudioDeviceType.unknown,
          name: 'Unknown device',
        );
      }
      return AudioDeviceInfo.fromMap(result);
    } catch (e) {
      debugPrint('Error getting current device: $e');
      return const AudioDeviceInfo(
        type: AudioDeviceType.unknown,
        name: 'Unknown device',
      );
    }
  }

  @override
  Future<BluetoothPermissionStatus>
  getBluetoothConnectPermissionStatus() async {
    try {
      final result = await methodChannel.invokeMethod<String>(
        'getBluetoothConnectPermissionStatus',
      );
      return BluetoothPermissionStatus.fromName(result);
    } catch (e) {
      debugPrint('Error getting bluetooth permission status: $e');
      return BluetoothPermissionStatus.unknown;
    }
  }

  @override
  Future<BluetoothPermissionStatus> requestBluetoothConnectPermission() async {
    try {
      final result = await methodChannel.invokeMethod<String>(
        'requestBluetoothConnectPermission',
      );
      return BluetoothPermissionStatus.fromName(result);
    } catch (e) {
      debugPrint('Error requesting bluetooth permission: $e');
      return BluetoothPermissionStatus.unknown;
    }
  }
}
