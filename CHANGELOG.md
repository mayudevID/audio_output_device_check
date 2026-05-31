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
