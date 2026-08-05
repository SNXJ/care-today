import 'package:care_today_mobile/features/home/records_filter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final symptoms = [
    {'id': 's1', 'tag': '头痛', 'note': '下午加重', 'happenedAt': '2026-07-06T09:00:00'},
    {'id': 's2', 'tag': '恶心', 'note': '', 'happenedAt': '2026-06-01T20:30:00'},
  ];
  final medications = [
    {
      'id': 'm1',
      'name': '布洛芬',
      'dosage': '1 片',
      'note': '饭后',
      'takenAt': '2026-07-05T12:00:00',
    },
  ];
  final body = [
    {
      'id': 'b1',
      'temperature': 38.2,
      'weight': null,
      'createdAt': '2026-07-04T08:00:00',
    },
    {
      'id': 'b2',
      'weight': 60.5,
      'painScore': 3,
      'note': '还行',
      'createdAt': '2026-05-01T08:00:00',
    },
  ];

  test('buildRecords maps symptoms with tag and note', () {
    final rows = buildRecords(RecordKind.symptom,
        symptoms: symptoms, medications: medications, body: body);
    expect(rows, hasLength(2));
    expect(rows.first.title, '头痛');
    expect(rows.first.subtitle, '下午加重');
    expect(rows.first.time, DateTime.parse('2026-07-06T09:00:00'));
  });

  test('buildRecords sorts newest first', () {
    final rows = buildRecords(RecordKind.symptom,
        symptoms: symptoms, medications: medications, body: body);
    expect(rows.first.title, '头痛');
    expect(rows.last.title, '恶心');
  });

  test('buildRecords joins medication dosage and note', () {
    final rows = buildRecords(RecordKind.medication,
        symptoms: symptoms, medications: medications, body: body);
    expect(rows.single.title, '布洛芬');
    expect(rows.single.subtitle, '1 片 · 饭后');
  });

  test('buildRecords vital picks only records with measurements', () {
    final rows = buildRecords(RecordKind.vital,
        symptoms: symptoms, medications: medications, body: body);
    expect(rows, hasLength(2));
    expect(rows.first.title, contains('体温'));
    expect(rows.first.title, contains('38.2'));
    expect(rows.last.title, contains('体重'));
  });

  test('buildRecords score picks only records with score fields', () {
    final rows = buildRecords(RecordKind.score,
        symptoms: symptoms, medications: medications, body: body);
    expect(rows, hasLength(1));
    expect(rows.single.title, contains('疼痛 3'));
    expect(rows.single.subtitle, '还行');
  });

  test('filterByDays keeps only records within the window', () {
    final now = DateTime.parse('2026-07-06T23:00:00');
    final rows = buildRecords(RecordKind.symptom,
        symptoms: symptoms, medications: medications, body: body);
    expect(filterByDays(rows, 7, now: now), hasLength(1));
    expect(filterByDays(rows, 90, now: now), hasLength(2));
    expect(filterByDays(rows, null, now: now), hasLength(2));
  });

  test('filterByRange respects inclusive day bounds', () {
    final rows = buildRecords(RecordKind.symptom,
        symptoms: symptoms, medications: medications, body: body);
    final only6 = filterByRange(
      rows,
      DateTime(2026, 6, 1),
      DateTime(2026, 6, 1),
    );
    expect(only6, hasLength(1));
    expect(only6.single.title, '恶心');
  });

  test('searchRecords matches title and subtitle case-insensitively', () {
    final rows = buildRecords(RecordKind.symptom,
        symptoms: symptoms, medications: medications, body: body);
    expect(searchRecords(rows, '头痛'), hasLength(1));
    expect(searchRecords(rows, '加重'), hasLength(1));
    expect(searchRecords(rows, ''), hasLength(2));
    expect(searchRecords(rows, '不存在'), isEmpty);
  });

  test('groupByDay returns day keys newest first', () {
    final rows = buildRecords(RecordKind.symptom,
        symptoms: symptoms, medications: medications, body: body);
    final groups = groupByDay(rows);
    expect(groups.keys.first, '2026-07-06');
    expect(groups.keys.last, '2026-06-01');
  });
}
