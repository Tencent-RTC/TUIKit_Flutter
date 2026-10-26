import 'dart:io';

import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

class LogFileBrowser extends StatefulWidget {
  final Directory? startDirectory;

  const LogFileBrowser({super.key, this.startDirectory});

  @override
  State<LogFileBrowser> createState() => _LogFileBrowserState();
}

class _LogFileBrowserState extends State<LogFileBrowser> {

  Future<void> _shareFile(
      BuildContext context,
      FileSystemEntity file,
      GlobalKey tileKey,
      ) async {
    try {
      Rect? origin;
      final renderObject = tileKey.currentContext?.findRenderObject();
      if (renderObject is RenderBox && renderObject.hasSize) {
        final offset = renderObject.localToGlobal(Offset.zero);
        origin = offset & renderObject.size;
      }

      await Share.shareXFiles(
        [XFile(file.path)],
        subject: file.path.split('/').last,
        sharePositionOrigin: origin,
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Share failed: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    Directory? currentDirectory = widget.startDirectory;

    if (currentDirectory == null) {
      return const Center(child: CircularProgressIndicator());
    }

    var files = currentDirectory.listSync();
    files.sort((a, b) => b.path.compareTo(a.path));

    return Scaffold(
      appBar: AppBar(
        title: Text(currentDirectory.path),
      ),
      body: ListView.builder(
        itemCount: files.length,
        itemBuilder: (context, index) {
          FileSystemEntity file = files[index];
          final tileKey = GlobalKey();
          return ListTile(
            key: tileKey,
            title: Text(file.path.split('/').last),
            onTap: () async {
              if (file is Directory) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => LogFileBrowser(startDirectory: file),
                  ),
                );
              } else {
                await _shareFile(context, file, tileKey);
              }
            },
          );
        },
      ),
    );
  }
}
