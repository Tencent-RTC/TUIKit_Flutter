import 'package:flutter/material.dart';
import 'package:tuikit_atomic_x/device_info/device.dart';

/// 优化的设备信息测试页面
class DeviceInfoTestPage extends StatefulWidget {
  const DeviceInfoTestPage({super.key});

  @override
  State<DeviceInfoTestPage> createState() => _DeviceInfoTestPageState();
}

class _DeviceInfoTestPageState extends State<DeviceInfoTestPage> {
  String _testResult = '';
  bool _isTesting = false;
  List<TestResult> _testResults = [];

  /// 执行单个测试
  Future<void> _runTest(String testName, Future<void> Function() testFunction) async {
    setState(() {
      _isTesting = true;
      _testResult = '正在执行 $testName...\n';
    });

    try {
      await testFunction();
      _addTestResult(testName, true, '测试完成');
    } catch (e) {
      _addTestResult(testName, false, '测试失败: $e');
    }

    setState(() {
      _isTesting = false;
    });
  }

  /// 添加测试结果
  void _addTestResult(String name, bool success, String message, {String? details}) {
    _testResults.add(TestResult(
      name: name,
      success: success,
      message: message,
      details: details,
    ));
    
    setState(() {
      _testResult += '${success ? '✅' : '❌'} $name: $message\n';
      if (details != null) {
        _testResult += '   $details\n';
      }
    });
  }

  /// 测试getDeviceInfo功能
  Future<void> _testGetDeviceInfo() async {
    final platform = await Device.platform;
    final model = await Device.model;
    final manufacturer = await Device.manufacturer;
    final version = await Device.version;
    final sdkInt = await Device.sdkInt;
    
    _addTestResult(
      'getDeviceInfo',
      true,
      '设备信息获取成功',
      details: '''
平台: $platform
型号: $model
制造商: $manufacturer
版本: $version
SDK版本: ${sdkInt ?? 'N/A'}''',
    );
  }

  /// 测试平台信息
  Future<void> _testPlatform() async {
    final platform = await Device.platform;
    _addTestResult(
      'platform',
      true,
      '平台信息获取成功',
      details: '平台类型: $platform',
    );
  }

  /// 测试设备型号
  Future<void> _testModel() async {
    final model = await Device.model;
    _addTestResult(
      'model',
      true,
      '设备型号获取成功',
      details: '设备型号: $model',
    );
  }

  /// 测试制造商信息
  Future<void> _testManufacturer() async {
    final manufacturer = await Device.manufacturer;
    _addTestResult(
      'manufacturer',
      true,
      '制造商信息获取成功',
      details: '制造商: $manufacturer',
    );
  }

  /// 测试系统版本
  Future<void> _testVersion() async {
    final version = await Device.version;
    _addTestResult(
      'version',
      true,
      '系统版本获取成功',
      details: '系统版本: $version',
    );
  }

  /// 测试SDK版本
  Future<void> _testSdkInt() async {
    final sdkInt = await Device.sdkInt;
    _addTestResult(
      'sdkInt',
      true,
      'SDK版本获取成功',
      details: 'SDK版本: ${sdkInt ?? 'N/A'}',
    );
  }

  /// 测试所有功能
  Future<void> _testAll() async {
    setState(() {
      _testResults.clear();
      _testResult = '开始执行设备信息测试...\n\n';
    });

    await _runTest('platform', _testPlatform);
    await _runTest('model', _testModel);
    await _runTest('manufacturer', _testManufacturer);
    await _runTest('version', _testVersion);
    await _runTest('sdkInt', _testSdkInt);
    await _runTest('getDeviceInfo', _testGetDeviceInfo);

    _addTestResult('综合测试', true, '所有测试完成');
  }

  /// 清除测试结果
  void _clearResults() {
    setState(() {
      _testResults.clear();
      _testResult = '';
    });
  }

  /// 导出测试结果
  void _exportResults() {
    final exportText = _testResults.map((result) {
      return '${result.success ? '✅' : '❌'} ${result.name}: ${result.message}';
    }).join('\n');
    
    // 这里可以添加分享或保存功能
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('测试结果已准备导出（${_testResults.length}项）'),
        action: SnackBarAction(
          label: '复制',
          onPressed: () {
            // 实际项目中可以添加复制到剪贴板功能
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('设备信息测试'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          if (_testResults.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.share),
              onPressed: _exportResults,
              tooltip: '导出结果',
            ),
          IconButton(
            icon: const Icon(Icons.clear_all),
            onPressed: _clearResults,
            tooltip: '清除结果',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 测试按钮区域
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    ElevatedButton.icon(
                      onPressed: _isTesting ? null : _testAll,
                      icon: const Icon(Icons.play_arrow),
                      label: const Text('执行全部测试'),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 48),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _isTesting ? null : () => _runTest('platform', _testPlatform),
                            icon: const Icon(Icons.devices),
                            label: const Text('平台信息'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _isTesting ? null : () => _runTest('model', _testModel),
                            icon: const Icon(Icons.phone_android),
                            label: const Text('设备型号'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _isTesting ? null : () => _runTest('manufacturer', _testManufacturer),
                            icon: const Icon(Icons.business),
                            label: const Text('制造商'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _isTesting ? null : () => _runTest('version', _testVersion),
                            icon: const Icon(Icons.system_update),
                            label: const Text('系统版本'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _isTesting ? null : () => _runTest('sdkInt', _testSdkInt),
                            icon: const Icon(Icons.code),
                            label: const Text('SDK版本'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _isTesting ? null : () => _runTest('getDeviceInfo', _testGetDeviceInfo),
                            icon: const Icon(Icons.device_hub),
                            label: const Text('完整信息'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // 测试结果区域
            Expanded(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text(
                            '测试结果',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (_isTesting)
                            const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          if (_testResults.isNotEmpty)
                            Chip(
                              label: Text('${_testResults.length}项'),
                              backgroundColor: Colors.green[50],
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey[300]!),
                            borderRadius: BorderRadius.circular(8),
                            color: Colors.grey[50],
                          ),
                          child: SingleChildScrollView(
                            child: Text(
                              _testResult.isEmpty 
                                  ? '点击上方按钮开始测试...'
                                  : _testResult,
                              style: const TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 12,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: _isTesting 
          ? FloatingActionButton(
              onPressed: null,
              child: const CircularProgressIndicator(color: Colors.white),
            )
          : null,
    );
  }
}

class TestResult {
  final String name;
  final bool success;
  final String message;
  final String? details;

  TestResult({
    required this.name,
    required this.success,
    required this.message,
    this.details,
  });
}