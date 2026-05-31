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
  audio_output_device_check: ^0.1.1
```

## Usage

```dart
import 'package:audio_output_device_check/audio_output_device_check.dart';

final plugin = AudioOutputDeviceCheck();
plugin.audioDeviceStreamWithPermission(
  autoRequestAndroidBluetoothPermission: true,
).listen((device) {
  print('Audio output changed: ${device.type} - ${device.name}');
});
```

## Android Bluetooth Permission API

Plugin provides optional Android `BLUETOOTH_CONNECT` permission helpers:

```dart
final status = await plugin.getBluetoothConnectPermissionStatus();
final requested = await plugin.requestBluetoothConnectPermission();
```

Behavior:
- On Android: permission can be requested automatically when stream starts.
- On non-Android platforms: permission APIs return `BluetoothPermissionStatus.notApplicable`.
- On permission/API failures: plugin returns safe fallback device info instead of throwing.

## Device Type Values

`AudioDeviceInfo.type` can be:
- `bluetooth`
- `wired`
- `speaker`
- `unknown`

## Notes

- Linux device name detection uses `pactl` command output. If unavailable, fallback value is returned.
- Stream emits current snapshot on listen; additional real-time update behavior depends on platform capabilities.
