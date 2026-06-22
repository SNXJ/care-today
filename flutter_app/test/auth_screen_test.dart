import 'package:care_today_mobile/core/secure_token_store.dart';
import 'package:care_today_mobile/data/care_api.dart';
import 'package:care_today_mobile/features/session/session_controller.dart';
import 'package:care_today_mobile/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

class FakeTokenStore extends SecureTokenStore {
  const FakeTokenStore();
  @override
  Future<String?> read() async => null;
  @override
  Future<void> write(String value) async {}
  @override
  Future<void> delete() async {}
}

void main() {
  testWidgets(
      'Given login screen, when register link is tapped, then nickname field appears',
      (tester) async {
    tester.view.physicalSize = const Size(1000, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final session = SessionController(CareApi(), const FakeTokenStore());
    await session.boot();
    await tester.pumpWidget(ChangeNotifierProvider.value(
        value: session, child: const MaterialApp(home: AuthScreen())));

    expect(find.text('登录陪伴空间'), findsOneWidget);
    await tester.tap(find.text('第一次来，去注册'));
    await tester.pump();

    expect(find.text('创建一个账号'), findsOneWidget);
    expect(find.widgetWithText(TextField, '昵称'), findsOneWidget);
  });
}
