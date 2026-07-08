import 'package:flutter/material.dart';
import '../../../data/repositories/routine_repository.dart';
import 'workout_history_detail_screen.dart';

class WorkoutHistoryScreen extends StatefulWidget {
  const WorkoutHistoryScreen({super.key});

  @override
  State<WorkoutHistoryScreen> createState() => _WorkoutHistoryScreenState();
}

class _WorkoutHistoryScreenState extends State<WorkoutHistoryScreen> {
  final _repository = RoutineRepository();
  List<WorkoutHistoryModel> _exercises = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      _exercises = await _repository.getExerciseHistory();
    } catch (_) {
      _exercises = [];
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F1FA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('운동 기록',
            style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: Colors.black)),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _exercises.isEmpty
          ? _buildEmpty()
          : RefreshIndicator(
        onRefresh: _load,
        child: ListView.builder(
          padding: const EdgeInsets.symmetric(
              horizontal: 16, vertical: 8),
          itemCount: _exercises.length,
          itemBuilder: (_, i) =>
              _ExerciseCard(item: _exercises[i]),
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.history, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text('운동 기록이 없습니다.',
              style: TextStyle(
                  fontSize: 18, fontWeight: FontWeight.bold)),
          SizedBox(height: 8),
          Text('운동을 기록하면 여기에 표시돼요.',
              style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}

class _ExerciseCard extends StatelessWidget {
  final WorkoutHistoryModel item;
  const _ExerciseCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: Colors.grey.withOpacity(0.15)),
      ),
      child: ListTile(
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.fitness_center_rounded,
              size: 22, color: Colors.blue),
        ),
        title: Text(item.exerciseName,
            style: const TextStyle(
                fontWeight: FontWeight.bold, fontSize: 15)),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Row(
            children: [
              Text(item.target,
                  style: TextStyle(
                      fontSize: 12, color: Colors.grey.shade500)),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text('${item.totalSessions}회',
                    style: const TextStyle(
                        fontSize: 11, color: Colors.grey)),
              ),
            ],
          ),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            const Icon(Icons.chevron_right,
                color: Colors.grey, size: 20),
            Text(item.lastLoggedDate,
                style: const TextStyle(
                    fontSize: 11, color: Colors.grey)),
          ],
        ),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => WorkoutHistoryDetailScreen(
              exerciseId: item.exerciseId,
              exerciseName: item.exerciseName,
            ),
          ),
        ),
      ),
    );
  }
}

// 모델
class WorkoutHistoryModel {
  final int exerciseId;
  final String exerciseName;
  final String target;
  final String lastLoggedDate;
  final int totalSessions;

  WorkoutHistoryModel({
    required this.exerciseId,
    required this.exerciseName,
    required this.target,
    required this.lastLoggedDate,
    required this.totalSessions,
  });

  factory WorkoutHistoryModel.fromJson(Map<String, dynamic> json) =>
      WorkoutHistoryModel(
        exerciseId: json['exerciseId'],
        exerciseName: json['exerciseName'],
        target: json['target'] ?? '',
        lastLoggedDate: json['lastLoggedDate'] ?? '',
        totalSessions: json['totalSessions'] ?? 0,
      );
}