import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../routine/provider/routine_provider.dart';
import '../../routine/screens/routine_form_screen.dart';
import '../../routine/screens/workout_history_screen.dart';

import '../../currency/provider/currency_provider.dart';
import '../../../data/models/routine_model.dart';
import '../../step/step_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RoutineProvider>().loadRoutines();
      context.read<StepProvider>().init();
      context.read<CurrencyProvider>().load();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('운동', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: false,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '루틴'),
            Tab(text: '걸음수'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _RoutineTab(),
          _StepTab(),
        ],
      ),
      floatingActionButton: ListenableBuilder(
        listenable: _tabController,
        builder: (context, _) {
          // 루틴 탭일 때만 FAB 표시
          if (_tabController.index != 0) return const SizedBox.shrink();
          return FloatingActionButton(
            onPressed: () async {
              context.read<RoutineProvider>().clearSelected();
              await Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const RoutineFormScreen()),
              );
              context.read<RoutineProvider>().loadRoutines();
            },
            child: const Icon(Icons.add),
          );
        },
      ),
    );
  }
}

// ── 루틴 탭 ──
class _RoutineTab extends StatelessWidget {
  const _RoutineTab();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<RoutineProvider>();

    return provider.isLoading
        ? const Center(child: CircularProgressIndicator())
        : provider.routines.isEmpty
        ? _buildEmpty(context)
        : _buildList(context, provider.routines);
  }

  Widget _buildEmpty(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.fitness_center, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          const Text('루틴을 추가해주세요',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('나만의 완벽한 운동 루틴을 만들어보세요.',
              style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildList(BuildContext context, List<RoutineModel> routines) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      children: [
        // 전체 기록 보기 버튼
        GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => const WorkoutHistoryScreen()),
          ),
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.blue.withOpacity(0.2)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                )
              ],
            ),
            child: const Row(
              children: [
                Icon(Icons.history_rounded, color: Colors.blue, size: 20),
                SizedBox(width: 10),
                Text('전체 운동 기록 보기',
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.blue)),
                Spacer(),
                Icon(Icons.chevron_right, color: Colors.blue, size: 20),
              ],
            ),
          ),
        ),
        // 루틴 목록
        ...routines.map((routine) => _RoutineCard(routine: routine)),
      ],
    );
  }
}

// ── 걸음수 탭 ──
class _StepTab extends StatelessWidget {
  const _StepTab();

  @override
  Widget build(BuildContext context) {
    final step = context.watch<StepProvider>();
    final currency = context.watch<CurrencyProvider>();

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const SizedBox(height: 20),

          // 걸음 수 카드
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                const Text('오늘 걸음 수',
                    style: TextStyle(fontSize: 14, color: Colors.grey)),
                const SizedBox(height: 8),
                Text(
                  _formatSteps(step.todaySteps),
                  style: const TextStyle(
                      fontSize: 52,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF42A5F5)),
                ),
                const Text('보',
                    style: TextStyle(fontSize: 16, color: Colors.grey)),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // 코인 정보 카드
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('받을 수 있는 코인',
                        style: TextStyle(fontSize: 14, color: Colors.grey)),
                    Row(children: [
                      const Text('👟',
                          style: TextStyle(fontSize: 16)),
                      const SizedBox(width: 4),
                      Text(
                        '${step.claimableCoins}개',
                        style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF42A5F5)),
                      ),
                    ]),
                  ],
                ),
                const SizedBox(height: 12),
                // 하루 캡 진행 바
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('오늘 신발코인',
                            style:
                            TextStyle(fontSize: 12, color: Colors.grey)),
                        Text(
                          '${currency.todayShoeCoin} / ${currency.dailyCap}개',
                          style: const TextStyle(
                              fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: currency.dailyCap > 0
                            ? currency.todayShoeCoin / currency.dailyCap
                            : 0,
                        minHeight: 8,
                        backgroundColor: Colors.grey.withOpacity(0.15),
                        valueColor: const AlwaysStoppedAnimation(
                            Color(0xFF42A5F5)),
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      '운동 + 걸음수 합산',
                      style: TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 28),

          // 보상받기 버튼
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: step.canClaim && !step.isLoading
                  ? () => _onClaim(context, step, currency)
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF42A5F5),
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.grey.withOpacity(0.2),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              child: step.isLoading
                  ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white),
              )
                  : Text(
                step.canClaim
                    ? '👟 신발코인 ${step.claimableCoins}개 받기'
                    : '1,000보 이상 걸으면 받을 수 있어요',
                style: const TextStyle(
                    fontSize: 15, fontWeight: FontWeight.bold),
              ),
            ),
          ),

          if (step.error != null) ...[
            const SizedBox(height: 12),
            Text(step.error!,
                style:
                const TextStyle(fontSize: 12, color: Colors.red)),
          ],
        ],
      ),
    );
  }

  String _formatSteps(int steps) {
    if (steps >= 10000) {
      return '${(steps / 10000).toStringAsFixed(1)}만';
    }
    return steps.toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');
  }

  Future<void> _onClaim(
      BuildContext context, StepProvider step, CurrencyProvider currency) async {
    final result = await step.claimReward();
    if (!context.mounted) return;

    if (result != null && result.success) {
      currency.load(); // 코인 즉시 갱신
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('👟 신발코인 ${result.grantedCoins}개를 받았어요!'),
        backgroundColor: const Color(0xFF42A5F5),
        behavior: SnackBarBehavior.floating,
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        duration: const Duration(seconds: 2),
      ));
    }
  }
}

// ── 루틴 카드 ──
class _RoutineCard extends StatelessWidget {
  final RoutineModel routine;
  const _RoutineCard({required this.routine});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        title: Text(routine.name,
            style: const TextStyle(
                fontWeight: FontWeight.bold, fontSize: 16)),
        subtitle: Text('${routine.exerciseCount}개의 운동',
            style: const TextStyle(color: Colors.grey)),
        onTap: () => context.push('/routine/${routine.id}', extra: routine),
        trailing: PopupMenuButton(
          itemBuilder: (_) => [
            const PopupMenuItem(value: 'edit', child: Text('수정')),
            const PopupMenuItem(
              value: 'delete',
              child: Text('삭제', style: TextStyle(color: Colors.red)),
            ),
          ],
          onSelected: (value) async {
            if (value == 'edit') {
              context.read<RoutineProvider>().setSelectedFromRoutine(routine);
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => RoutineFormScreen(routine: routine),
                ),
              );
              context.read<RoutineProvider>().loadRoutines();
            } else if (value == 'delete') {
              _showDeleteDialog(context);
            }
          },
        ),
      ),
    );
  }

  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('루틴 삭제'),
        content: const Text('삭제된 루틴은 복구할 수 없습니다.\n정말 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<RoutineProvider>().deleteRoutine(routine.id);
            },
            child:
            const Text('삭제', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}