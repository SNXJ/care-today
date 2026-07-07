import 'package:flutter/material.dart';
import '../../core/ui.dart';
import '../session/session_controller.dart';
import 'actions.dart';
import 'forms.dart';

class _ComposerAction {
  const _ComposerAction(this.id, this.label, this.desc, this.icon, this.color);
  final String id, label, desc;
  final IconData icon;
  final Color color;
}

const _blue = Color(0xff5b7c99);

const _actions = [
  _ComposerAction('message', '说说此刻', '发布给家人看', Icons.chat_bubble_outline, rose),
  _ComposerAction('event', '加日程', '复诊、检查、提醒', Icons.event_outlined, rose),
  _ComposerAction(
      'bodyRecord', '记身体状态', '疼痛、睡眠等评分', Icons.favorite_outline, sage),
  _ComposerAction(
      'temperature', '记体温', '测量时间和数值', Icons.thermostat_outlined, rose),
  _ComposerAction(
      'weight', '记体重', '日期和数值', Icons.monitor_weight_outlined, amber),
  _ComposerAction('symptom', '记症状', '症状和发生时间', Icons.healing_outlined, sage),
  _ComposerAction(
      'medication', '记用药', '吃了什么药、何时吃', Icons.medication_outlined, _blue),
  _ComposerAction(
      'notice', '记注意事项', '有效期内置顶', Icons.warning_amber_outlined, amber),
  _ComposerAction('question', '问医生的问题', '复诊前确认', Icons.help_outline, _blue),
  _ComposerAction('note', '存一条资料', '报告、用药、医嘱', Icons.folder_outlined, sage),
];

const _scope = {
  'moments': ['message'],
  'body': ['bodyRecord', 'temperature', 'weight', 'symptom', 'medication'],
  'notices': ['notice'],
};

Future<void> openComposer(
    BuildContext context, SessionController s, String view) async {
  final scope = _scope[view];
  final visible = _actions.where((a) {
    if (scope != null) return scope.contains(a.id);
    return true;
  }).toList();

  final picked = await showModalBottomSheet<String>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => _ComposerSheet(visible),
  );
  if (picked == null || !context.mounted) return;
  switch (picked) {
    case 'message':
      await addMessage(context, s);
    case 'event':
      await addEvent(context, s);
    case 'bodyRecord':
      await openBodyStatusForm(context, s);
    case 'temperature':
      await addTemperature(context, s);
    case 'weight':
      await addWeight(context, s);
    case 'symptom':
      await openSymptomForm(context, s);
    case 'medication':
      await addMedication(context, s);
    case 'notice':
      await addNotice(context, s);
    case 'question':
      await addQuestion(context, s);
    case 'note':
      await addNote(context, s);
  }
}

/// 「+」发布面板：圆角抬头 + 双列彩色动作卡片。
class _ComposerSheet extends StatelessWidget {
  const _ComposerSheet(this.actions);
  final List<_ComposerAction> actions;
  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    return Container(
      constraints: BoxConstraints(maxHeight: media.size.height * 0.85),
      decoration: const BoxDecoration(
        color: Color(0xfffffdf9),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(20, 12, 20, 16 + media.viewPadding.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: const Color(0xffe5d8c8),
                  borderRadius: BorderRadius.circular(4)),
            ),
          ),
          const SizedBox(height: 16),
          const Text('记录点什么',
              style: TextStyle(fontSize: 12, color: muted, letterSpacing: 2)),
          const SizedBox(height: 4),
          const Text('现在想记下哪件事？',
              style: TextStyle(
                  fontFamily: 'Songti SC',
                  fontSize: 22,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Flexible(
            child: SingleChildScrollView(
              child: LayoutBuilder(builder: (context, c) {
                const gap = 12.0;
                final w = (c.maxWidth - gap) / 2;
                return Wrap(
                  spacing: gap,
                  runSpacing: gap,
                  children: actions
                      .map((a) => SizedBox(
                          width: w,
                          child: _ComposerTile(
                              a, () => Navigator.pop(context, a.id))))
                      .toList(),
                );
              }),
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('取消')),
          ),
        ],
      ),
    );
  }
}

class _ComposerTile extends StatelessWidget {
  const _ComposerTile(this.action, this.onTap);
  final _ComposerAction action;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return Material(
      color: action.color.withValues(alpha: 0.07),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: action.color.withValues(alpha: 0.22))),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                    color: action.color.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(12)),
                child: Icon(action.icon, color: action.color, size: 20),
              ),
              const SizedBox(height: 10),
              Text(action.label,
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 15)),
              const SizedBox(height: 2),
              Text(action.desc,
                  style: const TextStyle(color: muted, fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }
}

/// 通用「管理」底部弹窗：标题 + 信息行 + 一组操作按钮。
class ManageLine {
  const ManageLine(this.label, this.value);
  final String label, value;
}

class ManageAction {
  const ManageAction(this.label, this.run, {this.danger = false});
  final String label;
  final Future<void> Function() run;
  final bool danger;
}

Future<void> showManageSheet(BuildContext context,
    {required String eyebrow,
    required String title,
    required List<ManageLine> lines,
    required List<ManageAction> actions}) async {
  final action = await showModalBottomSheet<ManageAction>(
    context: context,
    showDragHandle: true,
    builder: (_) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(eyebrow,
                style: const TextStyle(
                    fontSize: 12, color: muted, letterSpacing: 1)),
            const SizedBox(height: 4),
            Text(title,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            ...lines.map((l) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                          width: 72,
                          child: Text(l.label,
                              style:
                                  const TextStyle(color: muted, fontSize: 13))),
                      Expanded(
                          child: Text(l.value,
                              style: const TextStyle(height: 1.5))),
                    ],
                  ),
                )),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: actions
                  .map((a) => a.danger
                      ? OutlinedButton(
                          style:
                              OutlinedButton.styleFrom(foregroundColor: rose),
                          onPressed: () => Navigator.pop(context, a),
                          child: Text(a.label))
                      : FilledButton.tonal(
                          onPressed: () => Navigator.pop(context, a),
                          child: Text(a.label)))
                  .toList(),
            ),
          ],
        ),
      ),
    ),
  );
  if (action != null) await action.run();
}
