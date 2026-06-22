import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/ui.dart';
import '../session/session_controller.dart';
import '../update/update_service.dart';
import 'actions.dart';
import 'panels.dart';

const _roleLabels = {
  'PATIENT_ADMIN': '患者/管理员',
  'FAMILY': '家属',
  'FRIEND': '朋友',
  'READONLY': '只读成员',
};
const _statusLabels = {
  'ACTIVE': '已加入',
  'PENDING': '待确认',
  'REMOVED': '已移除',
};

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final s = context.watch<SessionController>();
    return Scaffold(
      appBar: AppBar(title: const Text('我的陪伴空间')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ListTile(
              title: Text(s.space?['name']?.toString() ?? '陪伴空间',
                  style: const TextStyle(fontWeight: FontWeight.w700)),
              subtitle:
                  Text('角色：${_roleLabels[s.currentRole] ?? s.currentRole}'),
            ),
          ),
          SectionCard(
            title: '成员与权限',
            tag: '默认最小可见',
            icon: Icons.group_outlined,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('生成邀请链接，对方打开登录后自动加入。',
                    style: TextStyle(color: muted, fontSize: 13)),
                const SizedBox(height: 10),
                FilledButton.icon(
                    onPressed: () => inviteMember(context, s),
                    icon: const Icon(Icons.person_add_alt_1),
                    label: const Text('生成邀请链接并复制')),
                const SizedBox(height: 8),
                ...s.members.cast<Map>().map((m) => _memberRow(context, s, m)),
              ],
            ),
          ),
          SectionCard(
            title: '快捷入口',
            icon: Icons.dashboard_outlined,
            child: Column(children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.help_outline, color: rose),
                title: const Text('问医生清单'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => openQuestionsPanel(context),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.folder_outlined, color: sage),
                title: const Text('复诊资料夹'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => openFolderPanel(context),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.system_update_outlined, color: amber),
                title: const Text('检查更新'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => checkForUpdate(context, silent: false),
              ),
            ]),
          ),
          const Card(
            child: Padding(
              padding: EdgeInsets.all(18),
              child: Text('所有健康相关数据只用于陪伴协作。本应用不提供医疗诊断、治疗建议或用药判断。',
                  style: TextStyle(height: 1.7)),
            ),
          ),
          const SizedBox(height: 8),
          OutlinedButton(
              style: OutlinedButton.styleFrom(foregroundColor: rose),
              onPressed: () => leaveSpace(context, s),
              child: const Text('退出空间')),
          const SizedBox(height: 8),
          OutlinedButton(
              style: OutlinedButton.styleFrom(foregroundColor: rose),
              onPressed: () => deleteAccount(context, s),
              child: const Text('删除账号')),
          const SizedBox(height: 8),
          FilledButton.tonal(
              onPressed: () async {
                await s.logout();
                if (context.mounted) Navigator.pop(context);
              },
              child: const Text('退出登录')),
        ],
      ),
    );
  }

  Widget _memberRow(BuildContext context, SessionController s, Map m) {
    final role = _roleLabels[m['role']] ?? m['role'].toString();
    final status = _statusLabels[m['status']] ?? m['status'].toString();
    final pending = m['status'] == 'PENDING';
    final isAdmin = m['role'] == 'PATIENT_ADMIN';
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(m['nickname']?.toString() ?? '成员',
          style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text('$role · $status'),
      trailing: Row(mainAxisSize: MainAxisSize.min, children: [
        if (pending)
          TextButton(
              onPressed: () => acceptMember(context, s, m),
              child: const Text('确认')),
        if (!isAdmin)
          IconButton(
              icon: const Icon(Icons.person_remove_outlined, color: rose),
              onPressed: () => removeMember(context, s, m)),
      ]),
    );
  }
}
