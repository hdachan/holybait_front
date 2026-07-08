import 'package:flutter/material.dart';
import '../../../data/repositories/routine_repository.dart';

class WorkoutHistoryDetailScreen extends StatefulWidget {
  final int exerciseId;
  final String exerciseName;

  const WorkoutHistoryDetailScreen({
    super.key,
    required this.exerciseId,
    required this.exerciseName,
  });

  @override
  State<WorkoutHistoryDetailScreen> createState() =>
      _WorkoutHistoryDetailScreenState();
}

class _WorkoutHistoryDetailScreenState
    extends State<WorkoutHistoryDetailScreen> {
  final _repository = RoutineRepository();
  List<WorkoutHistoryDetailModel> _records = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      _records = await _repository.getExerciseDetail(widget.exerciseId);
    } catch (_) {
      _records = [];
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
        title: Text(widget.exerciseName,
            style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: Colors.black)),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _records.isEmpty
          ? const Center(
          child: Text('기록이 없습니다.',
              style: TextStyle(color: Colors.grey)))
          : ListView.builder(
        padding: const EdgeInsets.symmetric(
            horizontal: 16, vertical: 8),
        itemCount: _records.length,
        itemBuilder: (_, i) =>
            _RecordCard(record: _records[i]),
      ),
    );
  }
}

class _RecordCard extends StatelessWidget {
  final WorkoutHistoryDetailModel record;
  const _RecordCard({required this.record});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 날짜 + 총 세트
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(record.loggedDate,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: Colors.black87)),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text('${record.totalSets}세트',
                      style: const TextStyle(
                          fontSize: 12,
                          color: Colors.blue,
                          fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 10),

            // 세트 목록
            ...record.sets.map((s) => _SetRow(set: s)),
          ],
        ),
      ),
    );
  }
}

class _SetRow extends StatelessWidget {
  final SetDetailModel set;
  const _SetRow({required this.set});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          // 세트 번호
          SizedBox(
            width: 52,
            child: set.isDropset
                ? Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text('DROP',
                  style: TextStyle(
                      fontSize: 10,
                      color: Colors.orange,
                      fontWeight: FontWeight.bold)),
            )
                : Text('${set.setNumber}세트',
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: Colors.black87)),
          ),
          const SizedBox(width: 12),
          // 무게
          Text(
            set.weightKg != null ? '${set.weightKg} kg' : '-',
            style: TextStyle(
                fontSize: 13, color: Colors.grey.shade700),
          ),
          const SizedBox(width: 8),
          const Text('×',
              style: TextStyle(color: Colors.grey, fontSize: 13)),
          const SizedBox(width: 8),
          // 횟수
          Text(
            set.reps != null ? '${set.reps} 회' : '-',
            style: TextStyle(
                fontSize: 13, color: Colors.grey.shade700),
          ),
        ],
      ),
    );
  }
}

// 모델
class WorkoutHistoryDetailModel {
  final String loggedDate;
  final int totalSets;
  final List<SetDetailModel> sets;

  WorkoutHistoryDetailModel({
    required this.loggedDate,
    required this.totalSets,
    required this.sets,
  });

  factory WorkoutHistoryDetailModel.fromJson(Map<String, dynamic> json) =>
      WorkoutHistoryDetailModel(
        loggedDate: json['loggedDate'] ?? '',
        totalSets: json['totalSets'] ?? 0,
        sets: (json['sets'] as List? ?? [])
            .map((s) => SetDetailModel.fromJson(s))
            .toList(),
      );
}

class SetDetailModel {
  final int setNumber;
  final double? weightKg;
  final int? reps;
  final bool isDropset;

  SetDetailModel({
    required this.setNumber,
    this.weightKg,
    this.reps,
    required this.isDropset,
  });

  factory SetDetailModel.fromJson(Map<String, dynamic> json) =>
      SetDetailModel(
        setNumber: json['setNumber'] ?? 0,
        weightKg: json['weightKg'] != null
            ? double.tryParse(json['weightKg'].toString())
            : null,
        reps: json['reps'],
        isDropset: json['isDropset'] ?? false,
      );
}