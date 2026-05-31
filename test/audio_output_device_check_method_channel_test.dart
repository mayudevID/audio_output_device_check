import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:audio_output_device_check/audio_output_device_check_method_channel.dart';
import 'package:audio_output_device_check/audio_output_device_check.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const MethodChannel channel = MethodChannel('audio_output_device_check');

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
          switch (methodCall.method) {
            case 'getCurrentDevice':
              return {'type': 'bluetooth', 'name': 'AirPods'};
            case 'getBluetoothConnectPermissionStatus':
              return 'granted';
            case 'requestBluetoothConnectPermission':
              return 'denied';
            default:
              return null;
          }
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('getCurrentDevice decodes map payload', () async {
    final plugin = MethodChannelAudioOutputDeviceCheck();
    final device = await plugin.getCurrentDevice();
    expect(device.type, 'bluetooth');
    expect(device.name, 'AirPods');
  });

  test('permission status APIs map to enum', () async {
    final plugin = MethodChannelAudioOutputDeviceCheck();
    final status = await plugin.getBluetoothConnectPermissionStatus();
    final requested = await plugin.requestBluetoothConnectPermission();

    expect(status, BluetoothPermissionStatus.granted);
    expect(requested, BluetoothPermissionStatus.denied);
  });
}
