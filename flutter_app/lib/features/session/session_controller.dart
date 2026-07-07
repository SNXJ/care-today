import 'package:flutter/foundation.dart';
import '../../core/secure_token_store.dart';
import '../../data/care_api.dart';

class SessionController extends ChangeNotifier {
  SessionController(this.api, this.store);
  final CareApi api;
  final SecureTokenStore store;
  bool ready = false, busy = false;
  Map<String, dynamic>? user, space;
  String currentRole = '';
  List<dynamic> spaces = [],
      members = [],
      events = [],
      body = [],
      questions = [],
      messages = [],
      symptoms = [],
      medications = [],
      notices = [],
      notes = [];
  bool get authenticated => api.token != null;
  bool get hasSpace => space != null;
  bool get isPatient => currentRole == 'PATIENT_ADMIN';
  String get spaceId => space!['id'].toString();

  Future<void> boot() async {
    if (ready) return;
    api.token = await store.read();
    if (api.token != null) {
      try {
        await loadSpaces();
      } on ApiException catch (error) {
        if (error.statusCode == 401) await logout();
      }
    }
    ready = true;
    notifyListeners();
  }

  Future<void> authenticate(
      {required bool register,
      required String account,
      required String password,
      String nickname = ''}) async {
    await _run(() async {
      final isEmail = account.contains('@');
      final payload = {
        'email': isEmail ? account : null,
        'phone': isEmail ? null : account,
        'password': password,
        if (register) 'nickname': nickname
      };
      final result =
          register ? await api.register(payload) : await api.login(payload);
      api.token = result['token'] as String;
      user = Map<String, dynamic>.from(result['user']);
      await store.write(api.token!);
      await loadSpaces();
    });
  }

  Future<void> loadSpaces() async {
    spaces = await api.list('/spaces');
    if (spaces.isNotEmpty) await selectSpace(spaces.first['id'].toString());
  }

  Future<void> createSpaceWithApi(
      String name, String patientNickname, String description) async {
    await _run(() async {
      final result = Map<String, dynamic>.from(
          await api.request('/spaces', method: 'POST', body: {
        'name': name,
        'patientNickname': patientNickname,
        if (description.isNotEmpty) 'description': description
      }));
      spaces = await api.list('/spaces');
      await selectSpace(result['id'].toString());
    });
  }

  Future<void> selectSpace(String id) async {
    final detail = await api.object('/spaces/$id');
    space = Map<String, dynamic>.from(detail['space']);
    members = List<dynamic>.from(detail['members'] ?? const []);
    currentRole = detail['currentRole']?.toString() ?? '';
    final results = await Future.wait([
      api.list('/spaces/$id/events'),
      api.list('/spaces/$id/body-records'),
      api.list('/spaces/$id/doctor-questions'),
      api.list('/spaces/$id/messages'),
      api.list('/spaces/$id/symptoms'),
      api.list('/spaces/$id/notices'),
      api.list('/spaces/$id/notes'),
      api.list('/spaces/$id/medications')
    ]);
    events = results[0];
    body = results[1];
    questions = results[2];
    messages = results[3];
    symptoms = results[4];
    notices = results[5];
    notes = results[6];
    medications = results[7];
    notifyListeners();
  }

  Future<void> refresh() async {
    if (space != null) await selectSpace(spaceId);
  }

  // —— 各集合的独立重载，避免每次改动都全量刷新 ——
  Future<void> reloadEvents() async {
    events = await api.list('/spaces/$spaceId/events');
    notifyListeners();
  }

  Future<void> reloadBody() async {
    body = await api.list('/spaces/$spaceId/body-records');
    notifyListeners();
  }

  Future<void> reloadQuestions() async {
    questions = await api.list('/spaces/$spaceId/doctor-questions');
    notifyListeners();
  }

  Future<void> reloadMessages() async {
    messages = await api.list('/spaces/$spaceId/messages');
    notifyListeners();
  }

  Future<void> reloadSymptoms() async {
    symptoms = await api.list('/spaces/$spaceId/symptoms');
    notifyListeners();
  }

  Future<void> reloadMedications() async {
    medications = await api.list('/spaces/$spaceId/medications');
    notifyListeners();
  }

  Future<void> reloadNotices() async {
    notices = await api.list('/spaces/$spaceId/notices');
    notifyListeners();
  }

  Future<void> reloadNotes() async {
    notes = await api.list('/spaces/$spaceId/notes');
    notifyListeners();
  }

  Future<void> reloadMembers() async {
    final detail = await api.object('/spaces/$spaceId');
    members = List<dynamic>.from(detail['members'] ?? const []);
    notifyListeners();
  }

  Future<void> leaveSpace() async {
    await api.request('/spaces/$spaceId/leave', method: 'DELETE');
    space = null;
    await loadSpaces();
    notifyListeners();
  }

  Future<void> deleteAccount() async {
    await api.request('/account', method: 'DELETE');
    await logout();
  }

  Future<void> logout() async {
    await store.delete();
    api.token = null;
    user = null;
    space = null;
    spaces = [];
    members = [];
    events = [];
    body = [];
    questions = [];
    messages = [];
    symptoms = [];
    medications = [];
    notices = [];
    notes = [];
    currentRole = '';
    notifyListeners();
  }

  Future<void> _run(Future<void> Function() action) async {
    busy = true;
    notifyListeners();
    try {
      await action();
    } finally {
      busy = false;
      notifyListeners();
    }
  }
}
