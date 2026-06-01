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

  @override
  Stream<AudioDeviceInfo> get audioDeviceStream => _controller.stream;

  @override
  Future<AudioDeviceInfo> getCurrentDevice() async {
    return const AudioDeviceInfo(type: 'speaker', name: 'Speaker');
  }

  @override
  Future<BluetoothPermissionStatus>
  getBluetoothConnectPermissionStatus() async {
    return BluetoothPermissionStatus.notApplicable;
  }

  @override
  Future<BluetoothPermissionStatus> requestBluetoothConnectPermission() async {
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

      expect(device.type, 'bluetooth');
      expect(device.name, 'AirPods');
    });

    test('fromMap handles missing fields with defaults', () {
      final map = <String, dynamic>{};
      final device = AudioDeviceInfo.fromMap(map);

      expect(device.type, 'unknown');
      expect(device.name, 'Unknown device');
    });

    test('equality works correctly', () {
      const device1 = AudioDeviceInfo(type: 'bluetooth', name: 'AirPods');
      const device2 = AudioDeviceInfo(type: 'bluetooth', name: 'AirPods');
      const device3 = AudioDeviceInfo(
        type: 'wired',
        name: 'Audio output device',
      );

      expect(device1, equals(device2));
      expect(device1, isNot(equals(device3)));
    });

    test('toMap converts correctly', () {
      const device = AudioDeviceInfo(type: 'speaker', name: 'Speaker');
      final map = device.toMap();

      expect(map['type'], 'speaker');
      expect(map['name'], 'Speaker');
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

    test('audioDeviceStreamWithPermission emits device changes', () async {
      final plugin = AudioOutputDeviceCheck();

      const testDevice = AudioDeviceInfo(
        type: 'bluetooth',
        name: 'AirPods Pro',
      );

      // Listen to stream
      final streamFuture = plugin.audioDeviceStreamWithPermission().first;

      // Emit device
      mockPlatform.emitDevice(testDevice);

      // Verify
      final emittedDevice = await streamFuture;
      expect(emittedDevice, equals(testDevice));
    });

    test(
      'audioDeviceStreamWithPermission emits multiple device changes',
      () async {
        final plugin = AudioOutputDeviceCheck();

        const device1 = AudioDeviceInfo(type: 'speaker', name: 'Speaker');
        const device2 = AudioDeviceInfo(type: 'bluetooth', name: 'AirPods');
        const device3 = AudioDeviceInfo(
          type: 'wired',
          name: 'Audio output device',
        );

        final devices = <AudioDeviceInfo>[];
        final subscription = plugin.audioDeviceStreamWithPermission().listen(
          devices.add,
        );

        mockPlatform.emitDevice(device1);
        mockPlatform.emitDevice(device2);
        mockPlatform.emitDevice(device3);

        await Future.delayed(const Duration(milliseconds: 100));

        expect(devices.length, 3);
        expect(devices[0], equals(device1));
        expect(devices[1], equals(device2));
        expect(devices[2], equals(device3));

        await subscription.cancel();
      },
    );

    test('permission status API returns platform status', () async {
      final plugin = AudioOutputDeviceCheck();
      final status = await plugin.getBluetoothConnectPermissionStatus();
      expect(status, BluetoothPermissionStatus.notApplicable);
    });
  });
}
