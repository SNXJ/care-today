import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:open_filex/open_filex.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/app_config.dart';
import '../../core/ui.dart';

/// 公开的版本检查接口（无需登录）。
const _versionUrl = '$careApiBase/app/version';

/// 非 Android 平台兜底跳转地址（应用商店或下载页）。
const _fallbackUrl = '$careOrigin/apk/';

class UpdateInfo {
  UpdateInfo({
    required this.versionCode,
    required this.versionName,
    required this.notes,
    required this.apkUrl,
    required this.forceUpdate,
    required this.fileSize,
  });
  final int versionCode;
  final String versionName;
  final String notes;
  final String apkUrl;
  final bool forceUpdate;
  final int fileSize;

  factory UpdateInfo.fromJson(Map<String, dynamic> json) => UpdateInfo(
        versionCode: (json['versionCode'] as num?)?.toInt() ?? 0,
        versionName: json['versionName']?.toString() ?? '',
        notes: json['notes']?.toString() ?? '',
        apkUrl: json['apkUrl']?.toString() ?? '',
        forceUpdate: json['forceUpdate'] == true,
        fileSize: (json['fileSize'] as num?)?.toInt() ?? 0,
      );
}

/// 拉取最新版本；若比当前安装版本新则返回，否则返回 null。
Future<UpdateInfo?> fetchUpdate() async {
  final res = await http
      .get(Uri.parse(_versionUrl))
      .timeout(const Duration(seconds: 8));
  if (res.statusCode == 204 || res.bodyBytes.isEmpty) return null;
  if (res.statusCode != 200) return null;
  final data = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
  final info = UpdateInfo.fromJson(data);
  final pkg = await PackageInfo.fromPlatform();
  final current = int.tryParse(pkg.buildNumber) ?? 0;
  return info.versionCode > current ? info : null;
}

/// 检查更新并按需弹窗。silent=true 时无更新/出错都不打扰用户（用于启动自动检查）。
Future<void> checkForUpdate(BuildContext context, {bool silent = true}) async {
  UpdateInfo? info;
  try {
    info = await fetchUpdate();
  } catch (e) {
    if (!silent && context.mounted) showError(context, e);
    return;
  }
  if (info == null) {
    if (!silent && context.mounted) showToast(context, '已经是最新版本');
    return;
  }
  if (!context.mounted) return;
  await showDialog(
    context: context,
    barrierDismissible: !info.forceUpdate,
    builder: (_) => UpdateDialog(info!),
  );
}

class UpdateDialog extends StatefulWidget {
  const UpdateDialog(this.info, {super.key});
  final UpdateInfo info;
  @override
  State<UpdateDialog> createState() => _UpdateDialogState();
}

class _UpdateDialogState extends State<UpdateDialog> {
  double? progress; // null=未开始，0..1=下载中
  bool done = false;

  Future<void> _start() async {
    if (!Platform.isAndroid) {
      final uri = Uri.parse(
          widget.info.apkUrl.isNotEmpty ? widget.info.apkUrl : _fallbackUrl);
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      return;
    }
    setState(() => progress = 0);
    try {
      final dir =
          await getExternalStorageDirectory() ?? await getTemporaryDirectory();
      final path = '${dir.path}/care-today-${widget.info.versionCode}.apk';
      final req = http.Request('GET', Uri.parse(widget.info.apkUrl));
      final resp = await http.Client().send(req);
      final total = resp.contentLength ?? widget.info.fileSize;
      final sink = File(path).openWrite();
      var received = 0;
      await for (final chunk in resp.stream) {
        sink.add(chunk);
        received += chunk.length;
        if (total > 0 && mounted) {
          setState(() => progress = received / total);
        }
      }
      await sink.close();
      if (mounted) setState(() => done = true);
      await OpenFilex.open(path);
    } catch (e) {
      if (mounted) {
        setState(() => progress = null);
        showError(context, e);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final info = widget.info;
    final downloading = progress != null && !done;
    return PopScope(
      canPop: !info.forceUpdate,
      child: AlertDialog(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('发现新版本',
                style: TextStyle(fontSize: 12, color: muted, letterSpacing: 1)),
            const SizedBox(height: 6),
            Text('v${info.versionName}', style: const TextStyle(fontSize: 20)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (info.notes.isNotEmpty)
              Text(info.notes, style: const TextStyle(height: 1.6)),
            if (info.forceUpdate)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text('这是一次必须更新，完成后才能继续使用。',
                    style: TextStyle(color: rose, fontSize: 13)),
              ),
            if (downloading) ...[
              const SizedBox(height: 16),
              LinearProgressIndicator(value: progress),
              const SizedBox(height: 6),
              Text('正在下载 ${((progress ?? 0) * 100).toStringAsFixed(0)}%',
                  style: const TextStyle(color: muted, fontSize: 12)),
            ],
          ],
        ),
        actions: downloading
            ? const [Text('下载中…', style: TextStyle(color: muted))]
            : [
                if (!info.forceUpdate)
                  TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('以后再说')),
                FilledButton(
                    onPressed: _start,
                    child: Text(Platform.isAndroid ? '立即更新' : '前往更新')),
              ],
      ),
    );
  }
}
