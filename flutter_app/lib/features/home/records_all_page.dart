import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/format.dart';
import '../../core/ui.dart';
import '../session/session_controller.dart';
import 'actions.dart';
import 'manage.dart';
import 'records_filter.dart';

const _paper = Color(0xfffbf8f4);
const _panel = Color(0xfffffdf9);
const _line = Color(0xffeadbca);
const _softRose = Color(0xfff7e2de);

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

  bool get _filterDirty =>
      customRange != null || days != 30 || searchController.text.isNotEmpty;

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
      backgroundColor: _paper,
      appBar: AppBar(
        backgroundColor: _paper,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: const Text('全部记录',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 19)),
      ),
      body: Column(
        children: [
          _filterPanel(rows.length, total),
          Expanded(
            child: rows.isEmpty
                ? emptyNote('这个时间范围内没有${recordKindLabels[kind]}记录。')
                : ListView(
                    padding: const EdgeInsets.fromLTRB(16, 6, 16, 28),
                    children: [
                      for (final entry in groups.entries)
                        _dayGroup(entry.key, entry.value, s),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  /// 顶部筛选区：类别分段 + 时间区间 + 搜索 + 统计。
  Widget _filterPanel(int shown, int total) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      decoration: const BoxDecoration(
        color: _panel,
        border: Border(bottom: BorderSide(color: _line)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 类别：四等分，不滚动，永远完整可见
          Container(
            height: 36,
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: _paper,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _line),
            ),
            child: Row(
              children: [
                for (final k in RecordKind.values)
                  Expanded(child: _segment(k)),
              ],
            ),
          ),
          const SizedBox(height: 10),
          // 时间：快捷区间与日历按钮同属一个 Wrap，换行时也保持整齐，
          // 且永远不会像横向滚动那样把最后一项切在屏幕外。
          Wrap(
            spacing: 6,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _rangeChip('7 天', 7),
              _rangeChip('30 天', 30),
              _rangeChip('90 天', 90),
              _rangeChip('全部', null),
              _iconPill(
                icon: Icons.date_range_rounded,
                active: customRange != null,
                onTap: _pickRange,
              ),
            ],
          ),
          if (customRange != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.event_available_rounded,
                    size: 14, color: rose.withValues(alpha: 0.9)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    '${formatDateLabel(customRange!.start)} – ${formatDateLabel(customRange!.end)}',
                    style: const TextStyle(fontSize: 12.5, color: ink),
                  ),
                ),
                GestureDetector(
                  onTap: () => setState(() {
                    customRange = null;
                    days = 30;
                  }),
                  child: const Icon(Icons.close_rounded,
                      size: 15, color: muted),
                ),
              ],
            ),
          ],
          const SizedBox(height: 10),
          // 搜索
          SizedBox(
            height: 38,
            child: TextField(
              controller: searchController,
              style: const TextStyle(fontSize: 13.5),
              decoration: InputDecoration(
                isDense: true,
                filled: true,
                fillColor: _paper,
                hintText: '搜索${recordKindLabels[kind]}内容或备注',
                hintStyle: const TextStyle(fontSize: 13, color: muted),
                prefixIcon: const Icon(Icons.search_rounded,
                    size: 18, color: muted),
                prefixIconConstraints:
                    const BoxConstraints(minWidth: 34, minHeight: 34),
                suffixIcon: searchController.text.isEmpty
                    ? null
                    : GestureDetector(
                        onTap: () =>
                            setState(() => searchController.clear()),
                        child: const Icon(Icons.cancel_rounded,
                            size: 16, color: muted),
                      ),
                suffixIconConstraints:
                    const BoxConstraints(minWidth: 32, minHeight: 32),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 9),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: _line)),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: _line)),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: rose, width: 1.3)),
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
          const SizedBox(height: 8),
          _countLine(shown, total),
        ],
      ),
    );
  }

  Widget _countLine(int shown, int total) {
    return Row(
      children: [
        Text(
          shown == total ? '共 $total 条' : '筛选出 $shown 条 / 共 $total 条',
          style: const TextStyle(color: muted, fontSize: 12),
        ),
        const Spacer(),
        if (_filterDirty)
          GestureDetector(
            onTap: () => setState(() {
              customRange = null;
              days = 30;
              searchController.clear();
            }),
            child: Text('重置筛选',
                style: TextStyle(
                    fontSize: 12,
                    color: rose,
                    fontWeight: FontWeight.w600)),
          ),
      ],
    );
  }

  Widget _segment(RecordKind k) {
    final selected = kind == k;
    return GestureDetector(
      onTap: () => setState(() => kind = k),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? _softRose : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          recordKindLabels[k]!,
          style: TextStyle(
            fontSize: 13.5,
            color: selected ? rose : muted,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _rangeChip(String label, int? value) {
    final selected = customRange == null && days == value;
    return GestureDetector(
      onTap: () => setState(() {
        days = value;
        customRange = null;
      }),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? _softRose : _paper,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: selected ? _softRose : _line),
        ),
        child: Text(label,
            style: TextStyle(
              fontSize: 12.5,
              color: selected ? rose : muted,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
            )),
      ),
    );
  }

  Widget _iconPill(
      {required IconData icon,
      required bool active,
      required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 32,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: active ? _softRose : _paper,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: active ? _softRose : _line),
        ),
        child: Icon(icon, size: 16, color: active ? rose : muted),
      ),
    );
  }

  Widget _dayGroup(
      String dayKey, List<UnifiedRecord> items, SessionController s) {
    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 2, bottom: 6),
            child: Row(
              children: [
                Container(
                  width: 3,
                  height: 13,
                  decoration: BoxDecoration(
                      color: rose, borderRadius: BorderRadius.circular(2)),
                ),
                const SizedBox(width: 7),
                Text(_dayLabel(dayKey),
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 13, color: ink)),
                const SizedBox(width: 7),
                Text('${items.length} 条',
                    style: const TextStyle(color: muted, fontSize: 11)),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: _panel,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _line),
            ),
            child: Column(
              children: [
                for (var i = 0; i < items.length; i++) ...[
                  if (i > 0)
                    const Divider(
                        height: 1, thickness: 1, indent: 14, endIndent: 14,
                        color: Color(0xfff2e8dc)),
                  _row(items[i], s),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _dayLabel(String key) {
    if (key == todayKey()) return '今天';
    final yesterday =
        dateKey(DateTime.now().subtract(const Duration(days: 1)));
    if (key == yesterday) return '昨天';
    return key;
  }

  Widget _row(UnifiedRecord r, SessionController s) {
    final editable = r.kind != RecordKind.score;
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: editable ? () => _openRecord(r, s) : null,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 11, 12, 11),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 42,
              child: Text(formatTimelineTime(r.time?.toIso8601String()),
                  style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                      color: muted)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(r.title,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14.5,
                          color: ink,
                          height: 1.3)),
                  if (r.subtitle.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 3),
                      child: Text(r.subtitle,
                          style: const TextStyle(
                              fontSize: 12.5, color: muted, height: 1.4)),
                    ),
                ],
              ),
            ),
            if (editable)
              const Padding(
                padding: EdgeInsets.only(left: 6, top: 2),
                child: Icon(Icons.chevron_right_rounded,
                    size: 18, color: Color(0xffc4b8aa)),
              ),
          ],
        ),
      ),
    );
  }
}
