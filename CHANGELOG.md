## 0.2.0

* Replace `audioDeviceStreamWithPermission()` with the `deviceStream` getter.
* Add public `currentDevice()` for one-time device snapshots.
* Add `AudioDeviceType` enum and replace string-based device types.
* Configure Android automatic Bluetooth permission requests through the
  `AudioOutputDeviceCheck` constructor.
* Limit automatic Bluetooth permission requests to once per plugin instance.
* Deduplicate repeated device events.
* Simplify `BluetoothPermissionStatus` to `granted`, `denied`,
  `notApplicable`, and `unknown`.

## 0.1.2

* Normalize default/fallback device names to English across platforms:
  * `Perangkat tidak diketahui` -> `Unknown device`
  * `Perangkat output audio` -> `Audio output device`
* Update Dart model defaults and tests to match new naming.

## 0.1.1

* Add complete package metadata for `pub.dev`:
  * `repository`
  * `issue_tracker`
  * `documentation`
  * `topics`
* Replace placeholder `LICENSE` with MIT License text.

## 0.1.0

* Remove legacy public APIs `audioDeviceStream` and `getCurrentDevice()`.
* Add Windows and Linux platform implementations.
* Add Android Bluetooth permission APIs:
  * `getBluetoothConnectPermissionStatus()`
  * `requestBluetoothConnectPermission()`
* Add `audioDeviceStreamWithPermission()` for permission-aware stream usage.
* Improve plugin documentation for Pub.dev usage and platform behavior.
