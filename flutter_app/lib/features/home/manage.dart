import 'package:flutter/material.dart';
import '../../core/format.dart';
import '../session/session_controller.dart';
import 'actions.dart';
import 'composer.dart';

String noticeRangeLabel(Map n) {
  final start = (n['startsOn'] ?? '').toString();
  final end = (n['endsOn'] ?? '').toString();
  if (start.isNotEmpty && end.isNotEmpty) return '$start 至 $end';
  if (start.isNotEmpty) return '$start 起生效';
  if (end.isNotEmpty) return '$end 前有效';
  return '长期有效';
}

/// 注意事项是否当前生效（未归档且在有效期内）。
bool noticeActive(Map n) {
  if (n['status'] == 'ARCHIVED') return false;
  final today = todayKey();
  final start = (n['startsOn'] ?? '').toString();
  final end = (n['endsOn'] ?? '').toString();
  if (start.isNotEmpty && start.compareTo(today) > 0) return false;
  if (end.isNotEmpty && end.compareTo(today) < 0) return false;
  return true;
}

Future<void> manageNotice(BuildContext context, SessionController s, Map n) {
  final archived = n['status'] == 'ARCHIVED';
  final important = n['important'] == true;
  return showManageSheet(context,
      eyebrow: '注意事项',
      title: n['content']?.toString() ?? '',
      lines: [
        ManageLine('生效期', noticeRangeLabel(n)),
        ManageLine('补充说明', (n['detail'] ?? '没有补充说明').toString()),
        ManageLine('状态', archived ? '已归档' : '生效中'),
      ],
      actions: [
        ManageAction(important ? '取消重要' : '设为重要',
            () => toggleNoticeImportant(context, s, n)),
        ManageAction('编辑', () => editNotice(context, s, n)),
        ManageAction(
            archived ? '恢复' : '归档', () => archiveNotice(context, s, n)),
        ManageAction('删除', () => deleteNotice(context, s, n), danger: true),
      ]);
}

Future<void> manageMessage(BuildContext context, SessionController s, Map m) {
  return showManageSheet(context,
      eyebrow: '分享',
      title: m['text']?.toString() ?? '',
      lines: [
        ManageLine('来自', (m['author'] ?? '家人').toString()),
        ManageLine('时间', formatFullDateTime(m['createdAt'])),
      ],
      actions: [
        ManageAction('编辑', () => editMessage(context, s, m)),
        ManageAction('删除', () => deleteMessage(context, s, m), danger: true),
      ]);
}

Future<void> manageSymptom(BuildContext context, SessionController s, Map sy) {
  return showManageSheet(context,
      eyebrow: '症状记录',
      title: sy['tag']?.toString() ?? '',
      lines: [
        ManageLine('发生时间', formatMonthDayTime(sy['happenedAt'])),
        ManageLine('补充说明', (sy['note'] ?? '没有补充说明').toString()),
      ],
      actions: [
        ManageAction('编辑', () => editSymptom(context, s, sy)),
        ManageAction('删除', () => deleteSymptom(context, s, sy), danger: true),
      ]);
}
