import 'package:flutter/material.dart';
import 'package:tuikit_atomic_x/permission/permission.dart';

class PermissionExample extends StatefulWidget {
  const PermissionExample({super.key});

  @override
  State<PermissionExample> createState() => _PermissionExampleState();
}

class _PermissionExampleState extends State<PermissionExample> {
  String _statusMessage = 'Ready to test permissions';
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Permission Module Example'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    if (_isLoading)
                      const CircularProgressIndicator()
                    else
                      const Icon(Icons.security, size: 48, color: Colors.blue),
                    const SizedBox(height: 16),
                    Text(
                      _statusMessage,
                      style: const TextStyle(fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Camera Permission',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _checkCameraPermission,
              icon: const Icon(Icons.check_circle_outline),
              label: const Text('Check Camera Permission'),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _requestCameraPermission,
              icon: const Icon(Icons.camera_alt),
              label: const Text('Request Camera Permission'),
            ),
            const SizedBox(height: 24),
            const Text(
              'Microphone Permission',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _checkMicrophonePermission,
              icon: const Icon(Icons.check_circle_outline),
              label: const Text('Check Microphone Permission'),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _requestMicrophonePermission,
              icon: const Icon(Icons.mic),
              label: const Text('Request Microphone Permission'),
            ),
            const SizedBox(height: 24),
            const Text(
              'Photos Permission',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _checkPhotosPermission,
              icon: const Icon(Icons.check_circle_outline),
              label: const Text('Check Photos Permission'),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _requestPhotosPermission,
              icon: const Icon(Icons.photo_library),
              label: const Text('Request Photos Permission'),
            ),
            const SizedBox(height: 24),
            const Text(
              'System Alert Window / Display Over Other Apps',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _checkSystemAlertWindowPermission,
              icon: const Icon(Icons.check_circle_outline),
              label: const Text('Check System Alert Window'),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _requestSystemAlertWindowPermission,
              icon: const Icon(Icons.picture_in_picture),
              label: const Text('Request System Alert Window'),
            ),
            const SizedBox(height: 24),
            const Text(
              'Multiple Permissions',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _requestMultiplePermissions,
              icon: const Icon(Icons.list),
              label: const Text('Request Multiple Permissions'),
            ),
            const SizedBox(height: 24),
            const Text(
              'Settings',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _openSettings,
              icon: const Icon(Icons.settings),
              label: const Text('Open App Settings'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _checkCameraPermission() async {
    setState(() => _isLoading = true);
    try {
      final status = await Permission.check(PermissionType.camera);
      setState(() {
        _statusMessage = '📷 Camera: ${_getStatusEmoji(status)} ${status.value}';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _requestCameraPermission() async {
    setState(() => _isLoading = true);
    try {
      final results = await Permission.request([PermissionType.camera]);
      final status = results[PermissionType.camera] ?? PermissionStatus.denied;
      setState(() {
        _statusMessage = '📷 Camera Request: ${_getStatusEmoji(status)} ${status.value}';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _checkMicrophonePermission() async {
    setState(() => _isLoading = true);
    try {
      final status = await Permission.check(PermissionType.microphone);
      setState(() {
        _statusMessage = '🎤 Microphone: ${_getStatusEmoji(status)} ${status.value}';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _requestMicrophonePermission() async {
    setState(() => _isLoading = true);
    try {
      final results = await Permission.request([PermissionType.microphone]);
      final status = results[PermissionType.microphone] ?? PermissionStatus.denied;
      setState(() {
        _statusMessage = '🎤 Microphone Request: ${_getStatusEmoji(status)} ${status.value}';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _checkPhotosPermission() async {
    setState(() => _isLoading = true);
    try {
      final status = await Permission.check(PermissionType.photos);
      setState(() {
        _statusMessage = '📸 Photos: ${_getStatusEmoji(status)} ${status.value}';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _requestPhotosPermission() async {
    setState(() => _isLoading = true);
    try {
      final results = await Permission.request([PermissionType.photos]);
      final status = results[PermissionType.photos] ?? PermissionStatus.denied;
      setState(() {
        _statusMessage = '📸 Photos Request: ${_getStatusEmoji(status)} ${status.value}';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _requestMultiplePermissions() async {
    setState(() => _isLoading = true);
    try {
      final results = await Permission.request([
        PermissionType.camera,
        PermissionType.microphone,
        PermissionType.photos,
      ]);

      final message = results.entries
          .map((e) {
            final name = e.key.name;
            return '$name: ${_getStatusEmoji(e.value)} ${e.value.value}';
          })
          .join('\n');

      setState(() {
        _statusMessage = 'Multiple Permissions:\n$message';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  String _getStatusEmoji(PermissionStatus status) {
    switch (status) {
      case PermissionStatus.granted:
        return '✅';
      case PermissionStatus.denied:
        return '❌';
      case PermissionStatus.permanentlyDenied:
        return '🚫';
      case PermissionStatus.limited:
        return '⚡';
    }
  }

  Future<void> _openSettings() async {
    setState(() => _isLoading = true);
    try {
      final opened = await Permission.openAppSettings();
      setState(() {
        _statusMessage = 'Open Settings: ${opened ? "✅ Success" : "❌ Failed"}';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _checkSystemAlertWindowPermission() async {
    setState(() => _isLoading = true);
    try {
      final status = await Permission.check(PermissionType.systemAlertWindow);
      setState(() {
        _statusMessage = '🪟 System Alert Window: ${_getStatusEmoji(status)} ${status.value}';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _requestSystemAlertWindowPermission() async {
    setState(() => _isLoading = true);
    try {
      final results = await Permission.request([PermissionType.systemAlertWindow]);
      final status = results[PermissionType.systemAlertWindow] ?? PermissionStatus.denied;
      setState(() {
        _statusMessage = '🪟 System Alert Window Request: ${_getStatusEmoji(status)} ${status.value}\n'
            'Note: On Android, this will open system settings.';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }
}
