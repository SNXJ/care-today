import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/format.dart';
import '../../core/ui.dart';
import '../session/session_controller.dart';
import 'actions.dart';

Future<void> openQuestionsPanel(BuildContext context) =>
    showDialog(context: context, builder: (_) => const _QuestionsPanel());

class _QuestionsPanel extends StatelessWidget {
  const _QuestionsPanel();
  @override
  Widget build(BuildContext context) {
    final s = context.watch<SessionController>();
    final questions = s.questions;
    return AlertDialog(
      scrollable: true,
      title: const Text('问医生清单', style: TextStyle(fontSize: 19)),
      content: SizedBox(
        width: 440,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('复诊前勾选。把担心的事先记下来，复诊时不怕忘。',
                style: TextStyle(color: muted, fontSize: 13)),
            const SizedBox(height: 8),
            if (questions.isEmpty)
              emptyNote('还没有问题。')
            else
              ...questions.map((q) {
                final done = q['asked'] == true;
                final important = q['important'] == true;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Checkbox(
                          value: done,
                          onChanged: (_) => toggleQuestionAsked(context, s, q)),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(q['question']?.toString() ?? '',
                                style: TextStyle(
                                    decoration: done
                                        ? TextDecoration.lineThrough
                                        : null,
                                    fontWeight: FontWeight.w600)),
                            if ((q['doctorAnswer'] ?? '').toString().isNotEmpty)
                              Text('医生答复：${q['doctorAnswer']}',
                                  style: const TextStyle(
                                      fontSize: 12, color: muted)),
                          ],
                        ),
                      ),
                      _iconAction(
                          important ? Icons.star : Icons.star_border,
                          important ? amber : muted,
                          () => toggleQuestionImportant(context, s, q)),
                      _iconAction(Icons.edit_outlined, muted,
                          () => editQuestion(context, s, q)),
                      _iconAction(Icons.delete_outline, rose,
                          () => deleteQuestion(context, s, q)),
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => addQuestion(context, s),
            child: const Text('添加问题')),
        FilledButton(
            onPressed: () => Navigator.pop(context), child: const Text('关闭')),
      ],
    );
  }
}

Future<void> openFolderPanel(BuildContext context) =>
    showDialog(context: context, builder: (_) => const _FolderPanel());

class _FolderPanel extends StatelessWidget {
  const _FolderPanel();
  @override
  Widget build(BuildContext context) {
    final s = context.watch<SessionController>();
    final notes = s.notes;
    return AlertDialog(
      scrollable: true,
      title: const Text('复诊资料夹', style: TextStyle(fontSize: 19)),
      content: SizedBox(
        width: 440,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('报告名称、用药记录和医嘱备注都可以存在这里。',
                style: TextStyle(color: muted, fontSize: 13)),
            const SizedBox(height: 8),
            if (notes.isEmpty)
              emptyNote('还没有资料。')
            else
              ...notes.map((n) => Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: const Icon(Icons.folder_outlined, color: sage),
                      title: Text(n['title']?.toString() ?? '',
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text(
                          '${n['type'] ?? '文本资料'} · ${formatTimelineDate(n['createdAt'])}'),
                      trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                        _iconAction(Icons.edit_outlined, muted,
                            () => editNote(context, s, n)),
                        _iconAction(Icons.delete_outline, rose,
                            () => deleteNote(context, s, n)),
                      ]),
                    ),
                  )),
          ],
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => addNote(context, s), child: const Text('新增资料')),
        FilledButton(
            onPressed: () => Navigator.pop(context), child: const Text('关闭')),
      ],
    );
  }
}

Widget _iconAction(IconData icon, Color color, VoidCallback onTap) =>
    IconButton(
        visualDensity: VisualDensity.compact,
        iconSize: 20,
        color: color,
        onPressed: onTap,
        icon: Icon(icon));
