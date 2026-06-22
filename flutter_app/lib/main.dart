import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/secure_token_store.dart';
import 'core/ui.dart';
import 'data/care_api.dart';
import 'features/session/session_controller.dart';
import 'features/home/body_view.dart';
import 'features/home/composer.dart';
import 'features/home/profile_view.dart';
import 'features/home/views.dart';
import 'features/update/update_service.dart';

void main() => runApp(ChangeNotifierProvider(
    create: (_) =>
        SessionController(CareApi(), const SecureTokenStore())..boot(),
    child: const CareTodayApp()));

class CareTodayApp extends StatelessWidget {
  const CareTodayApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
        debugShowCheckedModeBanner: false,
        title: '陪你一起过今天',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
              seedColor: rose, surface: const Color(0xfffffdf9)),
          scaffoldBackgroundColor: const Color(0xfffdf8f2),
          useMaterial3: true,
          fontFamily: 'PingFang SC',
          cardTheme: const CardThemeData(
              elevation: 0,
              margin: EdgeInsets.only(bottom: 16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(22)),
                  side: BorderSide(color: Color(0xffeadbca)))),
          // 统一弹窗风格：米色面板、大圆角、衬线标题，去掉原生紫色 tint
          dialogTheme: const DialogThemeData(
            backgroundColor: Color(0xfffffdf9),
            surfaceTintColor: Colors.transparent,
            elevation: 8,
            shadowColor: Color(0x22000000),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(26))),
            titleTextStyle: TextStyle(
                fontFamily: 'Songti SC',
                fontSize: 21,
                fontWeight: FontWeight.bold,
                color: ink),
            contentTextStyle: TextStyle(color: ink, height: 1.6, fontSize: 14),
          ),
          // 统一输入框：浅米填充、圆角、聚焦玫瑰描边
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: const Color(0xfffefbf6),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xffeadbca))),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xffeadbca))),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: rose, width: 1.6)),
            labelStyle: const TextStyle(color: muted),
            floatingLabelStyle: const TextStyle(color: rose),
          ),
          filledButtonTheme: FilledButtonThemeData(
            style: FilledButton.styleFrom(
                backgroundColor: rose,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 12)),
          ),
          textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(foregroundColor: muted),
          ),
          bottomSheetTheme: const BottomSheetThemeData(
            backgroundColor: Color(0xfffffdf9),
            surfaceTintColor: Colors.transparent,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
          ),
          navigationBarTheme: NavigationBarThemeData(
            backgroundColor: const Color(0xfffffdf9),
            surfaceTintColor: Colors.transparent,
            elevation: 3,
            height: 66,
            indicatorColor: const Color(0xfff7e6da),
            labelTextStyle: WidgetStateProperty.resolveWith((states) =>
                TextStyle(
                    fontSize: 11,
                    fontWeight:
                        states.contains(WidgetState.selected)
                            ? FontWeight.w700
                            : FontWeight.w500,
                    color:
                        states.contains(WidgetState.selected) ? rose : muted)),
            iconTheme: WidgetStateProperty.resolveWith((states) =>
                IconThemeData(
                    size: 24,
                    color:
                        states.contains(WidgetState.selected) ? rose : muted)),
          ),
        ),
        home: const RootScreen(),
      );
}

class RootScreen extends StatelessWidget {
  const RootScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionController>();
    if (!session.ready) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (!session.authenticated) return const AuthScreen();
    if (!session.hasSpace) return const CreateSpaceScreen();
    return const HomeShell();
  }
}

// ————————————————————————— 登录 / 注册 —————————————————————————
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});
  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final account = TextEditingController(),
      password = TextEditingController(),
      nickname = TextEditingController();
  bool register = false;

  @override
  void dispose() {
    account.dispose();
    password.dispose();
    nickname.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    final acc = account.text.trim();
    if (acc.isEmpty || password.text.isEmpty) {
      showToast(context, '请填写账号和密码');
      return;
    }
    try {
      await context.read<SessionController>().authenticate(
          register: register,
          account: acc,
          password: password.text,
          nickname: nickname.text.trim().isEmpty
              ? (acc.contains('@') ? acc.split('@').first : acc)
              : nickname.text.trim());
    } catch (e) {
      if (mounted) showError(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final busy = context.watch<SessionController>().busy;
    return Scaffold(
      body: SafeArea(
        child: ListView(padding: const EdgeInsets.all(24), children: [
          const SizedBox(height: 36),
          const Text('CARE TODAY',
              style: TextStyle(
                  color: rose, fontWeight: FontWeight.w700, letterSpacing: 2)),
          const Text('陪你一起过今天',
              style: TextStyle(
                  fontFamily: 'Songti SC',
                  fontSize: 38,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('把今天需要记住的事，放在一个温柔而清楚的地方。',
              style: TextStyle(color: muted, height: 1.7)),
          const SizedBox(height: 28),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(22),
              child: Column(children: [
                Text(register ? '创建一个账号' : '登录陪伴空间',
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 20),
                if (register) ...[
                  TextField(
                      controller: nickname,
                      decoration: const InputDecoration(
                          labelText: '昵称', border: OutlineInputBorder())),
                  const SizedBox(height: 14),
                ],
                TextField(
                    controller: account,
                    decoration: const InputDecoration(
                        labelText: '手机号或邮箱', border: OutlineInputBorder())),
                const SizedBox(height: 14),
                TextField(
                    controller: password,
                    obscureText: true,
                    decoration: const InputDecoration(
                        labelText: '密码', border: OutlineInputBorder())),
                const SizedBox(height: 20),
                FilledButton(
                    onPressed: busy ? null : submit,
                    child: Text(register ? '注册并登录' : '登录')),
                TextButton(
                    onPressed: () => setState(() => register = !register),
                    child: Text(register ? '已有账号，去登录' : '第一次来，去注册')),
              ]),
            ),
          ),
        ]),
      ),
    );
  }
}

// ————————————————————————— 创建空间 —————————————————————————
class CreateSpaceScreen extends StatefulWidget {
  const CreateSpaceScreen({super.key});
  @override
  State<CreateSpaceScreen> createState() => _CreateSpaceScreenState();
}

class _CreateSpaceScreenState extends State<CreateSpaceScreen> {
  final name = TextEditingController(text: '今天'),
      patient = TextEditingController(),
      description = TextEditingController();
  bool consent = false;

  @override
  void dispose() {
    name.dispose();
    patient.dispose();
    description.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final busy = context.watch<SessionController>().busy;
    return Scaffold(
      appBar: AppBar(title: const Text('建立陪伴空间')),
      body: ListView(padding: const EdgeInsets.all(24), children: [
        const Text('第一位成员将成为管理员。', style: TextStyle(color: muted, height: 1.6)),
        const SizedBox(height: 16),
        TextField(
            controller: name,
            decoration: const InputDecoration(
                labelText: '空间名称', border: OutlineInputBorder())),
        const SizedBox(height: 16),
        TextField(
            controller: patient,
            decoration: const InputDecoration(
                labelText: '患者昵称', border: OutlineInputBorder())),
        const SizedBox(height: 16),
        TextField(
            controller: description,
            decoration: const InputDecoration(
                labelText: '诊疗阶段备注（可选）', border: OutlineInputBorder())),
        const SizedBox(height: 8),
        CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          value: consent,
          onChanged: (v) => setState(() => consent = v ?? false),
          title: const Text('我了解这里会保存日程、身体记录、问题、分享和资料，用于就诊整理和家庭协作。',
              style: TextStyle(fontSize: 13, height: 1.5)),
        ),
        const SizedBox(height: 12),
        FilledButton(
            onPressed: (!consent || busy)
                ? null
                : () async {
                    try {
                      await context
                          .read<SessionController>()
                          .createSpaceWithApi(name.text.trim(),
                              patient.text.trim(), description.text.trim());
                    } catch (e) {
                      if (context.mounted) showError(context, e);
                    }
                  },
            child: const Text('创建空间')),
      ]),
    );
  }
}

// ————————————————————————— 主框架 —————————————————————————
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});
  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int index = 0;
  static const _labels = ['今天', '时间线', '分享', '身体', '注意'];
  static const _views = ['today', 'timeline', 'moments', 'body', 'notices'];

  @override
  void initState() {
    super.initState();
    // 进入主界面后静默检查更新（无更新/失败都不打扰）。
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) checkForUpdate(context, silent: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = context.read<SessionController>();
    return Scaffold(
      appBar: AppBar(title: Text(_labels[index]), actions: [
        IconButton(
            tooltip: '我的',
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const ProfileScreen())),
            icon: const Icon(Icons.person_outline)),
      ]),
      body: RefreshIndicator(
        onRefresh: s.refresh,
        child: const [
          TodayView(),
          TimelineView(),
          MomentsView(),
          BodyView(),
          NoticesView(),
        ][index],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (v) => setState(() => index = v),
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.wb_sunny_outlined),
              selectedIcon: Icon(Icons.wb_sunny),
              label: '今天'),
          NavigationDestination(
              icon: Icon(Icons.route_outlined),
              selectedIcon: Icon(Icons.route),
              label: '时间线'),
          NavigationDestination(
              icon: Icon(Icons.favorite_outline),
              selectedIcon: Icon(Icons.favorite),
              label: '分享'),
          NavigationDestination(
              icon: Icon(Icons.monitor_heart_outlined),
              selectedIcon: Icon(Icons.monitor_heart),
              label: '身体'),
          NavigationDestination(
              icon: Icon(Icons.notifications_none),
              selectedIcon: Icon(Icons.notifications),
              label: '注意'),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => openComposer(context, s, _views[index]),
        child: const Icon(Icons.add),
      ),
    );
  }
}
