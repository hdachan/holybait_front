import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../routine/provider/routine_provider.dart';
import '../../routine/screens/routine_form_screen.dart';
import '../../routine/screens/routine_detail_screen.dart';
import '../../../data/models/routine_model.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RoutineProvider>().loadRoutines();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<RoutineProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('루틴', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: false,
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : provider.routines.isEmpty
              ? _buildEmpty()
              : _buildList(provider.routines),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          provider.clearSelected();
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const RoutineFormScreen()),
          );
          provider.loadRoutines();
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildEmpty() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.fitness_center, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text('루틴을 추가해주세요',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          SizedBox(height: 8),
          Text('나만의 완벽한 운동 루틴을 만들어보세요.',
              style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildList(List<RoutineModel> routines) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: routines.length,
      itemBuilder: (_, i) => _RoutineCard(routine: routines[i]),
    );
  }
}

class _RoutineCard extends StatelessWidget {
  final RoutineModel routine;
  const _RoutineCard({required this.routine});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        title: Text(routine.name,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
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
            child: const Text('삭제', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
