import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/format.dart';
import '../../core/ui.dart';
import '../session/session_controller.dart';
import 'actions.dart';
import 'manage.dart';
import 'trend_chart.dart';

const _disclaimer = '仅用于陪伴协作和就诊整理；诊断、用药和治疗以医生意见为准。';
const _scoreLabels = {
  '疼痛': 'painScore',
  '乏力': 'fatigueScore',
  '睡眠': 'sleepScore',
  '心情': 'moodScore',
  '食欲': 'appetiteScore',
};

class BodyView extends StatefulWidget {
  const BodyView({super.key});
  @override
  State<BodyView> createState() => _BodyViewState();
}

class _BodyViewState extends State<BodyView> {
  String metric = '疼痛';
  int days = 7;
  String symptomFilter = '全部';

  dynamic _timeOf(Map r) =>
      r['measuredAt'] ?? r['createdAt'] ?? r['recordDate'];

  @override
  Widget build(BuildContext context) {
    final s = context.watch<SessionController>();
    final latestTemp =
        s.body.cast<Map>().where((r) => r['temperature'] != null).toList();
    final latestWeight =
        s.body.cast<Map>().where((r) => r['weight'] != null).toList();
    final today = todayKey();
    final todaySymptoms =
        s.symptoms.where((sy) => dateKeyOf(sy['happenedAt']) == today).toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _summaryTiles(
            context, s, latestTemp, latestWeight, todaySymptoms.length),
        const SizedBox(height: 4),
        _trendCard(s),
        if (_todayTemps(s, today).isNotEmpty) _todayTempCard(context, s, today),
        _medicationCard(context, s, today),
        _symptomCard(context, s, today),
        _scoreRecordsCard(s),
        SectionCard(
            title: '医疗边界',
            icon: Icons.privacy_tip_outlined,
            child: const Text(_disclaimer, style: TextStyle(height: 1.6))),
      ],
    );
  }

  Widget _summaryTiles(BuildContext context, SessionController s,
      List<Map> temps, List<Map> weights, int symptomCount) {
    final temp = temps.isEmpty ? null : temps.first;
    final weight = weights.isEmpty ? null : weights.first;
    return Row(
      children: [
        Expanded(
            child: _Tile(
                label: '最新体温',
                value: temp == null ? '—' : '${temp['temperature']}',
                unit: temp == null ? '' : '℃',
                sub: temp == null ? '还没记过' : formatFullDateTime(_timeOf(temp)),
                color: rose,
                onTap: temp == null
                    ? null
                    : () => editTemperature(context, s, temp))),
        const SizedBox(width: 8),
        Expanded(
            child: _Tile(
                label: '最新体重',
                value: weight == null ? '—' : '${weight['weight']}',
                unit: weight == null ? '' : 'kg',
                sub: weight == null
                    ? '还没记过'
                    : '${formatTimelineDate(_timeOf(weight))} 记录',
                color: amber,
                onTap: weight == null
                    ? null
                    : () => editWeight(context, s, weight))),
        const SizedBox(width: 8),
        Expanded(
            child: _Tile(
                label: '今日症状',
                value: '$symptomCount',
                unit: '次',
                sub: symptomCount > 0 ? '点下方查看' : '今天还没有',
                color: const Color(0xffc8893f),
                onTap: null)),
      ],
    );
  }

  Widget _trendCard(SessionController s) {
    return SectionCard(
      title: '变化趋势',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              ChoiceChip(
                  label: const Text('7 天'),
                  selected: days == 7,
                  onSelected: (_) => setState(() => days = 7)),
              const SizedBox(width: 8),
              ChoiceChip(
                  label: const Text('30 天'),
                  selected: days == 30,
                  onSelected: (_) => setState(() => days = 30)),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: trendMetrics
                .map((m) => ChoiceChip(
                    label: Text(m),
                    selected: metric == m,
                    onSelected: (_) => setState(() => metric = m)))
                .toList(),
          ),
          const SizedBox(height: 12),
          TrendChart(records: s.body, metric: metric, days: days),
        ],
      ),
    );
  }

  List<Map> _todayTemps(SessionController s, String today) => s.body
      .cast<Map>()
      .where((r) => r['temperature'] != null && r['recordDate'] == today)
      .toList()
    ..sort((a, b) => _timeOf(b).toString().compareTo(_timeOf(a).toString()));

  Widget _todayTempCard(
      BuildContext context, SessionController s, String today) {
    final temps = _todayTemps(s, today);
    return SectionCard(
      title: '今天的体温',
      tag: '${temps.length} 次',
      icon: Icons.thermostat_outlined,
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: temps
            .map((r) => InkWell(
                  onTap: () => editTemperature(context, s, r),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                        color: const Color(0xfffff7ee),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xffeadbca))),
                    child: Column(children: [
                      Text('${r['temperature']}℃',
                          style: const TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 16)),
                      Text(formatTimelineTime(_timeOf(r)),
                          style: const TextStyle(color: muted, fontSize: 12)),
                      if ((r['note'] ?? '').toString().isNotEmpty)
                        Text(r['note'].toString(),
                            style: const TextStyle(color: muted, fontSize: 11)),
                    ]),
                  ),
                ))
            .toList(),
      ),
    );
  }

  Widget _medicationCard(
      BuildContext context, SessionController s, String today) {
    final cutoff = DateTime.now().subtract(const Duration(days: 7));
    final todayList = s.medications
        .where((m) => dateKeyOf(m['takenAt']) == today)
        .toList()
      ..sort((a, b) =>
          b['takenAt'].toString().compareTo(a['takenAt'].toString()));
    final recentList = s.medications.where((m) {
      final d = tryParse(m['takenAt']);
      return dateKeyOf(m['takenAt']) != today &&
          d != null &&
          !d.isBefore(cutoff);
    }).toList()
      ..sort((a, b) =>
          b['takenAt'].toString().compareTo(a['takenAt'].toString()));

    return SectionCard(
      title: '用药记录',
      tag: todayList.isEmpty ? '今天还没记' : '今天 ${todayList.length} 次',
      icon: Icons.medication_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (todayList.isEmpty && recentList.isEmpty)
            emptyNote('还没有用药记录。点右下角「+」记一次服药，别忘了吃药。'),
          if (todayList.isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.only(top: 4, bottom: 4),
              child: Text('今天',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
            ),
            ...todayList.map((m) => _medicationRow(
                context, s, m, formatTimelineTime(m['takenAt']))),
          ],
          if (recentList.isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.only(top: 8, bottom: 4),
              child: Text('最近 7 天',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
            ),
            ...recentList.map((m) => _medicationRow(
                context, s, m, formatMonthDayTime(m['takenAt']))),
          ],
        ],
      ),
    );
  }

  Widget _medicationRow(
      BuildContext context, SessionController s, Map m, String time) {
    final dosage = (m['dosage'] ?? '').toString();
    final note = (m['note'] ?? '').toString();
    final subParts = [
      if (dosage.isNotEmpty) dosage,
      if (note.isNotEmpty) note,
    ];
    return ListTile(
      contentPadding: EdgeInsets.zero,
      dense: true,
      leading: SizedBox(
          width: 84,
          child: Text(time,
              style: const TextStyle(
                  fontWeight: FontWeight.w600, fontSize: 12, color: muted))),
      title: Text(m['name']?.toString() ?? '',
          style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: subParts.isEmpty ? null : Text(subParts.join(' · ')),
      trailing: const Icon(Icons.chevron_right, color: muted),
      onTap: () => manageMedication(context, s, m),
    );
  }

  Widget _symptomCard(BuildContext context, SessionController s, String today) {
    final tags = s.symptoms
        .map((sy) => sy['tag']?.toString())
        .whereType<String>()
        .toSet()
        .toList()
      ..sort();
    final options = ['全部', ...tags];
    if (!options.contains(symptomFilter)) symptomFilter = '全部';

    bool match(Map sy) => symptomFilter == '全部' || sy['tag'] == symptomFilter;
    final cutoff = DateTime.now().subtract(const Duration(days: 7));
    final todayList = s.symptoms
        .where((sy) => dateKeyOf(sy['happenedAt']) == today && match(sy))
        .toList()
      ..sort((a, b) =>
          b['happenedAt'].toString().compareTo(a['happenedAt'].toString()));
    final recentList = s.symptoms.where((sy) {
      final d = tryParse(sy['happenedAt']);
      return dateKeyOf(sy['happenedAt']) != today &&
          d != null &&
          !d.isBefore(cutoff) &&
          match(sy);
    }).toList()
      ..sort((a, b) =>
          b['happenedAt'].toString().compareTo(a['happenedAt'].toString()));

    return SectionCard(
      title: '症状记录',
      tag: '可编辑',
      icon: Icons.healing_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (options.length > 1)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: options
                  .map((o) => ChoiceChip(
                      label: Text(o),
                      selected: symptomFilter == o,
                      onSelected: (_) => setState(() => symptomFilter = o)))
                  .toList(),
            ),
          if (todayList.isEmpty && recentList.isEmpty) emptyNote('没有匹配的症状记录。'),
          if (todayList.isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.only(top: 8, bottom: 4),
              child: Text('今天',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
            ),
            ...todayList.map((sy) => _symptomRow(
                context, s, sy, formatTimelineTime(sy['happenedAt']))),
          ],
          if (recentList.isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.only(top: 8, bottom: 4),
              child: Text('最近 7 天',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
            ),
            ...recentList.map((sy) => _symptomRow(
                context, s, sy, formatMonthDayTime(sy['happenedAt']))),
          ],
        ],
      ),
    );
  }

  Widget _symptomRow(
      BuildContext context, SessionController s, Map sy, String time) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      dense: true,
      leading: SizedBox(
          width: 64,
          child: Text(time,
              style: const TextStyle(
                  fontWeight: FontWeight.w600, fontSize: 12, color: muted))),
      title: Text(sy['tag']?.toString() ?? '',
          style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: (sy['note'] ?? '').toString().isEmpty
          ? null
          : Text(sy['note'].toString()),
      trailing: const Icon(Icons.chevron_right, color: muted),
      onTap: () => manageSymptom(context, s, sy),
    );
  }

  Widget _scoreRecordsCard(SessionController s) {
    final rows = <Widget>[];
    for (final r in s.body.cast<Map>()) {
      final scores = _scoreLabels.entries
          .where((e) => r[e.value] != null && r[e.value] != '')
          .map((e) => '${e.key} ${r[e.value]}')
          .toList();
      if (scores.isEmpty) continue;
      rows.add(Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
                width: 64,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(formatTimelineDate(r['createdAt'] ?? r['recordDate']),
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 12)),
                    Text(formatTimelineTime(r['createdAt'] ?? r['recordDate']),
                        style: const TextStyle(color: muted, fontSize: 11)),
                  ],
                )),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: scores
                        .map((sc) => Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                  color: const Color(0xfff3ece2),
                                  borderRadius: BorderRadius.circular(20)),
                              child: Text(sc,
                                  style: const TextStyle(fontSize: 12)),
                            ))
                        .toList(),
                  ),
                  if ((r['note'] ?? '').toString().isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(r['note'].toString(),
                          style: const TextStyle(color: muted, fontSize: 12)),
                    ),
                ],
              ),
            ),
          ],
        ),
      ));
      if (rows.length >= 8) break;
    }
    return SectionCard(
      title: '评分记录',
      tag: '最近 ${rows.length} 条',
      icon: Icons.favorite_outline,
      child: rows.isEmpty
          ? emptyNote('还没有评分记录。')
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch, children: rows),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile(
      {required this.label,
      required this.value,
      required this.unit,
      required this.sub,
      required this.color,
      this.onTap});
  final String label, value, unit, sub;
  final Color color;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
            color: const Color(0xfffffdf9),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xffeadbca))),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: muted, fontSize: 12)),
            const SizedBox(height: 6),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Flexible(
                  child: Text(value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 22,
                          color: color)),
                ),
                Text(unit, style: TextStyle(fontSize: 12, color: color)),
              ],
            ),
            const SizedBox(height: 4),
            Text(sub,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: muted, fontSize: 11)),
          ],
        ),
      ),
    );
  }
}
