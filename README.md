# audio_output_device_check

[![pub package](https://img.shields.io/pub/v/audio_output_device_check.svg)](https://pub.dev/packages/audio_output_device_check)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![CI](https://github.com/mayudevID/audio_output_device_check/actions/workflows/ci.yml/badge.svg)](https://github.com/mayudevID/audio_output_device_check/actions/workflows/ci.yml)

Flutter plugin to detect current audio output device and listen for output changes.

## Supported Platforms

- Android: supported
- iOS: supported
- macOS: supported
- Windows: supported (snapshot + name detection)
- Linux: supported (snapshot + name detection via `pactl` when available)

## Installation

Add dependency in your app `pubspec.yaml`:

```yaml
dependencies:
  audio_output_device_check: ^0.2.0
```

## Usage

```dart
import 'package:audio_output_device_check/audio_output_device_check.dart';

final plugin = AudioOutputDeviceCheck(
  autoRequestBluetoothPermission: true,
);

final current = await plugin.currentDevice();
print('Current output: ${current.type.name} - ${current.name}');

plugin.deviceStream.listen((device) {
  print('Audio output changed: ${device.type.name} - ${device.name}');
});
```

## Android Bluetooth Permission API

Plugin provides optional Android `BLUETOOTH_CONNECT` permission helpers:

```dart
final status = await plugin.getBluetoothConnectPermissionStatus();
final requested = await plugin.requestBluetoothConnectPermission();
```

Behavior:
- On Android: permission is requested automatically at most once per plugin
  instance when `deviceStream` or `currentDevice()` is used.
- Set `autoRequestBluetoothPermission: false` to disable automatic requests.
- On non-Android platforms: permission APIs return `BluetoothPermissionStatus.notApplicable`.
- On permission/API failures: plugin returns safe fallback device info instead of throwing.

## Device Type Values

`AudioDeviceInfo.type` uses the `AudioDeviceType` enum:
- `AudioDeviceType.bluetooth`
- `AudioDeviceType.wired`
- `AudioDeviceType.speaker`
- `AudioDeviceType.unknown`

## Migrating from 0.1.x

```dart
// Before
plugin.audioDeviceStreamWithPermission().listen(...);
if (device.type == 'bluetooth') {}

// 0.2.0
plugin.deviceStream.listen(...);
if (device.type == AudioDeviceType.bluetooth) {}
```

`BluetoothPermissionStatus.permanentlyDenied` and
`BluetoothPermissionStatus.restricted` were removed because they could not be
reported consistently across supported platforms.

## Notes

- Linux device name detection uses `pactl` command output. If unavailable, fallback value is returned.
- Stream emits current snapshot on listen; additional real-time update behavior depends on platform capabilities.
