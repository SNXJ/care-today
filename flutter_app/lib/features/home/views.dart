import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/format.dart';
import '../../core/ui.dart';
import '../session/session_controller.dart';
import 'actions.dart';
import 'composer.dart';
import 'manage.dart';
import 'panels.dart';

const _disclaimer = '仅用于陪伴协作和就诊整理；诊断、用药和治疗以医生意见为准。';

// ————————————————————————— 今天 —————————————————————————
class TodayView extends StatelessWidget {
  const TodayView({super.key});
  @override
  Widget build(BuildContext context) {
    final s = context.watch<SessionController>();
    final today = todayKey();
    final activeNotices = s.notices.where((n) => noticeActive(n)).toList();
    final todayEvents = s.events
        .where((e) => dateKeyOf(e['scheduledAt']) == today)
        .toList()
      ..sort((a, b) =>
          a['scheduledAt'].toString().compareTo(b['scheduledAt'].toString()));

    // 下次复诊倒计时
    final startOfToday = DateTime.now().copyWith(
        hour: 0, minute: 0, second: 0, millisecond: 0, microsecond: 0);
    final future = s.events
        .map((e) => tryParse(e['scheduledAt']))
        .whereType<DateTime>()
        .where((d) => !d.isBefore(startOfToday))
        .toList()
      ..sort();
    final nextVisit = future.isEmpty ? null : future.first;
    final countdown = nextVisit == null
        ? null
        : DateTime(nextVisit.year, nextVisit.month, nextVisit.day)
            .difference(startOfToday)
            .inDays;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (activeNotices.isNotEmpty)
          SectionCard(
            title: '要注意',
            tag: '有效期内置顶',
            icon: Icons.warning_amber_outlined,
            child: Column(
              children: activeNotices
                  .map((n) =>
                      _PinnedNotice(n, () => manageNotice(context, s, n)))
                  .toList(),
            ),
          ),
        SectionCard(
          title: '今天要做的事',
          tag:
              '下次复诊：${nextVisit == null ? '待添加' : formatTimelineDate(nextVisit.toIso8601String())}',
          icon: Icons.event_outlined,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (todayEvents.isEmpty)
                emptyNote('今天没有日程，给自己留一点从容也很好。')
              else
                ...todayEvents.map((e) => _ScheduleRow(e)),
              const Divider(height: 24),
              Row(
                children: [
                  const Text('距离下次复诊 ',
                      style: TextStyle(color: muted, fontSize: 13)),
                  Text(countdown == null ? '—' : '$countdown 天',
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 16)),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                  countdown == null
                      ? '还没有安排日程。'
                      : countdown == 0
                          ? '今天，把资料和问题带上。'
                          : '提前整理资料和问题。',
                  style: const TextStyle(color: muted, fontSize: 12)),
              const SizedBox(height: 12),
              Wrap(spacing: 8, children: [
                OutlinedButton(
                    onPressed: () => openQuestionsPanel(context),
                    child: const Text('问题清单')),
                OutlinedButton(
                    onPressed: () => openFolderPanel(context),
                    child: const Text('复诊资料')),
              ]),
            ],
          ),
        ),
        _MedicationCard(s, today),
        SectionCard(
          title: '及时联系医生',
          icon: Icons.warning_amber_outlined,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              _Bullet('持续发热、寒战或感染迹象。'),
              _Bullet('严重疼痛、呼吸困难、胸闷或晕厥。'),
              _Bullet('过敏、伤口异常或用药后不适加重。'),
            ],
          ),
        ),
      ],
    );
  }
}

/// 今天页的用药提醒：显示今天已记录的服药，并提供快速「记一次」入口。
class _MedicationCard extends StatelessWidget {
  const _MedicationCard(this.s, this.today);
  final SessionController s;
  final String today;
  @override
  Widget build(BuildContext context) {
    final todayMeds = s.medications
        .where((m) => dateKeyOf(m['takenAt']) == today)
        .toList()
      ..sort((a, b) =>
          a['takenAt'].toString().compareTo(b['takenAt'].toString()));
    return SectionCard(
      title: '今天的用药',
      tag: todayMeds.isEmpty ? '还没记录' : '已记 ${todayMeds.length} 次',
      icon: Icons.medication_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (todayMeds.isEmpty)
            emptyNote('今天还没有用药记录。吃过药就点下方按钮记一笔，别漏了也别重复吃。')
          else
            ...todayMeds.map((m) {
              final dosage = (m['dosage'] ?? '').toString();
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                        width: 52,
                        child: Text(formatTimelineTime(m['takenAt']),
                            style: const TextStyle(
                                fontWeight: FontWeight.w700, fontSize: 13))),
                    Expanded(
                      child: Text(
                          dosage.isEmpty
                              ? (m['name']?.toString() ?? '')
                              : '${m['name']}（$dosage）',
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              );
            }),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
                onPressed: () => addMedication(context, s),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('记一次服药')),
          ),
        ],
      ),
    );
  }
}

class _PinnedNotice extends StatelessWidget {
  const _PinnedNotice(this.n, this.onTap);
  final Map n;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final important = n['important'] == true;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
            color:
                important ? const Color(0xfffdeee2) : const Color(0xfffff7ee),
            borderRadius: BorderRadius.circular(12),
            border:
                Border.all(color: important ? amber : const Color(0xffeadbca))),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(n['content']?.toString() ?? '',
                style: const TextStyle(fontWeight: FontWeight.w700)),
            if ((n['detail'] ?? '').toString().isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(n['detail'].toString(),
                    style: const TextStyle(color: muted, fontSize: 13)),
              ),
            const SizedBox(height: 2),
            Text(noticeRangeLabel(n),
                style: const TextStyle(color: muted, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

class _ScheduleRow extends StatelessWidget {
  const _ScheduleRow(this.e);
  final Map e;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
              width: 48,
              child: Text(formatTimelineTime(e['scheduledAt']),
                  style: const TextStyle(fontWeight: FontWeight.w700))),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(e['title']?.toString() ?? '日程',
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                Text(
                    (e['note'] ?? '').toString().isNotEmpty
                        ? e['note'].toString()
                        : (e['location'] ?? '待补充地点').toString(),
                    style: const TextStyle(color: muted, fontSize: 13)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
                color: const Color(0xfff3ece2),
                borderRadius: BorderRadius.circular(20)),
            child: Text(e['needsCompanion'] == true ? '需要陪同' : '站内提醒',
                style: const TextStyle(fontSize: 11, color: muted)),
          ),
        ],
      ),
    );
  }
}

class _Bullet extends StatelessWidget {
  const _Bullet(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('· ', style: TextStyle(fontWeight: FontWeight.bold)),
          Expanded(child: Text(text, style: const TextStyle(height: 1.5))),
        ]),
      );
}

// ————————————————————————— 分享 —————————————————————————
class MomentsView extends StatelessWidget {
  const MomentsView({super.key});
  @override
  Widget build(BuildContext context) {
    final s = context.watch<SessionController>();
    final messages = s.messages;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        SectionCard(
          title: '分享',
          tag: s.isPatient ? '管理员可管理' : '成员都能发',
          icon: Icons.chat_bubble_outline,
          child: messages.isEmpty
              ? emptyNote('还没有分享。点右下角「+」发布近况。')
              : Column(
                  children: messages.map((m) {
                    final tile = Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                          color: const Color(0xfffff7ee),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xffeadbca))),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(m['text']?.toString() ?? '',
                              style: const TextStyle(height: 1.5)),
                          const SizedBox(height: 6),
                          Text(
                              '${m['author'] ?? '家人'} · ${formatFullDateTime(m['createdAt'])}',
                              style:
                                  const TextStyle(color: muted, fontSize: 12)),
                        ],
                      ),
                    );
                    if (!s.isPatient) return tile;
                    return InkWell(
                        onTap: () => manageMessage(context, s, m),
                        borderRadius: BorderRadius.circular(14),
                        child: tile);
                  }).toList(),
                ),
        ),
      ],
    );
  }
}

// ————————————————————————— 注意 —————————————————————————
class NoticesView extends StatelessWidget {
  const NoticesView({super.key});
  @override
  Widget build(BuildContext context) {
    final s = context.watch<SessionController>();
    final active = s.notices.where((n) => n['status'] != 'ARCHIVED').toList();
    final archived = s.notices.where((n) => n['status'] == 'ARCHIVED').toList();
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        SectionCard(
          title: '注意事项',
          tag: '生效中置顶',
          icon: Icons.warning_amber_outlined,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('点一条可编辑、归档或删除。',
                  style: TextStyle(color: muted, fontSize: 13)),
              const SizedBox(height: 8),
              if (active.isEmpty && archived.isEmpty) emptyNote('还没有注意事项。'),
              ...active.map((n) => _NoticeRow(n,
                  important: n['important'] == true,
                  onTap: () => manageNotice(context, s, n))),
              if (archived.isNotEmpty) ...[
                const SizedBox(height: 10),
                const Text('已归档（不再显示在「今天」）',
                    style: TextStyle(color: muted, fontSize: 13)),
                const SizedBox(height: 6),
                ...archived.map((n) => _NoticeRow(n,
                    archived: true, onTap: () => manageNotice(context, s, n))),
              ],
            ],
          ),
        ),
        SectionCard(
          title: '医疗边界',
          icon: Icons.privacy_tip_outlined,
          child: const Text(_disclaimer, style: TextStyle(height: 1.6)),
        ),
      ],
    );
  }
}

class _NoticeRow extends StatelessWidget {
  const _NoticeRow(this.n,
      {this.important = false, this.archived = false, required this.onTap});
  final Map n;
  final bool important, archived;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Opacity(
        opacity: archived ? 0.6 : 1,
        child: ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Icon(Icons.warning_amber_outlined,
              color: important ? amber : muted),
          title: Text(n['content']?.toString() ?? '',
              style: const TextStyle(fontWeight: FontWeight.w600)),
          subtitle: Text(noticeRangeLabel(n) +
              ((n['detail'] ?? '').toString().isNotEmpty && !archived
                  ? ' · ${n['detail']}'
                  : '')),
          trailing: const Icon(Icons.chevron_right, color: muted),
          onTap: onTap,
        ),
      );
}

// ————————————————————————— 时间线 —————————————————————————
class _TimelineItem {
  _TimelineItem(this.kind, this.raw, this.type, this.title, this.meta,
      this.detail, this.at, this.icon, this.accent, this.fields);
  final String kind, type, title, meta, detail;
  final Map raw;
  final dynamic at;
  final IconData icon;
  final Color accent;
  final List<ManageLine> fields;
}

class TimelineView extends StatelessWidget {
  const TimelineView({super.key});

  List<_TimelineItem> _build(SessionController s) {
    final items = <_TimelineItem>[];
    for (final e in s.events) {
      items.add(_TimelineItem(
          'event',
          e,
          '日程',
          e['title']?.toString() ?? '',
          '${formatTimelineTime(e['scheduledAt'])} · ${e['location'] ?? '待补充地点'}',
          (e['note'] ?? (e['needsCompanion'] == true ? '需要有人陪同' : '站内提醒'))
              .toString(),
          e['scheduledAt'],
          Icons.event_outlined,
          rose,
          [
            ManageLine('时间', formatFullDateTime(e['scheduledAt'])),
            ManageLine('地点', (e['location'] ?? '待补充地点').toString()),
            ManageLine('陪同', e['needsCompanion'] == true ? '需要有人陪同' : '不需要陪同'),
            ManageLine('备注', (e['note'] ?? '没有备注').toString()),
          ]));
    }
    for (final q in s.questions) {
      items.add(_TimelineItem(
          'question',
          q,
          '问医生',
          q['question']?.toString() ?? '',
          q['asked'] == true
              ? '已问过医生'
              : q['important'] == true
                  ? '重点问题'
                  : '待复诊时确认',
          (q['doctorAnswer'] ?? '还没有记录医生回复').toString(),
          q['createdAt'],
          Icons.help_outline,
          const Color(0xff5b7c99),
          [
            ManageLine('添加时间', formatFullDateTime(q['createdAt'])),
            ManageLine('状态',
                '${q['asked'] == true ? '已问过医生' : '待复诊时确认'}${q['important'] == true ? ' · 重点问题' : ''}'),
            ManageLine('医生答复', (q['doctorAnswer'] ?? '还没有记录医生回复').toString()),
          ]));
    }
    for (final m in s.messages) {
      items.add(_TimelineItem(
          'message',
          m,
          '分享',
          m['text']?.toString() ?? '',
          (m['author'] ?? '家人').toString(),
          '一条分享动态',
          m['createdAt'],
          Icons.chat_bubble_outline,
          rose, [
        ManageLine('来自', (m['author'] ?? '家人').toString()),
        ManageLine('时间', formatFullDateTime(m['createdAt'])),
        ManageLine('内容', m['text']?.toString() ?? ''),
      ]));
    }
    for (final n in s.notes) {
      items.add(_TimelineItem(
          'note',
          n,
          '资料',
          n['title']?.toString() ?? '',
          '${n['type'] ?? '文本资料'}',
          (n['content'] ?? '资料文本已保存').toString(),
          n['createdAt'],
          Icons.folder_outlined,
          sage, [
        ManageLine('类型', (n['type'] ?? '文本资料').toString()),
        ManageLine('创建时间', formatFullDateTime(n['createdAt'])),
        ManageLine('内容', (n['content'] ?? '资料文本已保存').toString()),
      ]));
    }
    for (final n in s.notices) {
      items.add(_TimelineItem(
          'notice',
          n,
          '注意',
          n['content']?.toString() ?? '',
          '${n['important'] == true ? '重要 · ' : ''}${noticeRangeLabel(n)}',
          (n['detail'] ?? '添加了一条注意事项').toString(),
          n['createdAt'],
          Icons.warning_amber_outlined,
          amber, [
        ManageLine('生效期', noticeRangeLabel(n)),
        ManageLine('重要程度', n['important'] == true ? '重要' : '一般'),
        ManageLine('补充说明', (n['detail'] ?? '没有补充说明').toString()),
        ManageLine('添加时间', formatFullDateTime(n['createdAt'])),
      ]));
    }
    items.removeWhere((i) => i.at == null);
    items.sort((a, b) => b.at.toString().compareTo(a.at.toString()));
    return items;
  }

  Future<void> _editFromDetail(
      BuildContext context, SessionController s, _TimelineItem item) async {
    switch (item.kind) {
      case 'event':
        await editEvent(context, s, item.raw);
      case 'question':
        await editQuestion(context, s, item.raw);
      case 'message':
        await editMessage(context, s, item.raw);
      case 'note':
        await editNote(context, s, item.raw);
      case 'notice':
        await editNotice(context, s, item.raw);
    }
  }

  Future<void> _openDetail(
      BuildContext context, SessionController s, _TimelineItem item) {
    return showManageSheet(context,
        eyebrow: '${item.type} · ${formatTimelineDate(item.at)}',
        title: item.title,
        lines: item.fields,
        actions: [ManageAction('修改', () => _editFromDetail(context, s, item))]);
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<SessionController>();
    final items = _build(s);
    final future = items.where((i) => isAfterToday(i.at)).toList();
    final past = items.where((i) => !isAfterToday(i.at)).toList();
    final todayLabel = '${DateTime.now().month}月${DateTime.now().day}日';

    if (items.isEmpty) {
      return ListView(padding: const EdgeInsets.all(16), children: [
        SectionCard(
            title: '陪伴时间线',
            icon: Icons.timeline,
            child: emptyNote('还没有记录。点右下角「+」添加第一条。')),
      ]);
    }

    List<Widget> rail(List<_TimelineItem> list) => [
          for (var i = 0; i < list.length; i++)
            _TimelineRow(
              list[i],
              isFirst: i == 0,
              isLast: i == list.length - 1,
              onTap: () => _openDetail(context, s, list[i]),
            )
        ];

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        if (future.isNotEmpty) ...[
          _sectionHead('接下来', '${future.length} 项即将发生'),
          ...rail(future),
          const SizedBox(height: 4),
        ],
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(children: [
            const Expanded(child: Divider()),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Text('今天 · $todayLabel',
                  style: const TextStyle(color: muted, fontSize: 12)),
            ),
            const Expanded(child: Divider()),
          ]),
        ),
        if (past.isEmpty) emptyNote('今天和之前还没有记录。') else ...rail(past),
      ],
    );
  }

  Widget _sectionHead(String title, String sub) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(width: 8),
          Text(sub, style: const TextStyle(color: muted, fontSize: 12)),
        ]),
      );
}

/// 时间线一行：左侧竖向连接线 + 节点圆点，右侧内容卡片。
class _TimelineRow extends StatelessWidget {
  const _TimelineRow(this.item,
      {required this.isFirst, required this.isLast, required this.onTap});
  final _TimelineItem item;
  final bool isFirst, isLast;
  final VoidCallback onTap;

  static const _nodeCenter = 26.0; // 节点圆心距顶部距离

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 连接线轨道
          SizedBox(
            width: 40,
            child: Stack(
              children: [
                // 上半段线
                if (!isFirst)
                  const Positioned(
                      top: 0,
                      height: _nodeCenter,
                      left: 0,
                      right: 0,
                      child: Center(child: _Line())),
                // 下半段线（延伸到底部）
                if (!isLast)
                  const Positioned(
                      top: _nodeCenter,
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Center(child: _Line())),
                // 节点圆点
                Positioned(
                  top: _nodeCenter - 15,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                          color: const Color(0xfffffdf9),
                          shape: BoxShape.circle,
                          border: Border.all(color: item.accent, width: 2)),
                      child: Icon(item.icon, size: 15, color: item.accent),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // 内容卡片
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Material(
                color: const Color(0xfffffdf9),
                borderRadius: BorderRadius.circular(16),
                child: InkWell(
                  onTap: onTap,
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xffeadbca))),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          Text(formatTimelineDate(item.at),
                              style: TextStyle(
                                  color: item.accent,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800)),
                          const SizedBox(width: 6),
                          Text(formatTimelineTime(item.at),
                              style:
                                  const TextStyle(color: muted, fontSize: 12)),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                                color: item.accent.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(20)),
                            child: Text(item.type,
                                style: TextStyle(
                                    color: item.accent,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600)),
                          ),
                        ]),
                        const SizedBox(height: 8),
                        Text(item.title,
                            style:
                                const TextStyle(fontWeight: FontWeight.w700)),
                        const SizedBox(height: 2),
                        Text(item.meta,
                            style: const TextStyle(color: muted, fontSize: 13)),
                        if (item.detail.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(item.detail,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    color: muted, fontSize: 12)),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Line extends StatelessWidget {
  const _Line();
  @override
  Widget build(BuildContext context) =>
      Container(width: 2, color: const Color(0xffe5d8c8));
}
