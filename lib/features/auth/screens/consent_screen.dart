import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../provider/auth_provider.dart';
import '../../../core/widgets/app_background.dart';

class ConsentScreen extends StatefulWidget {
  const ConsentScreen({super.key});

  @override
  State<ConsentScreen> createState() => _ConsentScreenState();
}

class _ConsentScreenState extends State<ConsentScreen> {
  bool _termsAgreed = false;
  bool _privacyAgreed = false;
  bool _marketingAgreed = false;
  bool _isSaving = false;

  bool get _canProceed => _termsAgreed && _privacyAgreed;
  bool get _allAgreed => _termsAgreed && _privacyAgreed && _marketingAgreed;

  void _toggleAll(bool value) {
    setState(() {
      _termsAgreed = value;
      _privacyAgreed = value;
      _marketingAgreed = value;
    });
  }

  Future<void> _onConfirm() async {
    if (!_canProceed || _isSaving) return;
    setState(() => _isSaving = true);

    final auth = context.read<AuthProvider>();
    await auth.completeConsent(marketingAgreed: _marketingAgreed);

    if (mounted) context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AppBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 48),

                // 제목
                const Text('HolyHabit 시작하기',
                    style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white)),
                const SizedBox(height: 8),
                Text('아래 약관에 동의해주세요',
                    style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.5))),

                const SizedBox(height: 32),

                // 전체 동의
                GestureDetector(
                  onTap: () => _toggleAll(!_allAgreed),
                  child: Row(
                    children: [
                      _CheckCircle(checked: _allAgreed),
                      const SizedBox(width: 10),
                      const Text('전체 동의',
                          style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Colors.white)),
                    ],
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: Divider(color: Colors.white.withOpacity(0.1)),
                ),

                // 필수 - 서비스 이용약관
                _ConsentRow(
                  label: '[필수] 서비스 이용약관',
                  checked: _termsAgreed,
                  onChanged: (v) => setState(() => _termsAgreed = v),
                  onDetail: () => _openUrl(
                      'https://aquamarine-armchair-686.notion.site/HolyHabit-3a7d8a6d432180d5b335f42bafa9b543'),
                ),
                const SizedBox(height: 16),

                // 필수 - 개인정보 처리방침
                _ConsentRow(
                  label: '[필수] 개인정보 처리방침',
                  checked: _privacyAgreed,
                  onChanged: (v) => setState(() => _privacyAgreed = v),
                  onDetail: () => _openUrl(
                      'https://aquamarine-armchair-686.notion.site/HolyHabit-3a7d8a6d4321801dbb54d54e902323a3'),
                ),
                const SizedBox(height: 16),

                // 선택 - 마케팅
                _ConsentRow(
                  label: '[선택] 마케팅 정보 수신',
                  checked: _marketingAgreed,
                  onChanged: (v) => setState(() => _marketingAgreed = v),
                  onDetail: () => _openUrl(
                      'https://aquamarine-armchair-686.notion.site/HolyHabit-3a7d8a6d432180c085a8dfde536e3295'),
                ),

                const Spacer(),

                // 동의하고 시작하기 버튼
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _canProceed && !_isSaving ? _onConfirm : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF4A259),
                      foregroundColor: Colors.black,
                      disabledBackgroundColor:
                      Colors.white.withOpacity(0.1),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                    child: _isSaving
                        ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.black))
                        : const Text('동의하고 시작하기',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 12),
                Center(
                  child: Text(
                    '필수 항목에 동의해야 서비스를 이용할 수 있어요',
                    style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withOpacity(0.3)),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openUrl(String url) async {
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
}

// ── 동의 항목 행 ──
class _ConsentRow extends StatelessWidget {
  final String label;
  final bool checked;
  final ValueChanged<bool> onChanged;
  final VoidCallback onDetail;

  const _ConsentRow({
    required this.label,
    required this.checked,
    required this.onChanged,
    required this.onDetail,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        GestureDetector(
          onTap: () => onChanged(!checked),
          child: _CheckCircle(checked: checked),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: GestureDetector(
            onTap: () => onChanged(!checked),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: checked
                    ? Colors.white
                    : Colors.white.withOpacity(0.5),
              ),
            ),
          ),
        ),
        GestureDetector(
          onTap: onDetail,
          child: Text(
            '보기',
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withOpacity(0.3),
              decoration: TextDecoration.underline,
              decorationColor: Colors.white.withOpacity(0.3),
            ),
          ),
        ),
      ],
    );
  }
}

// ── 체크 원 ──
class _CheckCircle extends StatelessWidget {
  final bool checked;
  const _CheckCircle({required this.checked});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: checked ? const Color(0xFFF4A259) : Colors.transparent,
        border: Border.all(
          color: checked
              ? const Color(0xFFF4A259)
              : Colors.white.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: checked
          ? const Icon(Icons.check, size: 13, color: Colors.black)
          : null,
    );
  }
}