import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:audio_output_device_check/audio_output_device_check.dart';
import 'package:audio_output_device_check/audio_output_device_check_platform_interface.dart';
import 'package:audio_output_device_check/audio_output_device_check_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockAudioOutputDeviceCheckPlatform
    with MockPlatformInterfaceMixin
    implements AudioOutputDeviceCheckPlatform {
  final _controller = StreamController<AudioDeviceInfo>.broadcast();
  var currentDeviceCalls = 0;
  var permissionRequestCalls = 0;

  @override
  Stream<AudioDeviceInfo> get audioDeviceStream => _controller.stream;

  @override
  Future<AudioDeviceInfo> getCurrentDevice() async {
    currentDeviceCalls++;
    return const AudioDeviceInfo(
      type: AudioDeviceType.speaker,
      name: 'Speaker',
    );
  }

  @override
  Future<BluetoothPermissionStatus>
  getBluetoothConnectPermissionStatus() async {
    return BluetoothPermissionStatus.notApplicable;
  }

  @override
  Future<BluetoothPermissionStatus> requestBluetoothConnectPermission() async {
    permissionRequestCalls++;
    return BluetoothPermissionStatus.notApplicable;
  }

  void emitDevice(AudioDeviceInfo device) {
    _controller.add(device);
  }

  void dispose() {
    _controller.close();
  }
}

void main() {
  final AudioOutputDeviceCheckPlatform initialPlatform =
      AudioOutputDeviceCheckPlatform.instance;

  test('$MethodChannelAudioOutputDeviceCheck is the default instance', () {
    expect(
      initialPlatform,
      isInstanceOf<MethodChannelAudioOutputDeviceCheck>(),
    );
  });

  group('AudioDeviceInfo', () {
    test('fromMap creates instance correctly', () {
      final map = {'type': 'bluetooth', 'name': 'AirPods'};
      final device = AudioDeviceInfo.fromMap(map);

      expect(device.type, AudioDeviceType.bluetooth);
      expect(device.name, 'AirPods');
    });

    test('fromMap handles missing fields with defaults', () {
      final map = <String, dynamic>{};
      final device = AudioDeviceInfo.fromMap(map);

      expect(device.type, AudioDeviceType.unknown);
      expect(device.name, 'Unknown device');
    });

    test('equality works correctly', () {
      const device1 = AudioDeviceInfo(
        type: AudioDeviceType.bluetooth,
        name: 'AirPods',
      );
      const device2 = AudioDeviceInfo(
        type: AudioDeviceType.bluetooth,
        name: 'AirPods',
      );
      const device3 = AudioDeviceInfo(
        type: AudioDeviceType.wired,
        name: 'Audio output device',
      );

      expect(device1, equals(device2));
      expect(device1, isNot(equals(device3)));
    });

    test('toMap converts correctly', () {
      const device = AudioDeviceInfo(
        type: AudioDeviceType.speaker,
        name: 'Speaker',
      );
      final map = device.toMap();

      expect(map['type'], 'speaker');
      expect(map['name'], 'Speaker');
    });

    test('fromMap converts unknown native type to unknown enum', () {
      final device = AudioDeviceInfo.fromMap({
        'type': 'future-device',
        'name': 'Future device',
      });

      expect(device.type, AudioDeviceType.unknown);
      expect(device.name, 'Future device');
    });
  });

  group('AudioOutputDeviceCheck', () {
    late MockAudioOutputDeviceCheckPlatform mockPlatform;

    setUp(() {
      mockPlatform = MockAudioOutputDeviceCheckPlatform();
      AudioOutputDeviceCheckPlatform.instance = mockPlatform;
    });

    tearDown(() {
      mockPlatform.dispose();
    });

    test('deviceStream emits device changes', () async {
      final plugin = AudioOutputDeviceCheck();

      const testDevice = AudioDeviceInfo(
        type: AudioDeviceType.bluetooth,
        name: 'AirPods Pro',
      );

      final streamFuture = plugin.deviceStream.first;
      mockPlatform.emitDevice(testDevice);

      final emittedDevice = await streamFuture;
      expect(emittedDevice, equals(testDevice));
    });

    test('deviceStream emits multiple distinct device changes', () async {
      final plugin = AudioOutputDeviceCheck();

      const device1 = AudioDeviceInfo(
        type: AudioDeviceType.speaker,
        name: 'Speaker',
      );
      const device2 = AudioDeviceInfo(
        type: AudioDeviceType.bluetooth,
        name: 'AirPods',
      );

      final devices = <AudioDeviceInfo>[];
      final subscription = plugin.deviceStream.listen(devices.add);

      mockPlatform.emitDevice(device1);
      mockPlatform.emitDevice(device1);
      mockPlatform.emitDevice(device2);

      await Future.delayed(const Duration(milliseconds: 100));

      expect(devices, [device1, device2]);
      await subscription.cancel();
    });

    test('auto-requests permission once per instance', () async {
      final plugin = AudioOutputDeviceCheck();
      final first = plugin.deviceStream.listen((_) {});
      final second = plugin.deviceStream.listen((_) {});

      await Future<void>.delayed(Duration.zero);

      expect(mockPlatform.permissionRequestCalls, 1);
      await first.cancel();
      await second.cancel();
    });

    test('separate instances auto-request permission independently', () async {
      final first = AudioOutputDeviceCheck().deviceStream.listen((_) {});
      final second = AudioOutputDeviceCheck().deviceStream.listen((_) {});

      await Future<void>.delayed(Duration.zero);

      expect(mockPlatform.permissionRequestCalls, 2);
      await first.cancel();
      await second.cancel();
    });

    test('can disable automatic permission request', () async {
      final plugin = AudioOutputDeviceCheck(
        autoRequestBluetoothPermission: false,
      );
      final subscription = plugin.deviceStream.listen((_) {});

      await Future<void>.delayed(Duration.zero);

      expect(mockPlatform.permissionRequestCalls, 0);
      await subscription.cancel();
    });

    test('currentDevice returns platform snapshot', () async {
      final device = await AudioOutputDeviceCheck().currentDevice();

      expect(device.type, AudioDeviceType.speaker);
      expect(mockPlatform.currentDeviceCalls, 1);
    });

    test('permission status API returns platform status', () async {
      final plugin = AudioOutputDeviceCheck();
      final status = await plugin.getBluetoothConnectPermissionStatus();
      expect(status, BluetoothPermissionStatus.notApplicable);
    });
  });
}
