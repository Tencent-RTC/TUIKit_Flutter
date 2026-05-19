import 'package:flutter/material.dart';
import 'device_info/device_info_test_page.dart';
import 'permission_example.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Atomic-X Example',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const AtomicXExampleHome(),
    );
  }
}

/// Atomic-X 示例主页
class AtomicXExampleHome extends StatelessWidget {
  const AtomicXExampleHome({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Atomic-X Example'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.developer_board, size: 64, color: Colors.deepPurple),
            SizedBox(height: 16),
            Text(
              'Atomic-X Examples',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              '选择要测试的功能模块',
              style: TextStyle(fontSize: 16, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton.extended(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const PermissionExample(),
                ),
              );
            },
            icon: const Icon(Icons.security),
            label: const Text('权限验证'),
            heroTag: 'permission',
          ),
          const SizedBox(height: 16),
          FloatingActionButton.extended(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const DeviceInfoTestPage(),
                ),
              );
            },
            icon: const Icon(Icons.phone_android),
            label: const Text('设备信息'),
            heroTag: 'device_info',
          ),
        ],
      ),
    );
  }
}
