// 对话框关闭后继续使用 context 时，下游 _guard / showToast 均已用 context.mounted 守卫。
// ignore_for_file: use_build_context_synchronously
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/app_config.dart';
import '../../core/format.dart';
import '../../core/ui.dart';
import '../session/session_controller.dart';

/// 统一的异常包裹：捕获错误并 toast。
Future<void> _guard(
    BuildContext context, Future<void> Function() action) async {
  try {
    await action();
  } catch (e) {
    if (context.mounted) showError(context, e);
  }
}

String? _dateOnly(dynamic v) => v is DateTime ? dateKey(v) : v?.toString();
String? _iso(dynamic v) =>
    v is DateTime ? v.toUtc().toIso8601String() : v?.toString();

// ——————————————————— 日程 ———————————————————
Future<void> addEvent(BuildContext context, SessionController s) async {
  final values = await showForm(context,
      eyebrow: '加日程',
      title: '添加一条日程',
      message: '复诊、检查、取报告、用药提醒都可以记在这里。',
      confirmText: '添加日程',
      fields: [
        FieldSpec('title', '日程标题', required: true, placeholder: '例如：门诊复查'),
        FieldSpec('scheduledAt', '时间',
            type: FieldType.datetime, value: DateTime.now(), required: true),
        FieldSpec('location', '地点'),
        FieldSpec('note', '备注',
            type: FieldType.textarea, placeholder: '例如：带上报告和问题清单'),
        FieldSpec('needsCompanion', '需要陪同', type: FieldType.checkbox),
      ]);
  if (values == null) return;
  await _guard(context, () async {
    await s.api.request('/spaces/${s.spaceId}/events', method: 'POST', body: {
      'title': values['title'],
      'scheduledAt': _iso(values['scheduledAt']),
      'location': values['location'],
      'note': values['note'],
      'needsCompanion': values['needsCompanion'] == true,
    });
    await s.reloadEvents();
    if (context.mounted) showToast(context, '日程已添加');
  });
}

Future<void> editEvent(BuildContext context, SessionController s, Map e) async {
  final values =
      await showForm(context, eyebrow: '日程安排', title: '编辑日程', fields: [
    FieldSpec('title', '日程标题', value: e['title'], required: true),
    FieldSpec('scheduledAt', '时间',
        type: FieldType.datetime,
        value: tryParse(e['scheduledAt']),
        required: true),
    FieldSpec('location', '地点', value: e['location'] ?? ''),
    FieldSpec('note', '备注', type: FieldType.textarea, value: e['note'] ?? ''),
    FieldSpec('needsCompanion', '需要陪同',
        type: FieldType.checkbox, value: e['needsCompanion'] == true),
  ]);
  if (values == null) return;
  await _guard(context, () async {
    await s.api.request('/spaces/${s.spaceId}/events/${e['id']}',
        method: 'PATCH',
        body: {
          'title': values['title'],
          'scheduledAt': _iso(values['scheduledAt']),
          'location': values['location'],
          'note': values['note'],
          'needsCompanion': values['needsCompanion'] == true,
        });
    await s.reloadEvents();
    if (context.mounted) showToast(context, '日程已更新');
  });
}

Future<void> deleteEvent(
    BuildContext context, SessionController s, Map e) async {
  final ok = await showConfirm(context,
      eyebrow: '删除日程',
      title: '删除日程“${e['title']}”？',
      message: '删除后时间线和今天中不会再显示这条安排。',
      confirmText: '删除',
      danger: true);
  if (!ok) return;
  await _guard(context, () async {
    await s.api
        .request('/spaces/${s.spaceId}/events/${e['id']}', method: 'DELETE');
    await s.reloadEvents();
    if (context.mounted) showToast(context, '日程已删除');
  });
}

// ——————————————————— 问医生 ———————————————————
Future<void> addQuestion(BuildContext context, SessionController s) async {
  final values = await showForm(context,
      eyebrow: '问医生',
      title: '添加一个想问医生的问题',
      confirmText: '加入清单',
      fields: [
        FieldSpec('text', '问题', type: FieldType.textarea, required: true)
      ]);
  if (values == null) return;
  await _guard(context, () async {
    await s.api.request('/spaces/${s.spaceId}/doctor-questions',
        method: 'POST', body: {'question': values['text'], 'important': false});
    await s.reloadQuestions();
    if (context.mounted) showToast(context, '已加入问医生清单');
  });
}

Future<void> editQuestion(
    BuildContext context, SessionController s, Map q) async {
  final values =
      await showForm(context, eyebrow: '问医生', title: '编辑问题', fields: [
    FieldSpec('text', '问题',
        type: FieldType.textarea, value: q['question'], required: true),
    FieldSpec('answer', '医生答复',
        type: FieldType.textarea, value: q['doctorAnswer'] ?? ''),
  ]);
  if (values == null) return;
  await _guard(context, () async {
    await s.api.request('/spaces/${s.spaceId}/doctor-questions/${q['id']}',
        method: 'PATCH',
        body: {'question': values['text'], 'doctorAnswer': values['answer']});
    await s.reloadQuestions();
    if (context.mounted) showToast(context, '问题已更新');
  });
}

Future<void> deleteQuestion(
    BuildContext context, SessionController s, Map q) async {
  final ok = await showConfirm(context,
      eyebrow: '删除问题',
      title: '删除这个问题？',
      message: q['question']?.toString() ?? '',
      confirmText: '删除',
      danger: true);
  if (!ok) return;
  await _guard(context, () async {
    await s.api.request('/spaces/${s.spaceId}/doctor-questions/${q['id']}',
        method: 'DELETE');
    await s.reloadQuestions();
    if (context.mounted) showToast(context, '问题已删除');
  });
}

Future<void> toggleQuestionImportant(
    BuildContext context, SessionController s, Map q) async {
  await _guard(context, () async {
    await s.api.request('/spaces/${s.spaceId}/doctor-questions/${q['id']}',
        method: 'PATCH', body: {'important': q['important'] != true});
    await s.reloadQuestions();
  });
}

Future<void> toggleQuestionAsked(
    BuildContext context, SessionController s, Map q) async {
  await _guard(context, () async {
    await s.api.request('/spaces/${s.spaceId}/doctor-questions/${q['id']}',
        method: 'PATCH', body: {'asked': q['asked'] != true});
    await s.reloadQuestions();
  });
}

// ——————————————————— 分享 / 动态 ———————————————————
Future<void> addMessage(BuildContext context, SessionController s) async {
  final values = await showForm(context,
      eyebrow: '说说此刻',
      title: '现在想说点什么？',
      message: '会发布到「分享」，家人朋友都能看到。',
      confirmText: '发布',
      fields: [
        FieldSpec('text', '内容',
            type: FieldType.textarea,
            required: true,
            placeholder: '此刻的想法、状态或想说的话')
      ]);
  if (values == null) return;
  await _guard(context, () async {
    await s.api.request('/spaces/${s.spaceId}/messages',
        method: 'POST', body: {'text': values['text']});
    await s.reloadMessages();
    if (context.mounted) showToast(context, '动态已发布');
  });
}

Future<void> editMessage(
    BuildContext context, SessionController s, Map m) async {
  final values = await showForm(context, eyebrow: '动态', title: '编辑动态', fields: [
    FieldSpec('text', '内容',
        type: FieldType.textarea, value: m['text'], required: true)
  ]);
  if (values == null) return;
  await _guard(context, () async {
    await s.api.request('/spaces/${s.spaceId}/messages/${m['id']}',
        method: 'PATCH', body: {'text': values['text']});
    await s.reloadMessages();
    if (context.mounted) showToast(context, '动态已更新');
  });
}

Future<void> deleteMessage(
    BuildContext context, SessionController s, Map m) async {
  final ok = await showConfirm(context,
      eyebrow: '删除动态',
      title: '删除这条动态？',
      message: m['text']?.toString() ?? '',
      confirmText: '删除',
      danger: true);
  if (!ok) return;
  await _guard(context, () async {
    await s.api
        .request('/spaces/${s.spaceId}/messages/${m['id']}', method: 'DELETE');
    await s.reloadMessages();
    if (context.mounted) showToast(context, '动态已删除');
  });
}

// ——————————————————— 资料 ———————————————————
Future<void> addNote(BuildContext context, SessionController s) async {
  final values = await showForm(context,
      eyebrow: '资料',
      title: '存一条复诊资料',
      confirmText: '保存',
      fields: [
        FieldSpec('title', '资料名称',
            required: true, placeholder: '报告名称、用药记录或医嘱备注'),
        FieldSpec('content', '内容', type: FieldType.textarea),
      ]);
  if (values == null) return;
  await _guard(context, () async {
    await s.api.request('/spaces/${s.spaceId}/notes', method: 'POST', body: {
      'title': values['title'],
      'type': '文本资料',
      'content': values['content'],
      'visibility': 'PATIENT_ADMIN',
    });
    await s.reloadNotes();
    if (context.mounted) showToast(context, '资料已保存');
  });
}

Future<void> editNote(BuildContext context, SessionController s, Map n) async {
  final values =
      await showForm(context, eyebrow: '资料夹', title: '编辑资料', fields: [
    FieldSpec('title', '资料标题', value: n['title'], required: true),
    FieldSpec('content', '资料内容',
        type: FieldType.textarea, value: n['content'] ?? ''),
  ]);
  if (values == null) return;
  await _guard(context, () async {
    await s.api.request('/spaces/${s.spaceId}/notes/${n['id']}',
        method: 'PATCH',
        body: {'title': values['title'], 'content': values['content']});
    await s.reloadNotes();
    if (context.mounted) showToast(context, '资料已更新');
  });
}

Future<void> deleteNote(
    BuildContext context, SessionController s, Map n) async {
  final ok = await showConfirm(context,
      eyebrow: '删除资料',
      title: '删除资料“${n['title']}”？',
      message: '删除后资料夹里不会再显示这条记录。',
      confirmText: '删除',
      danger: true);
  if (!ok) return;
  await _guard(context, () async {
    await s.api
        .request('/spaces/${s.spaceId}/notes/${n['id']}', method: 'DELETE');
    await s.reloadNotes();
    if (context.mounted) showToast(context, '资料已删除');
  });
}

// ——————————————————— 注意事项 ———————————————————
Future<void> addNotice(BuildContext context, SessionController s) async {
  final values = await showForm(context,
      eyebrow: '注意事项',
      title: '记一条注意事项',
      message: '医生叮嘱的禁忌和要小心的事。生效期间每天在「今天」页置顶提醒。',
      confirmText: '记下来',
      fields: [
        FieldSpec('content', '要注意的事',
            required: true, placeholder: '例如：化疗期间避免生食'),
        FieldSpec('detail', '补充说明', type: FieldType.textarea),
        FieldSpec('startsOn', '开始日期（可不填）', type: FieldType.date),
        FieldSpec('endsOn', '结束日期（可不填，留空=长期）', type: FieldType.date),
        FieldSpec('important', '标为重要', type: FieldType.checkbox),
      ]);
  if (values == null) return;
  await _guard(context, () async {
    await s.api.request('/spaces/${s.spaceId}/notices', method: 'POST', body: {
      'content': values['content'],
      'detail': values['detail'],
      'important': values['important'] == true,
      'startsOn': _dateOnly(values['startsOn']),
      'endsOn': _dateOnly(values['endsOn']),
    });
    await s.reloadNotices();
    if (context.mounted) showToast(context, '注意事项已记下，生效期间每天提醒');
  });
}

Future<void> editNotice(
    BuildContext context, SessionController s, Map n) async {
  final values =
      await showForm(context, eyebrow: '注意事项', title: '编辑注意事项', fields: [
    FieldSpec('content', '内容',
        type: FieldType.textarea, value: n['content'], required: true),
    FieldSpec('detail', '补充说明',
        type: FieldType.textarea, value: n['detail'] ?? ''),
    FieldSpec('startsOn', '开始日期',
        type: FieldType.date, value: tryParse(n['startsOn'])),
    FieldSpec('endsOn', '结束日期',
        type: FieldType.date, value: tryParse(n['endsOn'])),
    FieldSpec('important', '重要',
        type: FieldType.checkbox, value: n['important'] == true),
  ]);
  if (values == null) return;
  await _guard(context, () async {
    await s.api.request('/spaces/${s.spaceId}/notices/${n['id']}',
        method: 'PATCH',
        body: {
          'content': values['content'],
          'detail': values['detail'],
          'startsOn': _dateOnly(values['startsOn']),
          'endsOn': _dateOnly(values['endsOn']),
          'important': values['important'] == true,
        });
    await s.reloadNotices();
    if (context.mounted) showToast(context, '注意事项已更新');
  });
}

Future<void> toggleNoticeImportant(
    BuildContext context, SessionController s, Map n) async {
  await _guard(context, () async {
    await s.api.request('/spaces/${s.spaceId}/notices/${n['id']}',
        method: 'PATCH', body: {'important': n['important'] != true});
    await s.reloadNotices();
  });
}

Future<void> archiveNotice(
    BuildContext context, SessionController s, Map n) async {
  final archived = n['status'] == 'ARCHIVED';
  await _guard(context, () async {
    await s.api.request('/spaces/${s.spaceId}/notices/${n['id']}',
        method: 'PATCH', body: {'status': archived ? 'ACTIVE' : 'ARCHIVED'});
    await s.reloadNotices();
    if (context.mounted) {
      showToast(context, archived ? '注意事项已恢复' : '注意事项已归档');
    }
  });
}

Future<void> deleteNotice(
    BuildContext context, SessionController s, Map n) async {
  final ok = await showConfirm(context,
      eyebrow: '删除注意事项',
      title: '删除这条注意事项？',
      message: n['content']?.toString() ?? '',
      confirmText: '删除',
      danger: true);
  if (!ok) return;
  await _guard(context, () async {
    await s.api
        .request('/spaces/${s.spaceId}/notices/${n['id']}', method: 'DELETE');
    await s.reloadNotices();
    if (context.mounted) showToast(context, '注意事项已删除');
  });
}

// ——————————————————— 症状 ———————————————————
Future<void> editSymptom(
    BuildContext context, SessionController s, Map sy) async {
  final values = await showForm(context,
      eyebrow: '症状记录',
      title: '编辑「${sy['tag']}」',
      fields: [
        FieldSpec('tag', '症状', value: sy['tag'], required: true),
        FieldSpec('note', '补充说明',
            type: FieldType.textarea, value: sy['note'] ?? ''),
      ]);
  if (values == null) return;
  await _guard(context, () async {
    await s.api.request('/spaces/${s.spaceId}/symptoms/${sy['id']}',
        method: 'PATCH', body: {'tag': values['tag'], 'note': values['note']});
    await s.reloadSymptoms();
    if (context.mounted) showToast(context, '症状记录已更新');
  });
}

Future<void> deleteSymptom(
    BuildContext context, SessionController s, Map sy) async {
  final ok = await showConfirm(context,
      eyebrow: '删除症状记录',
      title: '删除「${sy['tag']}」这条记录？',
      message: formatMonthDayTime(sy['happenedAt']),
      confirmText: '删除',
      danger: true);
  if (!ok) return;
  await _guard(context, () async {
    await s.api
        .request('/spaces/${s.spaceId}/symptoms/${sy['id']}', method: 'DELETE');
    await s.reloadSymptoms();
    if (context.mounted) showToast(context, '症状记录已删除');
  });
}

// ——————————————————— 体温 / 体重 ———————————————————
Future<void> addTemperature(BuildContext context, SessionController s) async {
  final values = await showForm(context,
      eyebrow: '体温',
      title: '记一次体温',
      message: '体温常一天测多次，可以选具体时间。',
      confirmText: '记下来',
      fields: [
        FieldSpec('temperature', '体温（℃）',
            type: FieldType.number, required: true, placeholder: '例如 36.8'),
        FieldSpec('measuredAt', '测量时间',
            type: FieldType.datetime, value: DateTime.now()),
        FieldSpec('note', '备注（可不填）', placeholder: '例如：服药后测的'),
      ]);
  if (values == null) return;
  final temp = double.tryParse(values['temperature']?.toString() ?? '');
  if (temp == null) {
    if (context.mounted) showToast(context, '填一个有效的体温');
    return;
  }
  final when = (values['measuredAt'] as DateTime?) ?? DateTime.now();
  await _guard(context, () async {
    await s.api
        .request('/spaces/${s.spaceId}/body-records', method: 'POST', body: {
      'temperature': temp,
      'note': (values['note'] as String).isEmpty ? null : values['note'],
      'recordDate': dateKey(when),
      'measuredAt': when.toUtc().toIso8601String(),
    });
    await s.reloadBody();
    if (context.mounted) showToast(context, '已记录体温 $temp℃');
  });
}

Future<void> editTemperature(
    BuildContext context, SessionController s, Map r) async {
  final values = await showForm(context,
      eyebrow: '体温',
      title: '修改体温',
      confirmText: '保存修改',
      fields: [
        FieldSpec('temperature', '体温（℃）',
            type: FieldType.number, value: r['temperature'], required: true),
        FieldSpec('measuredAt', '测量时间',
            type: FieldType.datetime,
            value: tryParse(r['measuredAt'] ?? r['createdAt'])),
        FieldSpec('note', '备注', value: r['note'] ?? ''),
      ]);
  if (values == null) return;
  final temp = double.tryParse(values['temperature']?.toString() ?? '');
  if (temp == null) return;
  final when = (values['measuredAt'] as DateTime?) ?? DateTime.now();
  await _guard(context, () async {
    await s.api.request('/spaces/${s.spaceId}/body-records/${r['id']}',
        method: 'PATCH',
        body: {
          'temperature': temp,
          'measuredAt': when.toUtc().toIso8601String(),
          'recordDate': dateKey(when),
          'note': values['note'],
        });
    await s.reloadBody();
    if (context.mounted) showToast(context, '体温已更新');
  });
}

Future<void> addWeight(BuildContext context, SessionController s) async {
  final values = await showForm(context,
      eyebrow: '体重',
      title: '记一次体重',
      message: '默认记到今天，也可以补记到别的日期。',
      confirmText: '记下来',
      fields: [
        FieldSpec('weight', '体重（kg）',
            type: FieldType.number, required: true, placeholder: '例如 55.5'),
        FieldSpec('recordDate', '日期',
            type: FieldType.date, value: DateTime.now()),
        FieldSpec('note', '备注（可不填）', placeholder: '例如：早晨空腹'),
      ]);
  if (values == null) return;
  final weight = double.tryParse(values['weight']?.toString() ?? '');
  if (weight == null) {
    if (context.mounted) showToast(context, '填一个有效的体重');
    return;
  }
  await _guard(context, () async {
    await s.api
        .request('/spaces/${s.spaceId}/body-records', method: 'POST', body: {
      'weight': weight,
      'note': (values['note'] as String).isEmpty ? null : values['note'],
      'recordDate': _dateOnly(values['recordDate']) ?? todayKey(),
    });
    await s.reloadBody();
    if (context.mounted) showToast(context, '已记录体重 $weight kg');
  });
}

Future<void> editWeight(
    BuildContext context, SessionController s, Map r) async {
  final values = await showForm(context,
      eyebrow: '体重',
      title: '修改体重',
      confirmText: '保存修改',
      fields: [
        FieldSpec('weight', '体重（kg）',
            type: FieldType.number, value: r['weight'], required: true),
        FieldSpec('recordDate', '日期',
            type: FieldType.date,
            value: tryParse(r['recordDate']) ?? DateTime.now()),
        FieldSpec('note', '备注', value: r['note'] ?? ''),
      ]);
  if (values == null) return;
  final weight = double.tryParse(values['weight']?.toString() ?? '');
  if (weight == null) return;
  await _guard(context, () async {
    await s.api.request('/spaces/${s.spaceId}/body-records/${r['id']}',
        method: 'PATCH',
        body: {
          'weight': weight,
          'recordDate': _dateOnly(values['recordDate']) ?? todayKey(),
          'note': values['note'],
        });
    await s.reloadBody();
    if (context.mounted) showToast(context, '体重已更新');
  });
}

// ——————————————————— 成员 ———————————————————
Future<void> inviteMember(BuildContext context, SessionController s) async {
  await _guard(context, () async {
    final invite = Map<String, dynamic>.from(await s.api.request(
        '/spaces/${s.spaceId}/member-invites',
        method: 'POST',
        body: {'nickname': '家人朋友', 'role': 'FRIEND'}));
    final url =
        '$careOrigin/?invite=${invite['token'] ?? invite['id']}';
    await Clipboard.setData(ClipboardData(text: url));
    if (!context.mounted) return;
    await showForm(context,
        eyebrow: '邀请链接已生成',
        title: '把这条链接发给家人朋友',
        message: '链接已自动复制，直接粘贴到微信发给对方即可。对方打开登录后会自动加入，7 天内有效。',
        confirmText: '好的',
        cancelText: '关闭',
        fields: [
          FieldSpec('url', '邀请链接',
              type: FieldType.textarea, value: url, readonly: true)
        ]);
  });
}

Future<void> acceptMember(
    BuildContext context, SessionController s, Map m) async {
  await _guard(context, () async {
    await s.api.request('/spaces/${s.spaceId}/members/${m['id']}/accept',
        method: 'PATCH');
    await s.reloadMembers();
    if (context.mounted) showToast(context, '成员已确认加入');
  });
}

Future<void> removeMember(
    BuildContext context, SessionController s, Map m) async {
  final ok = await showConfirm(context,
      eyebrow: '移除成员',
      title: '移除成员“${m['nickname']}”？',
      message: '移除后该成员将不能继续访问这个陪伴空间。',
      confirmText: '移除',
      danger: true);
  if (!ok) return;
  await _guard(context, () async {
    await s.api
        .request('/spaces/${s.spaceId}/members/${m['id']}', method: 'DELETE');
    await s.reloadMembers();
    if (context.mounted) showToast(context, '成员已移除');
  });
}

Future<void> leaveSpace(BuildContext context, SessionController s) async {
  final ok = await showConfirm(context,
      eyebrow: '退出空间',
      title: '退出当前陪伴空间？',
      message: '退出后你将无法访问这里的数据，除非管理员重新邀请你。',
      confirmText: '退出空间',
      danger: true);
  if (!ok) return;
  await _guard(context, () async {
    await s.leaveSpace();
    if (context.mounted) showToast(context, '已退出空间');
  });
}

Future<void> deleteAccount(BuildContext context, SessionController s) async {
  final ok = await showConfirm(context,
      eyebrow: '删除账号',
      title: '删除账号会退出所有空间',
      message: '删除后当前账号将不能继续登录，必要审计信息会按规则保留。',
      confirmText: '删除账号',
      danger: true);
  if (!ok) return;
  await _guard(context, () async {
    await s.deleteAccount();
    if (context.mounted) showToast(context, '账号已删除');
  });
}
