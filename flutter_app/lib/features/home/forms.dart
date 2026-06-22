import 'package:flutter/material.dart';
import '../../core/format.dart';
import '../../core/ui.dart';
import '../session/session_controller.dart';

const scoreFields = {
  '疼痛': 'painScore',
  '乏力': 'fatigueScore',
  '睡眠': 'sleepScore',
  '心情': 'moodScore',
  '食欲': 'appetiteScore',
};

/// 今日身体评分（5 项 0-10 + 一句感受），对齐 Web 的 bodyForm。
Future<void> openBodyStatusForm(
    BuildContext context, SessionController s) async {
  final saved = await showDialog<bool>(
      context: context, builder: (_) => _BodyStatusDialog(s));
  if (saved == true && context.mounted) {
    showToast(context, '今天的身体状态已记录');
  }
}

class _BodyStatusDialog extends StatefulWidget {
  const _BodyStatusDialog(this.s);
  final SessionController s;
  @override
  State<_BodyStatusDialog> createState() => _BodyStatusDialogState();
}

class _BodyStatusDialogState extends State<_BodyStatusDialog> {
  late final Map<String, double> scores;
  final note = TextEditingController();
  bool saving = false;

  @override
  void initState() {
    super.initState();
    // 取每项最近一次非空评分作为初值。
    num latest(String field) {
      for (final r in widget.s.body) {
        final v = r[field];
        if (v != null && v != '') return v as num;
      }
      return 5;
    }

    scores = {
      for (final e in scoreFields.entries) e.key: latest(e.value).toDouble()
    };
  }

  @override
  void dispose() {
    note.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => saving = true);
    try {
      await widget.s.api.request('/spaces/${widget.s.spaceId}/body-records',
          method: 'POST',
          body: {
            for (final e in scoreFields.entries)
              e.value: scores[e.key]!.round(),
            'note': note.text.trim(),
            'recordDate': todayKey(),
          });
      await widget.s.reloadBody();
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        setState(() => saving = false);
        showError(context, e);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      scrollable: true,
      title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('每天一条',
                style: TextStyle(fontSize: 12, color: muted, letterSpacing: 1)),
            SizedBox(height: 6),
            Text('今天身体怎么样？', style: TextStyle(fontSize: 19)),
          ]),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('体温和体重在「+」里有单独入口，这里只记评分和感受。',
                style: TextStyle(color: muted, height: 1.5, fontSize: 13)),
            const SizedBox(height: 8),
            ...scoreFields.keys.map((label) => Row(children: [
                  SizedBox(width: 40, child: Text(label)),
                  Expanded(
                      child: Slider(
                          value: scores[label]!,
                          min: 0,
                          max: 10,
                          divisions: 10,
                          label: scores[label]!.round().toString(),
                          onChanged: (v) => setState(() => scores[label] = v))),
                  SizedBox(
                      width: 34,
                      child: Text('${scores[label]!.round()}/10',
                          style: const TextStyle(fontSize: 12))),
                ])),
            const SizedBox(height: 8),
            TextField(
                controller: note,
                decoration: const InputDecoration(
                    labelText: '补一句感受（可不填）',
                    hintText: '例如：下午有点恶心，晚饭吃得少',
                    border: OutlineInputBorder())),
          ],
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context), child: const Text('取消')),
        FilledButton(
            onPressed: saving ? null : _save, child: const Text('保存今天的状态')),
      ],
    );
  }
}

const symptomPresets = ['大便', '腹泻', '发烧', '乏力', '疼痛', '手脚发麻'];

/// 记一次症状（预设标签 + 自定义 + 时间 + 备注），对齐 Web 的 symptomForm。
Future<void> openSymptomForm(BuildContext context, SessionController s) async {
  final tag = await showDialog<String>(
      context: context, builder: (_) => _SymptomDialog(s));
  if (tag != null && context.mounted) showToast(context, '已记下：$tag');
}

class _SymptomDialog extends StatefulWidget {
  const _SymptomDialog(this.s);
  final SessionController s;
  @override
  State<_SymptomDialog> createState() => _SymptomDialogState();
}

class _SymptomDialogState extends State<_SymptomDialog> {
  String selected = '';
  bool custom = false;
  final customTag = TextEditingController();
  final note = TextEditingController();
  DateTime happenedAt = DateTime.now();
  bool saving = false;

  @override
  void dispose() {
    customTag.dispose();
    note.dispose();
    super.dispose();
  }

  Future<void> _pickTime() async {
    final date = await showDatePicker(
        context: context,
        initialDate: happenedAt,
        firstDate: DateTime(happenedAt.year - 1),
        lastDate: DateTime(happenedAt.year + 1));
    if (date == null || !mounted) return;
    final time = await showTimePicker(
        context: context, initialTime: TimeOfDay.fromDateTime(happenedAt));
    setState(() => happenedAt = DateTime(date.year, date.month, date.day,
        time?.hour ?? happenedAt.hour, time?.minute ?? happenedAt.minute));
  }

  Future<void> _save() async {
    final tag = (custom ? customTag.text : selected).trim();
    if (tag.isEmpty) {
      showToast(context, '先选一个症状标签，或自己写一个');
      return;
    }
    setState(() => saving = true);
    try {
      await widget.s.api.request('/spaces/${widget.s.spaceId}/symptoms',
          method: 'POST',
          body: {
            'tag': tag,
            'happenedAt': happenedAt.toUtc().toIso8601String(),
            'note': note.text.trim().isEmpty ? null : note.text.trim(),
          });
      await widget.s.reloadSymptoms();
      if (mounted) Navigator.pop(context, tag);
    } catch (e) {
      if (mounted) {
        setState(() => saving = false);
        showError(context, e);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final chips = [...symptomPresets, '自定义…'];
    return AlertDialog(
      scrollable: true,
      title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('什么时间发生了什么',
                style: TextStyle(fontSize: 12, color: muted, letterSpacing: 1)),
            SizedBox(height: 6),
            Text('记一次症状', style: TextStyle(fontSize: 19)),
          ]),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: chips.map((c) {
                final isCustom = c == '自定义…';
                final active = isCustom ? custom : (!custom && selected == c);
                return ChoiceChip(
                  label: Text(c),
                  selected: active,
                  onSelected: (_) => setState(() {
                    if (isCustom) {
                      custom = true;
                      selected = '';
                    } else {
                      custom = false;
                      selected = c;
                    }
                  }),
                );
              }).toList(),
            ),
            if (custom) ...[
              const SizedBox(height: 10),
              TextField(
                  controller: customTag,
                  decoration: const InputDecoration(
                      labelText: '自己写一个',
                      hintText: '例如：头晕',
                      border: OutlineInputBorder())),
            ],
            const SizedBox(height: 12),
            InkWell(
              onTap: _pickTime,
              child: InputDecorator(
                decoration: const InputDecoration(
                    labelText: '发生时间', border: OutlineInputBorder()),
                child: Text(formatFullDateTime(happenedAt)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
                controller: note,
                decoration: const InputDecoration(
                    labelText: '补充说明（可不填）',
                    hintText: '例如：38.2 度，吃了退烧药',
                    border: OutlineInputBorder())),
          ],
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context), child: const Text('取消')),
        FilledButton(
            onPressed: saving ? null : _save, child: const Text('记下来')),
      ],
    );
  }
}
