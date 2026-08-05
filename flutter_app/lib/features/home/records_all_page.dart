import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/format.dart';
import '../../core/ui.dart';
import '../session/session_controller.dart';
import 'actions.dart';
import 'manage.dart';
import 'records_filter.dart';

/// 全部记录：四类记录的完整历史，支持时间范围过滤与关键字搜索。
class RecordsAllPage extends StatefulWidget {
  const RecordsAllPage({super.key, this.initialKind = RecordKind.symptom});
  final RecordKind initialKind;

  static Future<void> open(BuildContext context, RecordKind kind) {
    return Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => RecordsAllPage(initialKind: kind),
    ));
  }

  @override
  State<RecordsAllPage> createState() => _RecordsAllPageState();
}

class _RecordsAllPageState extends State<RecordsAllPage> {
  late RecordKind kind = widget.initialKind;
  int? days = 30; // null = 全部
  DateTimeRange? customRange;
  final searchController = TextEditingController();

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> _pickRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 5),
      lastDate: now,
      initialDateRange: customRange,
      helpText: '选择时间范围',
      saveText: '确定',
    );
    if (picked != null) {
      setState(() {
        customRange = picked;
        days = null;
      });
    }
  }

  void _openRecord(UnifiedRecord r, SessionController s) {
    switch (r.kind) {
      case RecordKind.symptom:
        manageSymptom(context, s, r.raw);
      case RecordKind.medication:
        manageMedication(context, s, r.raw);
      case RecordKind.vital:
        if (r.raw['temperature'] != null) {
          editTemperature(context, s, r.raw);
        } else if (r.raw['weight'] != null) {
          editWeight(context, s, r.raw);
        }
      case RecordKind.score:
        break; // 评分记录暂不支持编辑
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<SessionController>();
    var rows = buildRecords(kind,
        symptoms: s.symptoms, medications: s.medications, body: s.body);
    final total = rows.length;
    if (customRange != null) {
      rows = filterByRange(rows, customRange!.start, customRange!.end);
    } else {
      rows = filterByDays(rows, days);
    }
    rows = searchRecords(rows, searchController.text);
    final groups = groupByDay(rows);

    return Scaffold(
      appBar: AppBar(
        title: const Text('全部记录'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(104),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  height: 38,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      for (final k in RecordKind.values) ...[
                        ChoiceChip(
                          label: Text(recordKindLabels[k]!),
                          selected: kind == k,
                          onSelected: (_) => setState(() => kind = k),
                        ),
                        const SizedBox(width: 8),
                      ],
                    ],
                  ),
                ),
                SizedBox(
                  height: 38,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      _rangeChip('7 天', 7),
                      _rangeChip('30 天', 30),
                      _rangeChip('90 天', 90),
                      _rangeChip('全部', null),
                      ChoiceChip(
                        avatar: const Icon(Icons.date_range, size: 15),
                        label: Text(customRange == null
                            ? '自定义'
                            : '${formatDateLabel(customRange!.start)}–${formatDateLabel(customRange!.end)}'),
                        selected: customRange != null,
                        onSelected: (_) => _pickRange(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: TextField(
              controller: searchController,
              decoration: InputDecoration(
                isDense: true,
                hintText: '搜索${recordKindLabels[kind]}内容或备注',
                prefixIcon: const Icon(Icons.search, size: 18),
                suffixIcon: searchController.text.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.close, size: 16),
                        onPressed: () =>
                            setState(() => searchController.clear()),
                      ),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 6, 18, 6),
            child: Row(
              children: [
                Text(
                  rows.length == total
                      ? '共 $total 条'
                      : '筛选出 ${rows.length} 条 / 共 $total 条',
                  style: const TextStyle(color: muted, fontSize: 12),
                ),
                const Spacer(),
                if (customRange != null || searchController.text.isNotEmpty)
                  TextButton(
                    onPressed: () => setState(() {
                      customRange = null;
                      days = 30;
                      searchController.clear();
                    }),
                    child: const Text('重置筛选', style: TextStyle(fontSize: 12)),
                  ),
              ],
            ),
          ),
          Expanded(
            child: rows.isEmpty
                ? emptyNote('这个时间范围内没有${recordKindLabels[kind]}记录。')
                : ListView(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    children: [
                      for (final entry in groups.entries) ...[
                        Padding(
                          padding: const EdgeInsets.only(top: 14, bottom: 4),
                          child: Row(
                            children: [
                              Text(_dayLabel(entry.key),
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13)),
                              const SizedBox(width: 8),
                              Text('${entry.value.length} 条',
                                  style: const TextStyle(
                                      color: muted, fontSize: 11)),
                            ],
                          ),
                        ),
                        ...entry.value.map((r) => _row(r, s)),
                      ],
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _rangeChip(String label, int? value) => Padding(
        padding: const EdgeInsets.only(right: 8),
        child: ChoiceChip(
          label: Text(label),
          selected: customRange == null && days == value,
          onSelected: (_) => setState(() {
            days = value;
            customRange = null;
          }),
        ),
      );

  String _dayLabel(String key) {
    if (key == todayKey()) return '今天';
    final yesterday =
        dateKey(DateTime.now().subtract(const Duration(days: 1)));
    if (key == yesterday) return '昨天';
    return key;
  }

  Widget _row(UnifiedRecord r, SessionController s) {
    final editable = r.kind != RecordKind.score;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      dense: true,
      leading: SizedBox(
        width: 46,
        child: Text(formatTimelineTime(r.time?.toIso8601String()),
            style: const TextStyle(
                fontWeight: FontWeight.w600, fontSize: 12, color: muted)),
      ),
      title: Text(r.title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: r.subtitle.isEmpty ? null : Text(r.subtitle),
      trailing:
          editable ? const Icon(Icons.chevron_right, color: muted) : null,
      onTap: editable ? () => _openRecord(r, s) : null,
    );
  }
}
