import '../../core/format.dart';

/// 全部记录页的四类记录。
enum RecordKind { symptom, medication, vital, score }

const recordKindLabels = {
  RecordKind.symptom: '症状',
  RecordKind.medication: '用药',
  RecordKind.vital: '体征',
  RecordKind.score: '评分',
};

const scoreFieldLabels = {
  '疼痛': 'painScore',
  '乏力': 'fatigueScore',
  '睡眠': 'sleepScore',
  '心情': 'moodScore',
  '食欲': 'appetiteScore',
};

/// 体征字段 → 展示名与单位。
const vitalFieldLabels = {
  'temperature': ['体温', '℃'],
  'weight': ['体重', 'kg'],
  'systolic': ['收缩压', 'mmHg'],
  'diastolic': ['舒张压', 'mmHg'],
  'heartRate': ['心率', '次/分'],
  'bloodSugar': ['血糖', 'mmol/L'],
};

/// 统一后的记录行，UI 只认这个结构。
class UnifiedRecord {
  final RecordKind kind;
  final DateTime? time;
  final String title;
  final String subtitle;
  final Map raw;
  const UnifiedRecord({
    required this.kind,
    required this.time,
    required this.title,
    required this.subtitle,
    required this.raw,
  });
}

String _text(dynamic v) => (v ?? '').toString().trim();

/// 去掉小数末尾的 .0，让 38.0 显示成 38。
String _num(dynamic v) {
  final s = _text(v);
  return s.endsWith('.0') ? s.substring(0, s.length - 2) : s;
}

/// 把某一类原始数据整理成按时间倒序的统一记录列表。
List<UnifiedRecord> buildRecords(
  RecordKind kind, {
  required List symptoms,
  required List medications,
  required List body,
}) {
  final rows = <UnifiedRecord>[];
  switch (kind) {
    case RecordKind.symptom:
      for (final sy in symptoms.cast<Map>()) {
        rows.add(UnifiedRecord(
          kind: kind,
          time: tryParse(sy['happenedAt']),
          title: _text(sy['tag']),
          subtitle: _text(sy['note']),
          raw: sy,
        ));
      }
    case RecordKind.medication:
      for (final m in medications.cast<Map>()) {
        final parts = [_text(m['dosage']), _text(m['note'])]
            .where((e) => e.isNotEmpty)
            .toList();
        rows.add(UnifiedRecord(
          kind: kind,
          time: tryParse(m['takenAt']),
          title: _text(m['name']),
          subtitle: parts.join(' · '),
          raw: m,
        ));
      }
    case RecordKind.vital:
      for (final r in body.cast<Map>()) {
        final parts = <String>[];
        for (final e in vitalFieldLabels.entries) {
          final v = r[e.key];
          if (v == null || _text(v).isEmpty) continue;
          parts.add('${e.value[0]} ${_num(v)}${e.value[1]}');
        }
        if (parts.isEmpty) continue;
        rows.add(UnifiedRecord(
          kind: kind,
          time: tryParse(r['measuredAt'] ?? r['createdAt'] ?? r['recordDate']),
          title: parts.join(' · '),
          subtitle: _text(r['note']),
          raw: r,
        ));
      }
    case RecordKind.score:
      for (final r in body.cast<Map>()) {
        final parts = <String>[];
        for (final e in scoreFieldLabels.entries) {
          final v = r[e.value];
          if (v == null || _text(v).isEmpty) continue;
          parts.add('${e.key} ${_num(v)}');
        }
        if (parts.isEmpty) continue;
        rows.add(UnifiedRecord(
          kind: kind,
          time: tryParse(r['createdAt'] ?? r['recordDate']),
          title: parts.join(' · '),
          subtitle: _text(r['note']),
          raw: r,
        ));
      }
  }
  rows.sort((a, b) {
    final at = a.time, bt = b.time;
    if (at == null && bt == null) return 0;
    if (at == null) return 1;
    if (bt == null) return -1;
    return bt.compareTo(at);
  });
  return rows;
}

/// 最近 N 天；[days] 为 null 表示不限时间。
List<UnifiedRecord> filterByDays(List<UnifiedRecord> rows, int? days,
    {DateTime? now}) {
  if (days == null) return rows;
  final cutoff =
      (now ?? DateTime.now()).subtract(Duration(days: days));
  return rows
      .where((r) => r.time != null && !r.time!.isBefore(cutoff))
      .toList();
}

/// 自定义日期区间（含首尾两天）。
List<UnifiedRecord> filterByRange(
    List<UnifiedRecord> rows, DateTime from, DateTime to) {
  final start = DateTime(from.year, from.month, from.day);
  final end = DateTime(to.year, to.month, to.day).add(const Duration(days: 1));
  return rows
      .where((r) =>
          r.time != null && !r.time!.isBefore(start) && r.time!.isBefore(end))
      .toList();
}

/// 标题 / 备注关键字搜索，不区分大小写。
List<UnifiedRecord> searchRecords(List<UnifiedRecord> rows, String query) {
  final q = query.trim().toLowerCase();
  if (q.isEmpty) return rows;
  return rows
      .where((r) =>
          r.title.toLowerCase().contains(q) ||
          r.subtitle.toLowerCase().contains(q))
      .toList();
}

/// 按天分组，键为 yyyy-MM-dd，保持传入顺序（新→旧）。
Map<String, List<UnifiedRecord>> groupByDay(List<UnifiedRecord> rows) {
  final groups = <String, List<UnifiedRecord>>{};
  for (final r in rows) {
    final key = r.time == null ? '未知时间' : dateKey(r.time!);
    groups.putIfAbsent(key, () => []).add(r);
  }
  return groups;
}
