import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../common/app_strings.dart';
import '../../common/platform/log_share.dart';

class LogUploadView extends StatefulWidget {
  const LogUploadView({super.key});
  @override
  State<LogUploadView> createState() => _LogUploadViewState();
}

class _LogUploadViewState extends State<LogUploadView> {
  List<Map<String, String>> _files = [];
  int _selected = 0;
  bool _loading = true;
  bool _sharing = false;
  String? _error;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final files = await LogShare.files();
      if (mounted) setState(() => _files = files);
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _share() async {
    if (_files.isEmpty || _sharing) return;
    setState(() => _sharing = true);
    try {
      await LogShare.share(_files[_selected]['path']!);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  @override
  Widget build(BuildContext context) => SizedBox(
    height: MediaQuery.sizeOf(context).height / 2,
    child: SafeArea(
      top: false,
      child: Column(
        children: [
          SizedBox(
            height: 44,
            child: Row(
              children: [
                TextButton(onPressed: () => Navigator.pop(context), child: Text(AppStrings.of(context, 'cancel'))),
                Expanded(
                  child: Text(
                    AppStrings.of(context, 'shareLog'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                ),
                TextButton(
                  onPressed: _loading || _sharing || _files.isEmpty ? null : _share,
                  child: Text(AppStrings.of(context, 'share')),
                ),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _files.isEmpty || _error != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Text(_error ?? AppStrings.of(context, 'noLogs')),
                    ),
                  )
                : CupertinoPicker(
                    itemExtent: 36,
                    onSelectedItemChanged: (index) => _selected = index,
                    children: [
                      for (final file in _files)
                        Center(
                          child: Text(
                            file['name']!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 18),
                          ),
                        ),
                    ],
                  ),
          ),
        ],
      ),
    ),
  );
}
