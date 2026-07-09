// 照片附件公用组件：选图上传、缩略图网格、全屏大图预览。
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/app_config.dart';
import '../../core/ui.dart';
import '../session/session_controller.dart';

/// 弹出「拍照 / 相册」选择，选图后立即上传，返回文件 id；取消或失败返回 null。
Future<String?> pickAndUploadPhoto(
    BuildContext context, SessionController s) async {
  final source = await showModalBottomSheet<ImageSource>(
    context: context,
    showDragHandle: true,
    builder: (ctx) => SafeArea(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        ListTile(
            leading: const Icon(Icons.photo_camera_outlined, color: rose),
            title: const Text('拍照'),
            onTap: () => Navigator.pop(ctx, ImageSource.camera)),
        ListTile(
            leading: const Icon(Icons.photo_library_outlined, color: sage),
            title: const Text('从相册选择'),
            onTap: () => Navigator.pop(ctx, ImageSource.gallery)),
        const SizedBox(height: 8),
      ]),
    ),
  );
  if (source == null || !context.mounted) return null;
  try {
    final picked = await ImagePicker()
        .pickImage(source: source, maxWidth: 1600, imageQuality: 82);
    if (picked == null) return null;
    final bytes = await picked.readAsBytes();
    final contentType = picked.mimeType ??
        (picked.path.toLowerCase().endsWith('.png')
            ? 'image/png'
            : 'image/jpeg');
    final result =
        await s.api.uploadPhoto(s.spaceId, picked.name, bytes, contentType);
    return result['id']?.toString();
  } catch (e) {
    if (context.mounted) showError(context, e);
    return null;
  }
}

/// 从记录里取出照片 id 列表。
List<String> photoIdsOf(Map record) =>
    List<String>.from(record['photos'] ?? const []);

/// 缩略图网格：点击任意一张进入全屏预览。
class PhotoGrid extends StatelessWidget {
  const PhotoGrid(this.ids, {super.key, this.size = 86});
  final List<String> ids;
  final double size;
  @override
  Widget build(BuildContext context) {
    if (ids.isEmpty) return const SizedBox.shrink();
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (var i = 0; i < ids.length; i++)
          GestureDetector(
            onTap: () => openPhotoViewer(context, ids, i),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.network(photoUrl(ids[i]),
                  width: size,
                  height: size,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                      width: size,
                      height: size,
                      color: const Color(0xfff3ece2),
                      child: const Icon(Icons.broken_image_outlined,
                          color: muted))),
            ),
          ),
      ],
    );
  }
}

void openPhotoViewer(BuildContext context, List<String> ids, int index) {
  Navigator.push(
      context,
      MaterialPageRoute(
          builder: (_) => _PhotoViewerScreen(ids, initialIndex: index)));
}

/// 全屏大图预览：左右滑动切换 + 双指缩放。
class _PhotoViewerScreen extends StatefulWidget {
  const _PhotoViewerScreen(this.ids, {required this.initialIndex});
  final List<String> ids;
  final int initialIndex;
  @override
  State<_PhotoViewerScreen> createState() => _PhotoViewerScreenState();
}

class _PhotoViewerScreenState extends State<_PhotoViewerScreen> {
  late final PageController _controller =
      PageController(initialPage: widget.initialIndex);
  late int _current = widget.initialIndex;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text('${_current + 1} / ${widget.ids.length}',
            style: const TextStyle(fontSize: 15)),
      ),
      body: PageView.builder(
        controller: _controller,
        itemCount: widget.ids.length,
        onPageChanged: (i) => setState(() => _current = i),
        itemBuilder: (_, i) => InteractiveViewer(
          minScale: 1,
          maxScale: 4,
          child: Center(
            child: Image.network(photoUrl(widget.ids[i]),
                fit: BoxFit.contain,
                loadingBuilder: (_, child, progress) => progress == null
                    ? child
                    : const CircularProgressIndicator(color: Colors.white54),
                errorBuilder: (_, __, ___) => const Icon(
                    Icons.broken_image_outlined,
                    color: Colors.white38,
                    size: 48)),
          ),
        ),
      ),
    );
  }
}
