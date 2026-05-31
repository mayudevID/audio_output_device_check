import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'audio_output_device_check_method_channel.dart';
import 'models/audio_device_info.dart';
import 'models/bluetooth_permission_status.dart';

abstract class AudioOutputDeviceCheckPlatform extends PlatformInterface {
  /// Constructs a AudioOutputDeviceCheckPlatform.
  AudioOutputDeviceCheckPlatform() : super(token: _token);

  static final Object _token = Object();

  static AudioOutputDeviceCheckPlatform _instance =
      MethodChannelAudioOutputDeviceCheck();

  /// The default instance of [AudioOutputDeviceCheckPlatform] to use.
  ///
  /// Defaults to [MethodChannelAudioOutputDeviceCheck].
  static AudioOutputDeviceCheckPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [AudioOutputDeviceCheckPlatform] when
  /// they register themselves.
  static set instance(AudioOutputDeviceCheckPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  /// Stream of audio device changes
  ///
  /// Emits a new [AudioDeviceInfo] whenever the audio output device changes,
  /// including when devices are connected/disconnected or Bluetooth state changes.
  Stream<AudioDeviceInfo> get audioDeviceStream {
    throw UnimplementedError('audioDeviceStream has not been implemented.');
  }

  /// Gets the current audio output device
  ///
  /// Returns the currently active [AudioDeviceInfo] immediately.
  Future<AudioDeviceInfo> getCurrentDevice() {
    throw UnimplementedError('getCurrentDevice() has not been implemented.');
  }

  Future<BluetoothPermissionStatus> getBluetoothConnectPermissionStatus() {
    return Future.value(BluetoothPermissionStatus.notApplicable);
  }

  Future<BluetoothPermissionStatus> requestBluetoothConnectPermission() {
    return Future.value(BluetoothPermissionStatus.notApplicable);
  }
}
