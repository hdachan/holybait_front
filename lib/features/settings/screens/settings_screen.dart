import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../auth/provider/auth_provider.dart';
import '../../../core/widgets/app_background.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationEnabled = true;
  String _appVersion = '';

  @override
  void initState() {
    super.initState();
    _loadAppVersion();
  }

  Future<void> _loadAppVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      if (mounted) setState(() => _appVersion = info.version);
    } catch (_) {
      if (mounted) setState(() => _appVersion = '1.0.0');
    }
  }

  Future<void> _openLink(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('링크를 열 수 없습니다.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;
    final marketingAgreed = auth.marketingAgreed;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: const Color(0xFF160d1f),
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text('설정',
            style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: Colors.white)),
        centerTitle: true,
      ),
      body: AppBackground(
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 8),
          children: [
            // ── 계정 정보 ──
            _SectionHeader(title: '계정 정보'),
            _Card(children: [
              _InfoTile(label: '닉네임', value: user?.nickname ?? '-'),
              _InfoTile(label: '이메일', value: user?.email ?? '-'),
              _InfoTile(label: '로그인 방식', value: user?.provider ?? '-'),
              _InfoTile(label: '가입일', value: _formatDate(user?.createdAt)),
            ]),

            // ── 계정 ──
            _SectionHeader(title: '계정'),
            _Card(children: [
              _ActionTile(
                icon: Icons.person_outline,
                label: '프로필 수정',
                onTap: () => _showEditNicknameDialog(context),
              ),
              _SwitchTile(
                icon: Icons.notifications_outlined,
                label: '알림 받기',
                value: _notificationEnabled,
                onChanged: (v) => setState(() => _notificationEnabled = v),
              ),
              _SwitchTile(
                icon: Icons.campaign_outlined,
                label: '마케팅 정보 수신',
                value: marketingAgreed,
                onChanged: (v) async {
                  await auth.updateMarketingConsent(v);
                },
              ),
            ]),

            // ── 개인정보 ──
            _SectionHeader(title: '개인정보'),
            _Card(children: [
              _ActionTile(
                icon: Icons.privacy_tip_outlined,
                label: '개인정보 처리방침',
                onTap: () => _openLink('https://aquamarine-armchair-686.notion.site/HolyHabit-3a7d8a6d4321801dbb54d54e902323a3'),
              ),
              _ActionTile(
                icon: Icons.description_outlined,
                label: '이용약관',
                onTap: () => _openLink('https://aquamarine-armchair-686.notion.site/HolyHabit-3a7d8a6d432180d5b335f42bafa9b543'),
              ),
            ]),

            // ── 고객 지원 ──
            _SectionHeader(title: '고객 지원'),
            _Card(children: [
              _ActionTile(
                icon: Icons.help_outline,
                label: 'FAQ',
                onTap: () => _openLink('https://example.com/faq'),
              ),
              _ActionTile(
                icon: Icons.bug_report_outlined,
                label: '문의하기 / 버그 제보',
                onTap: () => _openLink('https://example.com/contact'),
              ),
              _ActionTile(
                icon: Icons.feedback_outlined,
                label: '의견 보내기',
                onTap: () => _openLink('https://example.com/feedback'),
              ),
            ]),

            // ── 앱 정보 ──
            _SectionHeader(title: '앱 정보'),
            _Card(children: [
              _InfoTile(
                  label: '앱 버전',
                  value: _appVersion.isEmpty ? '-' : _appVersion),
              _ActionTile(
                icon: Icons.history,
                label: '업데이트 내역',
                onTap: () => _showUpdateHistory(context),
              ),
            ]),

            // ── 계정 관리 ──
            _SectionHeader(title: '계정 관리'),
            _Card(children: [
              ListTile(
                leading: const Icon(Icons.logout,
                    color: Color(0xFFF4A259)),
                title: const Text('로그아웃',
                    style: TextStyle(color: Colors.white)),
                onTap: () => _showLogoutDialog(context),
              ),
              ListTile(
                leading: const Icon(Icons.person_remove,
                    color: Colors.redAccent),
                title: const Text('회원 탈퇴',
                    style: TextStyle(color: Colors.redAccent)),
                onTap: () => _showWithdrawDialog(context),
              ),
            ]),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  void _showEditNicknameDialog(BuildContext context) {
    final auth = context.read<AuthProvider>();
    final controller = TextEditingController(text: auth.user?.nickname ?? '');
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF1E1225),
          title: const Text('프로필 수정',
              style: TextStyle(color: Colors.white)),
          content: TextField(
            controller: controller,
            maxLength: 12,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: '닉네임',
              labelStyle: TextStyle(color: Colors.white.withOpacity(0.6)),
              hintText: '2~12자로 입력해주세요',
              hintStyle:
              TextStyle(color: Colors.white.withOpacity(0.3)),
              filled: true,
              fillColor: Colors.white.withOpacity(0.07),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
            ),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: isSaving
                  ? null
                  : () => Navigator.pop(dialogContext),
              child: Text('취소',
                  style:
                  TextStyle(color: Colors.white.withOpacity(0.5))),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFF4A259),
                  foregroundColor: Colors.black),
              onPressed: isSaving
                  ? null
                  : () async {
                final nickname = controller.text.trim();
                if (nickname.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('닉네임을 입력해주세요.')),
                  );
                  return;
                }
                setDialogState(() => isSaving = true);
                final success =
                await auth.updateNickname(nickname);
                setDialogState(() => isSaving = false);
                if (!dialogContext.mounted) return;
                Navigator.pop(dialogContext);
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(success
                        ? '닉네임이 변경되었습니다.'
                        : (auth.errorMessage ??
                        '닉네임 변경에 실패했습니다.')),
                    backgroundColor: success
                        ? const Color(0xFF4CAF50)
                        : Colors.red,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    margin:
                    const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  ),
                );
              },
              child: isSaving
                  ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.black))
                  : const Text('저장'),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '-';
    try {
      final dt = DateTime.parse(dateStr);
      return '${dt.year}.${dt.month.toString().padLeft(2, '0')}.${dt.day.toString().padLeft(2, '0')}';
    } catch (_) {
      return '-';
    }
  }

  void _showUpdateHistory(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1E1225),
        title: const Text('업데이트 내역',
            style: TextStyle(color: Colors.white)),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _UpdateHistoryItem(version: 'v1.0.0', note: '첫 출시'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('닫기',
                style: TextStyle(color: Color(0xFFF4A259))),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1E1225),
        title: const Text('로그아웃',
            style: TextStyle(color: Colors.white)),
        content: const Text('로그아웃 하시겠습니까?',
            style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('취소',
                style:
                TextStyle(color: Colors.white.withOpacity(0.5))),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await context.read<AuthProvider>().logout();
              if (context.mounted) context.go('/login');
            },
            child: const Text('로그아웃',
                style: TextStyle(color: Color(0xFFF4A259))),
          ),
        ],
      ),
    );
  }

  void _showWithdrawDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1E1225),
        title: const Text('회원 탈퇴',
            style: TextStyle(color: Colors.white)),
        content: const Text('탈퇴하면 모든 데이터가 삭제됩니다.\n정말 탈퇴하시겠습니까?',
            style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('취소',
                style:
                TextStyle(color: Colors.white.withOpacity(0.5))),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await context.read<AuthProvider>().withdraw();
              if (context.mounted) context.go('/login');
            },
            child: const Text('탈퇴',
                style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }
}

// ── 섹션 헤더 ──
class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: Colors.white.withOpacity(0.4),
        ),
      ),
    );
  }
}

// ── 카드 컨테이너 ──
class _Card extends StatelessWidget {
  final List<Widget> children;
  const _Card({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1225),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Column(
        children: List.generate(children.length * 2 - 1, (i) {
          if (i.isEven) return children[i ~/ 2];
          return Divider(
              height: 1,
              indent: 16,
              endIndent: 16,
              color: Colors.white.withOpacity(0.06));
        }),
      ),
    );
  }
}

// ── 정보 표시 ──
class _InfoTile extends StatelessWidget {
  final String label;
  final String value;
  const _InfoTile({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(label,
          style: TextStyle(
              fontSize: 14, color: Colors.white.withOpacity(0.4))),
      trailing: Text(value,
          style: const TextStyle(fontSize: 14, color: Colors.white)),
    );
  }
}

// ── 탭하면 이동/실행 ──
class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: Colors.white.withOpacity(0.5), size: 22),
      title: Text(label,
          style: const TextStyle(fontSize: 14, color: Colors.white)),
      trailing: Icon(Icons.chevron_right,
          color: Colors.white.withOpacity(0.3), size: 20),
      onTap: onTap,
    );
  }
}

// ── 토글 스위치 ──
class _SwitchTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SwitchTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: Colors.white.withOpacity(0.5), size: 22),
      title: Text(label,
          style: const TextStyle(fontSize: 14, color: Colors.white)),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: const Color(0xFFF4A259),
      ),
      onTap: () => onChanged(!value),
    );
  }
}

// ── 업데이트 내역 항목 ──
class _UpdateHistoryItem extends StatelessWidget {
  final String version;
  final String note;
  const _UpdateHistoryItem({required this.version, required this.note});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(version,
              style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Colors.white)),
          const SizedBox(height: 2),
          Text(note,
              style: TextStyle(
                  fontSize: 13, color: Colors.white.withOpacity(0.4))),
        ],
      ),
    );
  }
}