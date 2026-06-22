/// 日期与文本格式化工具，与 Web 端 App.vue 中的同名函数保持一致。
library;

const weekdayLabels = ['一', '二', '三', '四', '五', '六', '日'];

DateTime? tryParse(dynamic value) {
  if (value == null) return null;
  return DateTime.tryParse(value.toString())?.toLocal();
}

/// yyyy-MM-dd
String dateKey(DateTime date) {
  final m = date.month.toString().padLeft(2, '0');
  final d = date.day.toString().padLeft(2, '0');
  return '${date.year}-$m-$d';
}

String todayKey() => dateKey(DateTime.now());

/// 把字符串时间转成本地 dateKey，解析失败返回空串。
String dateKeyOf(dynamic value) {
  final d = tryParse(value);
  return d == null ? '' : dateKey(d);
}

bool isAfterToday(dynamic value) {
  final d = tryParse(value);
  if (d == null) return false;
  final endOfToday = DateTime.now().copyWith(
      hour: 23, minute: 59, second: 59, millisecond: 999, microsecond: 0);
  return d.isAfter(endOfToday);
}

/// 时间线日期：今年只显示「x月x日」，跨年带年份。
String formatTimelineDate(dynamic value) {
  final d = tryParse(value);
  if (d == null) return '待记录';
  if (d.year == DateTime.now().year) return '${d.month}月${d.day}日';
  return '${d.year}年${d.month}月${d.day}日';
}

String formatTimelineTime(dynamic value) {
  final d = tryParse(value);
  if (d == null) return '';
  return '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
}

String formatClock(dynamic value) => formatTimelineTime(value);

String formatFullDateTime(dynamic value) {
  final d = tryParse(value);
  if (d == null) return '待记录';
  return '${d.year}年${d.month}月${d.day}日 ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
}

/// 月日 + 时分，用于近 7 天症状。
String formatMonthDayTime(dynamic value) {
  final d = tryParse(value);
  if (d == null) return '待记录';
  return '${d.month}月${d.day}日 ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
}

/// 体重小数：去掉无意义的 .0
String trimDecimal(num value) {
  final s = value.toStringAsFixed(1);
  return s.endsWith('.0') ? s.substring(0, s.length - 2) : s;
}

String formatDateLabel(DateTime d) => '${d.month}/${d.day}';

/// 当前本地时间，用于 datetime 字段默认值。
DateTime nowLocal() => DateTime.now();
