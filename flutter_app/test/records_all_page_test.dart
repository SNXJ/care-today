import 'package:care_today_mobile/core/secure_token_store.dart';
import 'package:care_today_mobile/data/care_api.dart';
import 'package:care_today_mobile/features/home/records_all_page.dart';
import 'package:care_today_mobile/features/home/records_filter.dart';
import 'package:care_today_mobile/features/session/session_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

SessionController _session() {
  final s = SessionController(CareApi(), const SecureTokenStore());
  final now = DateTime.now();
  String iso(int daysAgo, int hour) =>
      now.subtract(Duration(days: daysAgo)).copyWith(hour: hour).toIso8601String();
  // 同一天多条 + 长备注，用来压边界
  s.body = [
    {'id': 'b1', 'temperature': 38.5, 'note': '寒战', 'createdAt': iso(0, 19)},
    {'id': 'b2', 'temperature': 37.8, 'note': '', 'createdAt': iso(0, 14)},
    {'id': 'b3', 'weight': 57.5, 'note': '', 'createdAt': iso(0, 9)},
    {'id': 'b4', 'temperature': 39.0, 'note': '很不舒服，晚上睡不着，出了很多汗', 'createdAt': iso(1, 21)},
    {'id': 'b5', 'painScore': 3, 'note': '还行', 'createdAt': iso(2, 8)},
    {'id': 'b6', 'temperature': 37.3, 'note': '', 'createdAt': iso(80, 10)},
  ];
  s.symptoms = [
    {'id': 's1', 'tag': '头痛', 'note': '下午加重', 'happenedAt': iso(0, 15)},
    {'id': 's2', 'tag': '恶心', 'note': '', 'happenedAt': iso(3, 20)},
  ];
  s.medications = [
    {'id': 'm1', 'name': '布洛芬', 'dosage': '1 片', 'note': '饭后', 'takenAt': iso(0, 12)},
  ];
  return s;
}

Widget _wrap(SessionController s, {RecordKind kind = RecordKind.vital}) {
  return ChangeNotifierProvider<SessionController>.value(
    value: s,
    child: MaterialApp(home: RecordsAllPage(initialKind: kind)),
  );
}

void main() {
  testWidgets('renders without overflow on a narrow phone', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_wrap(_session()));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('全部记录'), findsOneWidget);
  });

  testWidgets('all four category segments are laid out on screen',
      (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_wrap(_session()));
    await tester.pumpAndSettle();

    final screenWidth = tester.view.physicalSize.width / tester.view.devicePixelRatio;
    for (final label in ['症状', '用药', '体征', '评分']) {
      final finder = find.text(label);
      expect(finder, findsOneWidget, reason: '$label 分段缺失');
      // 分段必须完整落在屏幕内（旧版横向滚动会把最后一项切掉）
      final box = tester.getRect(finder);
      expect(box.left, greaterThanOrEqualTo(0.0), reason: '$label 左侧被切');
      expect(box.right, lessThanOrEqualTo(screenWidth), reason: '$label 右侧被切');
    }
  });

  testWidgets('date-range button is fully visible, not clipped', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_wrap(_session()));
    await tester.pumpAndSettle();

    final screenWidth = tester.view.physicalSize.width / tester.view.devicePixelRatio;
    final icon = find.byIcon(Icons.date_range_rounded);
    expect(icon, findsOneWidget);
    final box = tester.getRect(icon);
    expect(box.right, lessThanOrEqualTo(screenWidth), reason: '日历按钮被切掉');
    expect(box.left, greaterThanOrEqualTo(0.0));
  });

  testWidgets('switching category re-filters the list', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_wrap(_session()));
    await tester.pumpAndSettle();
    expect(find.textContaining('体温 38.5'), findsOneWidget);

    await tester.tap(find.text('症状'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('头痛'), findsOneWidget);
    expect(find.textContaining('体温 38.5'), findsNothing);
  });

  testWidgets('default range is 30 days and excludes older records',
      (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_wrap(_session()));
    await tester.pumpAndSettle();

    // 80 天前那条应被默认的 30 天过滤掉，计数行显示筛选比例
    expect(find.textContaining('筛选出'), findsOneWidget);
    expect(find.textContaining('体温 37.3'), findsNothing);

    await tester.tap(find.text('全部'));
    await tester.pumpAndSettle();
    expect(find.textContaining('体温 37.3'), findsOneWidget);
  });
}
