import 'package:flutter/material.dart';

const rose = Color(0xffb85f55);
const sage = Color(0xff78927c);
const amber = Color(0xffc8893f);
const ink = Color(0xff2e2a27);
const muted = Color(0xff766b62);

void showToast(BuildContext context, String text) {
  ScaffoldMessenger.of(context)
    ..clearSnackBars()
    ..showSnackBar(SnackBar(
        content: Text(text),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(milliseconds: 1900)));
}

void showError(BuildContext context, Object error) =>
    showToast(context, error.toString());

/// 表单字段类型，对齐 Web 端 openFormDialog 的 field.type。
enum FieldType { text, textarea, number, date, datetime, checkbox, photos }

class FieldSpec {
  FieldSpec(this.name, this.label,
      {this.type = FieldType.text,
      this.value,
      this.required = false,
      this.placeholder = '',
      this.readonly = false,
      this.uploader,
      this.thumbUrl});
  final String name;
  final String label;
  final FieldType type;
  final dynamic value;
  final bool required;
  final String placeholder;
  final bool readonly;

  /// photos 类型：点「+」时调用，完成选图并上传，返回文件 id（取消返回 null）。
  final Future<String?> Function()? uploader;

  /// photos 类型：由文件 id 生成缩略图地址。
  final String Function(String id)? thumbUrl;
}

/// 弹出确认框，返回 true=确认。
Future<bool> showConfirm(BuildContext context,
    {required String eyebrow,
    required String title,
    String message = '',
    String confirmText = '确认',
    String cancelText = '取消',
    bool danger = false}) async {
  final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
            title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(eyebrow,
                      style: const TextStyle(
                          fontSize: 12, color: muted, letterSpacing: 1)),
                  const SizedBox(height: 6),
                  Text(title, style: const TextStyle(fontSize: 19)),
                ]),
            content: message.isEmpty
                ? null
                : Text(message, style: const TextStyle(height: 1.6)),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: Text(cancelText)),
              FilledButton(
                  style: FilledButton.styleFrom(
                      backgroundColor: danger ? rose : sage),
                  onPressed: () => Navigator.pop(ctx, true),
                  child: Text(confirmText)),
            ],
          ));
  return result ?? false;
}

/// 弹出表单，返回填写值 Map；取消返回 null。
Future<Map<String, dynamic>?> showForm(BuildContext context,
    {required String eyebrow,
    required String title,
    String message = '',
    required List<FieldSpec> fields,
    String confirmText = '保存',
    String cancelText = '取消'}) {
  return showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => _FormDialog(
            eyebrow: eyebrow,
            title: title,
            message: message,
            fields: fields,
            confirmText: confirmText,
            cancelText: cancelText,
          ));
}

class _FormDialog extends StatefulWidget {
  const _FormDialog({
    required this.eyebrow,
    required this.title,
    required this.message,
    required this.fields,
    required this.confirmText,
    required this.cancelText,
  });
  final String eyebrow, title, message, confirmText, cancelText;
  final List<FieldSpec> fields;
  @override
  State<_FormDialog> createState() => _FormDialogState();
}

class _FormDialogState extends State<_FormDialog> {
  final _controllers = <String, TextEditingController>{};
  final _bools = <String, bool>{};
  final _dates = <String, DateTime?>{};
  final _photos = <String, List<String>>{};
  bool _uploading = false;

  @override
  void initState() {
    super.initState();
    for (final f in widget.fields) {
      switch (f.type) {
        case FieldType.checkbox:
          _bools[f.name] = f.value == true;
        case FieldType.date:
        case FieldType.datetime:
          _dates[f.name] = f.value is DateTime ? f.value as DateTime : null;
        case FieldType.photos:
          _photos[f.name] =
              List<String>.from(f.value as List? ?? const <String>[]);
        default:
          _controllers[f.name] =
              TextEditingController(text: f.value?.toString() ?? '');
      }
    }
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  String _dateLabel(DateTime? d, bool withTime) {
    if (d == null) return '未选择';
    final base = '${d.year}年${d.month}月${d.day}日';
    if (!withTime) return base;
    return '$base ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _pickDate(FieldSpec f) async {
    final now = DateTime.now();
    final base = _dates[f.name] ?? now;
    final date = await showDatePicker(
        context: context,
        initialDate: base,
        firstDate: DateTime(now.year - 3),
        lastDate: DateTime(now.year + 3));
    if (date == null) return;
    if (f.type == FieldType.date) {
      setState(
          () => _dates[f.name] = DateTime(date.year, date.month, date.day));
      return;
    }
    if (!mounted) return;
    final time = await showTimePicker(
        context: context, initialTime: TimeOfDay.fromDateTime(base));
    setState(() => _dates[f.name] = DateTime(date.year, date.month, date.day,
        time?.hour ?? base.hour, time?.minute ?? base.minute));
  }

  void _submit() {
    final values = <String, dynamic>{};
    for (final f in widget.fields) {
      switch (f.type) {
        case FieldType.checkbox:
          values[f.name] = _bools[f.name];
        case FieldType.date:
        case FieldType.datetime:
          values[f.name] = _dates[f.name];
        case FieldType.photos:
          values[f.name] = _photos[f.name];
        default:
          values[f.name] = _controllers[f.name]!.text.trim();
      }
      if (f.required) {
        final v = values[f.name];
        final empty = v == null || (v is String && v.isEmpty);
        if (empty) {
          showToast(context, '请填写${f.label}');
          return;
        }
      }
    }
    Navigator.pop(context, values);
  }

  Future<void> _addPhoto(FieldSpec f) async {
    if (f.uploader == null || _uploading) return;
    setState(() => _uploading = true);
    try {
      final id = await f.uploader!();
      if (id != null && mounted) {
        setState(() => _photos[f.name] = [..._photos[f.name]!, id]);
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Widget _buildField(FieldSpec f) {
    switch (f.type) {
      case FieldType.photos:
        final ids = _photos[f.name]!;
        const side = 64.0;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: InputDecorator(
            decoration: InputDecoration(
                labelText: f.label, border: const OutlineInputBorder()),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (var i = 0; i < ids.length; i++)
                  Stack(clipBehavior: Clip.none, children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: f.thumbUrl == null
                          ? Container(
                              width: side,
                              height: side,
                              color: const Color(0xfff3ece2))
                          : Image.network(f.thumbUrl!(ids[i]),
                              width: side, height: side, fit: BoxFit.cover),
                    ),
                    Positioned(
                      top: -7,
                      right: -7,
                      child: GestureDetector(
                        onTap: () => setState(() => _photos[f.name] =
                            [...ids]..removeAt(i)),
                        child: Container(
                          decoration: const BoxDecoration(
                              color: rose, shape: BoxShape.circle),
                          padding: const EdgeInsets.all(2),
                          child: const Icon(Icons.close,
                              size: 13, color: Colors.white),
                        ),
                      ),
                    ),
                  ]),
                InkWell(
                  onTap: () => _addPhoto(f),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    width: side,
                    height: side,
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xffeadbca)),
                        color: const Color(0xfffefbf6)),
                    child: _uploading
                        ? const Padding(
                            padding: EdgeInsets.all(20),
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.add_a_photo_outlined,
                            color: muted, size: 22),
                  ),
                ),
              ],
            ),
          ),
        );
      case FieldType.checkbox:
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: _bools[f.name] ?? false,
            onChanged: (v) => setState(() => _bools[f.name] = v),
            title: Text(f.label),
          ),
        );
      case FieldType.date:
      case FieldType.datetime:
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: InkWell(
            onTap: () => _pickDate(f),
            child: InputDecorator(
              decoration: InputDecoration(
                  labelText: f.label, border: const OutlineInputBorder()),
              child: Text(
                  _dateLabel(_dates[f.name], f.type == FieldType.datetime)),
            ),
          ),
        );
      default:
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: TextField(
            controller: _controllers[f.name],
            readOnly: f.readonly,
            maxLines: f.type == FieldType.textarea ? 3 : 1,
            keyboardType: f.type == FieldType.number
                ? const TextInputType.numberWithOptions(decimal: true)
                : null,
            decoration: InputDecoration(
                labelText: f.label,
                hintText: f.placeholder.isEmpty ? null : f.placeholder,
                border: const OutlineInputBorder()),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      scrollable: true,
      title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(widget.eyebrow,
                style: const TextStyle(
                    fontSize: 12, color: muted, letterSpacing: 1)),
            const SizedBox(height: 6),
            Text(widget.title, style: const TextStyle(fontSize: 19)),
          ]),
      content: SizedBox(
        width: 420,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.message.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(widget.message,
                    style: const TextStyle(color: muted, height: 1.6)),
              ),
            ...widget.fields.map(_buildField),
          ],
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(widget.cancelText)),
        FilledButton(
            style: FilledButton.styleFrom(backgroundColor: sage),
            onPressed: _submit,
            child: Text(widget.confirmText)),
      ],
    );
  }
}

/// 通用卡片容器，统一视觉。
class SectionCard extends StatelessWidget {
  const SectionCard(
      {super.key,
      required this.title,
      this.tag,
      required this.child,
      this.icon});
  final String title;
  final String? tag;
  final Widget child;
  final IconData? icon;
  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 18, color: rose),
                    const SizedBox(width: 8),
                  ],
                  Expanded(
                      child: Text(title,
                          style: const TextStyle(
                              fontSize: 17, fontWeight: FontWeight.w700))),
                  if (tag != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                          color: const Color(0xfff3ece2),
                          borderRadius: BorderRadius.circular(20)),
                      child: Text(tag!,
                          style: const TextStyle(fontSize: 12, color: muted)),
                    ),
                ],
              ),
              const SizedBox(height: 14),
              child,
            ],
          ),
        ),
      );
}

Widget emptyNote(String text) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 18),
      child: Text(text,
          style: const TextStyle(color: muted, height: 1.6),
          textAlign: TextAlign.center),
    );
