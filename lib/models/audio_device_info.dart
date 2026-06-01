/// Represents information about an audio output device
class AudioDeviceInfo {
  const AudioDeviceInfo({required this.type, required this.name});

  /// Creates an [AudioDeviceInfo] from a platform channel map
  factory AudioDeviceInfo.fromMap(Map<dynamic, dynamic> map) {
    return AudioDeviceInfo(
      type: map['type'] as String? ?? 'unknown',
      name: map['name'] as String? ?? 'Unknown device',
    );
  }

  /// The type of audio device: "bluetooth", "wired", "speaker", or "unknown"
  final String type;

  /// The display name of the device
  /// - For Bluetooth devices: the brand/device name (e.g., "AirPods", "Sony WH-1000XM4")
  /// - For wired devices: "Audio output device"
  /// - For speaker: "Speaker"
  final String name;

  /// Converts this [AudioDeviceInfo] to a map for platform channels
  Map<String, String> toMap() {
    return {'type': type, 'name': name};
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is AudioDeviceInfo && other.type == type && other.name == name;
  }

  @override
  int get hashCode => type.hashCode ^ name.hashCode;

  @override
  String toString() => 'AudioDeviceInfo(type: $type, name: $name)';
}
