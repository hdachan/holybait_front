import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../routine/provider/routine_provider.dart';
import '../../routine/screens/routine_form_screen.dart';
import '../../routine/screens/workout_history_screen.dart';
import '../../currency/provider/currency_provider.dart';
import '../../../data/models/routine_model.dart';
import '../../step/step_provider.dart';
import '../../../core/widgets/app_background.dart';

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
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: const Color(0xFF160d1f),
        elevation: 0,
        title: const Text('운동',
            style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontSize: 18)),
        centerTitle: false,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFFF4A259),
          indicatorWeight: 2,
          labelColor: const Color(0xFFF4A259),
          unselectedLabelColor: Colors.white38,
          labelStyle: const TextStyle(
              fontWeight: FontWeight.bold, fontSize: 14),
          tabs: const [
            Tab(text: '루틴'),
            Tab(text: '걸음수'),
          ],
        ),
      ),
      body: AppBackground(
        child: TabBarView(
          controller: _tabController,
          children: const [
            _RoutineTab(),
            _StepTab(),
          ],
        ),
      ),
      floatingActionButton: ListenableBuilder(
        listenable: _tabController,
        builder: (context, _) {
          if (_tabController.index != 0) return const SizedBox.shrink();
          return FloatingActionButton(
            backgroundColor: const Color(0xFFF4A259),
            foregroundColor: Colors.black,
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
        ? const Center(
        child: CircularProgressIndicator(color: Colors.white))
        : provider.routines.isEmpty
        ? _buildEmpty(context)
        : _buildList(context, provider.routines);
  }

  Widget _buildEmpty(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.fitness_center,
              size: 64, color: Colors.white.withOpacity(0.3)),
          const SizedBox(height: 16),
          const Text('루틴을 추가해주세요',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white)),
          const SizedBox(height: 8),
          Text('나만의 완벽한 운동 루틴을 만들어보세요.',
              style: TextStyle(color: Colors.white.withOpacity(0.5))),
        ],
      ),
    );
  }

  Widget _buildList(BuildContext context, List<RoutineModel> routines) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
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
              color: Colors.white.withOpacity(0.06),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                  color: const Color(0xFFF4A259).withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.history_rounded,
                    color: const Color(0xFFF4A259), size: 20),
                const SizedBox(width: 10),
                const Text('전체 운동 기록 보기',
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFF4A259))),
                const Spacer(),
                Icon(Icons.chevron_right,
                    color: const Color(0xFFF4A259).withOpacity(0.7),
                    size: 20),
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
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Column(
        children: [
          const SizedBox(height: 20),

          // 걸음 수 카드
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
                vertical: 36, horizontal: 24),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.06),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: Colors.white.withOpacity(0.08)),
            ),
            child: Column(
              children: [
                Text('오늘 걸음 수',
                    style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.5))),
                const SizedBox(height: 8),
                Text(
                  _formatSteps(step.todaySteps),
                  style: const TextStyle(
                      fontSize: 52,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF42A5F5)),
                ),
                Text('보',
                    style: TextStyle(
                        fontSize: 16,
                        color: Colors.white.withOpacity(0.5))),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // 코인 정보 카드
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.06),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color: Colors.white.withOpacity(0.08)),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('받을 수 있는 코인',
                        style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withOpacity(0.5))),
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
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment:
                      MainAxisAlignment.spaceBetween,
                      children: [
                        Text('오늘 신발코인',
                            style: TextStyle(
                                fontSize: 12,
                                color: Colors.white.withOpacity(0.4))),
                        Text(
                          '${currency.todayShoeCoin} / ${currency.dailyCap}개',
                          style: TextStyle(
                              fontSize: 12,
                              color: Colors.white.withOpacity(0.4)),
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
                        backgroundColor:
                        Colors.white.withOpacity(0.1),
                        valueColor: const AlwaysStoppedAnimation(
                            Color(0xFF42A5F5)),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text('운동 + 걸음수 합산',
                        style: TextStyle(
                            fontSize: 11,
                            color: Colors.white.withOpacity(0.3))),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

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
                disabledBackgroundColor:
                Colors.white.withOpacity(0.1),
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
                    fontSize: 15,
                    fontWeight: FontWeight.bold),
              ),
            ),
          ),

          if (step.error != null) ...[
            const SizedBox(height: 12),
            Text(step.error!,
                style: const TextStyle(
                    fontSize: 12, color: Colors.redAccent)),
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
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
            (m) => '${m[1]},');
  }

  Future<void> _onClaim(BuildContext context, StepProvider step,
      CurrencyProvider currency) async {
    final result = await step.claimReward();
    if (!context.mounted) return;
    if (result != null && result.success) {
      currency.load();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('👟 신발코인 ${result.grantedCoins}개를 받았어요!'),
        backgroundColor: const Color(0xFF42A5F5),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10)),
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
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1225),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: ListTile(
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: const Color(0xFF1A3A4A),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.open_in_full_rounded,
              color: Color(0xFF42A5F5), size: 20),
        ),
        title: Text(routine.name,
            style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: Colors.white)),
        subtitle: Text(routine.exerciseCount != null
            ? '${routine.exerciseCount}개의 운동' : '',
            style:
            TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12)),
        onTap: () => context.push('/routine/${routine.id}', extra: routine),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.chevron_right,
                color: Colors.white.withOpacity(0.3), size: 20),
            PopupMenuButton(
              icon: Icon(Icons.more_vert,
                  color: Colors.white.withOpacity(0.3), size: 20),
              color: const Color(0xFF1E1225),
              itemBuilder: (_) => [
                const PopupMenuItem(
                    value: 'edit',
                    child: Text('수정',
                        style: TextStyle(color: Colors.white))),
                const PopupMenuItem(
                  value: 'delete',
                  child: Text('삭제',
                      style: TextStyle(color: Colors.redAccent)),
                ),
              ],
              onSelected: (value) async {
                if (value == 'edit') {
                  context
                      .read<RoutineProvider>()
                      .setSelectedFromRoutine(routine);
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
          ],
        ),
      ),
    );
  }

  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1E1225),
        title: const Text('루틴 삭제',
            style: TextStyle(color: Colors.white)),
        content: const Text('삭제된 루틴은 복구할 수 없습니다.\n정말 삭제하시겠습니까?',
            style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소',
                style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<RoutineProvider>().deleteRoutine(routine.id);
            },
            child: const Text('삭제',
                style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }
}