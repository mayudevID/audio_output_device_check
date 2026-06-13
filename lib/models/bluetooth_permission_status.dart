/// The Android Bluetooth connection permission status.
enum BluetoothPermissionStatus {
  /// Permission is granted.
  granted,

  /// Permission is denied.
  denied,

  /// Bluetooth permission is not required on this platform.
  notApplicable,

  /// Permission status could not be determined.
  unknown;

  /// Converts a native platform channel value to a permission status.
  static BluetoothPermissionStatus fromName(String? value) {
    switch (value) {
      case 'granted':
        return BluetoothPermissionStatus.granted;
      case 'denied':
        return BluetoothPermissionStatus.denied;
      case 'notApplicable':
        return BluetoothPermissionStatus.notApplicable;
      default:
        return BluetoothPermissionStatus.unknown;
    }
  }
}
