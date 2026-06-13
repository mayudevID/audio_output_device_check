/// The detected audio output device category.
enum AudioDeviceType {
  /// A Bluetooth audio output device.
  bluetooth,

  /// A wired, USB, or HDMI audio output device.
  wired,

  /// A built-in speaker.
  speaker,

  /// An unavailable or unrecognized audio output device.
  unknown;

  /// Converts a native platform channel value to an [AudioDeviceType].
  factory AudioDeviceType.fromName(String? value) {
    return switch (value) {
      'bluetooth' => AudioDeviceType.bluetooth,
      'wired' => AudioDeviceType.wired,
      'speaker' => AudioDeviceType.speaker,
      _ => AudioDeviceType.unknown,
    };
  }
}

/// Represents information about an audio output device
class AudioDeviceInfo {
  const AudioDeviceInfo({required this.type, required this.name});

  /// Creates an [AudioDeviceInfo] from a platform channel map
  factory AudioDeviceInfo.fromMap(Map<dynamic, dynamic> map) {
    return AudioDeviceInfo(
      type: AudioDeviceType.fromName(map['type'] as String?),
      name: map['name'] as String? ?? 'Unknown device',
    );
  }

  /// The detected audio output device type.
  final AudioDeviceType type;

  /// The display name of the device
  /// - For Bluetooth devices: the brand/device name (e.g., "AirPods", "Sony WH-1000XM4")
  /// - For wired devices: "Audio output device"
  /// - For speaker: "Speaker"
  final String name;

  /// Converts this [AudioDeviceInfo] to a map for platform channels
  Map<String, String> toMap() {
    return {'type': type.name, 'name': name};
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
