import 'package:flutter/material.dart';
import 'package:audio_output_device_check/audio_output_device_check.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Audio Output Device Check',
      theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
      home: const AudioDeviceDemo(),
    );
  }
}

class AudioDeviceDemo extends StatefulWidget {
  const AudioDeviceDemo({super.key});

  @override
  State<AudioDeviceDemo> createState() => _AudioDeviceDemoState();
}

class _AudioDeviceDemoState extends State<AudioDeviceDemo> {
  final _audioOutputDeviceCheckPlugin = AudioOutputDeviceCheck();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Audio Output Device Check'),
        elevation: 2,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Current Audio Output:',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 32),
              StreamBuilder<AudioDeviceInfo>(
                stream: _audioOutputDeviceCheckPlugin.deviceStream,
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return _buildErrorState(snapshot.error.toString());
                  }

                  if (!snapshot.hasData) {
                    return const CircularProgressIndicator();
                  }

                  final device = snapshot.data!;
                  return _buildDeviceInfo(device);
                },
              ),
              const SizedBox(height: 48),
              const Text(
                'Try connecting or disconnecting:',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 8),
              const Text(
                '• Bluetooth headphones\n'
                '• Wired headphones\n'
                '• Toggle Bluetooth on/off',
                style: TextStyle(fontSize: 14, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDeviceInfo(AudioDeviceInfo device) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _getIconForDeviceType(device.type),
              size: 80,
              color: _getColorForDeviceType(device.type),
            ),
            const SizedBox(height: 16),
            Text(
              device.name,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _getColorForDeviceType(
                  device.type,
                ).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                device.type.name.toUpperCase(),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _getColorForDeviceType(device.type),
                  letterSpacing: 1.2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Card(
      elevation: 4,
      color: Colors.red.shade50,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 80, color: Colors.red),
            const SizedBox(height: 16),
            const Text(
              'Error',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: const TextStyle(fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  IconData _getIconForDeviceType(AudioDeviceType type) {
    switch (type) {
      case AudioDeviceType.bluetooth:
        return Icons.bluetooth_audio;
      case AudioDeviceType.wired:
        return Icons.headset;
      case AudioDeviceType.speaker:
        return Icons.speaker;
      case AudioDeviceType.unknown:
        return Icons.volume_up;
    }
  }

  Color _getColorForDeviceType(AudioDeviceType type) {
    switch (type) {
      case AudioDeviceType.bluetooth:
        return Colors.blue;
      case AudioDeviceType.wired:
        return Colors.green;
      case AudioDeviceType.speaker:
        return Colors.orange;
      case AudioDeviceType.unknown:
        return Colors.grey;
    }
  }
}
