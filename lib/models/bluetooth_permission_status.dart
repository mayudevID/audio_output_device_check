enum BluetoothPermissionStatus {
  granted,
  denied,
  permanentlyDenied,
  restricted,
  notApplicable,
  unknown;

  static BluetoothPermissionStatus fromName(String? value) {
    switch (value) {
      case 'granted':
        return BluetoothPermissionStatus.granted;
      case 'denied':
        return BluetoothPermissionStatus.denied;
      case 'permanentlyDenied':
        return BluetoothPermissionStatus.permanentlyDenied;
      case 'restricted':
        return BluetoothPermissionStatus.restricted;
      case 'notApplicable':
        return BluetoothPermissionStatus.notApplicable;
      default:
        return BluetoothPermissionStatus.unknown;
    }
  }
}
