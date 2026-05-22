import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../data/models/routine_model.dart';
import '../../../data/models/workout_model.dart';
import '../../../data/repositories/routine_repository.dart';

class WorkoutLogScreen extends StatefulWidget {
  // 단일 운동이면 exercises에 1개, 슈퍼세트면 N개
  final List<RoutineExerciseModel> exercises;

  const WorkoutLogScreen({
    super.key,
    required this.exercises,
  });

  // 편의 생성자 — 단일 운동
  factory WorkoutLogScreen.single(RoutineExerciseModel exercise) {
    return WorkoutLogScreen(exercises: [exercise]);
  }

  // 편의 생성자 — 슈퍼세트
  factory WorkoutLogScreen.superset(List<RoutineExerciseModel> exercises) {
    return WorkoutLogScreen(exercises: exercises);
  }

  bool get isSuperset => exercises.length > 1;

  @override
  State<WorkoutLogScreen> createState() => _WorkoutLogScreenState();
}

class _WorkoutLogScreenState extends State<WorkoutLogScreen>
    with TickerProviderStateMixin {
  final _repository = RoutineRepository();
  late TabController? _tabController;

  // 각 운동별 세트 그룹 리스트
  late List<List<_SetGroup>> _allSets;
  late List<List<WorkoutSetModel>> _allRecentSets;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _tabController = widget.isSuperset
        ? TabController(length: widget.exercises.length, vsync: this)
        : null;

    _allSets = List.generate(widget.exercises.length, (_) => []);
    _allRecentSets = List.generate(widget.exercises.length, (_) => []);

    _loadAll();
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    for (int i = 0; i < widget.exercises.length; i++) {
      await _loadRecentSets(i);
    }
  }

  Future<void> _loadRecentSets(int index) async {
    try {
      final sets = await _repository.getRecentSets(widget.exercises[index].id);
      setState(() {
        _allRecentSets[index] = sets;
        final mainSets = sets.where((s) => !s.isDropset).toList();
        if (mainSets.isNotEmpty) {
          final first = mainSets.first;
          final group = _SetGroup(setNumber: 1);
          group.main.weightController.text = first.weightKg?.toString() ?? '';
          group.main.repsController.text = first.reps?.toString() ?? '';
          _allSets[index].add(group);
        } else {
          _allSets[index].add(_SetGroup(setNumber: 1));
        }
      });
    } catch (_) {
      setState(() => _allSets[index].add(_SetGroup(setNumber: 1)));
    }
  }

  void _addSet(int index) {
    setState(() {
      final groups = _allSets[index];
      final prev = groups.last;
      final group = _SetGroup(setNumber: groups.length + 1);
      group.main.weightController.text = prev.main.weightController.text;
      group.main.repsController.text = prev.main.repsController.text;
      groups.add(group);
    });
  }

  void _removeSet(int index, int groupIndex) {
    setState(() {
      final groups = _allSets[index];
      groups.removeAt(groupIndex);
      for (int i = 0; i < groups.length; i++) groups[i].setNumber = i + 1;
    });
  }

  void _addDropset(int index, int groupIndex) {
    setState(() {
      final groups = _allSets[index];
      final prev = groups[groupIndex];
      final drop = _SetInput();
      drop.weightController.text = prev.dropsets.isNotEmpty
          ? prev.dropsets.last.weightController.text
          : prev.main.weightController.text;
      drop.repsController.text = prev.dropsets.isNotEmpty
          ? prev.dropsets.last.repsController.text
          : prev.main.repsController.text;
      groups[groupIndex].dropsets.add(drop);
    });
  }

  void _removeDropset(int index, int groupIndex, int dropIndex) {
    setState(() => _allSets[index][groupIndex].dropsets.removeAt(dropIndex));
  }

  List<Map<String, dynamic>> _buildPayload(List<_SetGroup> groups) {
    final sets = <Map<String, dynamic>>[];
    for (final g in groups) {
      sets.add({
        'weightKg': double.tryParse(g.main.weightController.text) ?? 0,
        'reps': int.tryParse(g.main.repsController.text) ?? 0,
        'isDropset': false,
      });
      for (final d in g.dropsets) {
        sets.add({
          'weightKg': double.tryParse(d.weightController.text) ?? 0,
          'reps': int.tryParse(d.repsController.text) ?? 0,
          'isDropset': true,
        });
      }
    }
    return sets;
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    try {
      for (int i = 0; i < widget.exercises.length; i++) {
        await _repository.saveWorkout(
            widget.exercises[i].id, _buildPayload(_allSets[i]));
      }
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('저장에 실패했습니다.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: widget.isSuperset
            ? Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text('SS',
                      style: TextStyle(
                          fontSize: 11,
                          color: Colors.orange,
                          fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 6),
                const Text('슈퍼세트',
                    style: TextStyle(
                        fontSize: 14, color: Colors.orange)),
              ],
            ),
            Text(
              widget.exercises.map((e) => e.exerciseName).join(' + '),
              style: const TextStyle(fontSize: 13),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        )
            : Text(widget.exercises.first.exerciseName),
        bottom: widget.isSuperset
            ? TabBar(
          controller: _tabController,
          isScrollable: widget.exercises.length > 3,
          tabs: widget.exercises
              .map((e) => Tab(text: e.exerciseName))
              .toList(),
        )
            : null,
      ),
      body: _allSets.any((s) => s.isEmpty)
          ? const Center(child: CircularProgressIndicator())
          : widget.isSuperset
          ? TabBarView(
        controller: _tabController,
        children: List.generate(
          widget.exercises.length,
              (i) => _buildEditor(i),
        ),
      )
          : _buildEditor(0),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton(
            onPressed: _isSaving ? null : _save,
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 52),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: _isSaving
                ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2))
                : Text(
              widget.isSuperset ? '슈퍼세트 저장하기' : '저장하기',
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEditor(int index) {
    final groups = _allSets[index];
    final recent = _allRecentSets[index];

    if (groups.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Padding(
          padding: EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              SizedBox(width: 56),
              Expanded(
                  child: Center(
                      child: Text('무게(kg)',
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey)))),
              SizedBox(width: 8),
              Expanded(
                  child: Center(
                      child: Text('횟수',
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey)))),
              SizedBox(width: 40),
            ],
          ),
        ),
        ...groups.asMap().entries.map((e) => _SetGroupWidget(
          group: e.value,
          onRemoveSet: () => _removeSet(index, e.key),
          onAddDropset: () => _addDropset(index, e.key),
          onRemoveDropset: (di) => _removeDropset(index, e.key, di),
        )),
        OutlinedButton(
          onPressed: () => _addSet(index),
          child: const Text('+ 세트 추가'),
        ),
        const Divider(height: 32),
        const Text('최근 기록',
            style:
            TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 8),
        if (recent.isEmpty)
          const Text('최근 기록이 없습니다.',
              style: TextStyle(color: Colors.grey))
        else
          ...recent.map((s) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  s.isDropset ? '  └ DROP' : '${s.setNumber}세트',
                  style: TextStyle(
                    color: s.isDropset
                        ? Colors.orange
                        : Colors.black87,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text('${s.weightKg}KG · ${s.reps}회',
                    style: const TextStyle(color: Colors.grey)),
              ],
            ),
          )),
        const SizedBox(height: 80),
      ],
    );
  }
}

class _SetGroup {
  int setNumber;
  final _SetInput main;
  final List<_SetInput> dropsets;

  _SetGroup({required this.setNumber})
      : main = _SetInput(),
        dropsets = [];
}

class _SetInput {
  final TextEditingController weightController = TextEditingController();
  final TextEditingController repsController = TextEditingController();
}

class _SetGroupWidget extends StatelessWidget {
  final _SetGroup group;
  final VoidCallback onRemoveSet;
  final VoidCallback onAddDropset;
  final void Function(int) onRemoveDropset;

  const _SetGroupWidget({
    required this.group,
    required this.onRemoveSet,
    required this.onAddDropset,
    required this.onRemoveDropset,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _row('${group.setNumber}', group.main, false, onRemoveSet),
        ...group.dropsets.asMap().entries.map((e) => Padding(
          padding: const EdgeInsets.only(left: 16),
          child: _row('DROP', e.value, true,
                  () => onRemoveDropset(e.key)),
        )),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton(
            onPressed: onAddDropset,
            child: const Text('↳ 드롭세트 추가',
                style: TextStyle(fontSize: 13, color: Colors.grey)),
          ),
        ),
        const Divider(),
      ],
    );
  }

  Widget _row(
      String label, _SetInput input, bool isDrop, VoidCallback onRemove) {
    return Row(
      children: [
        SizedBox(
          width: 56,
          child: isDrop
              ? Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 6, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.2),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Text('DROP',
                style: TextStyle(
                    fontSize: 11,
                    color: Colors.orange,
                    fontWeight: FontWeight.bold)),
          )
              : Text(label,
              style: const TextStyle(fontWeight: FontWeight.bold)),
        ),
        Expanded(child: _Num(controller: input.weightController, hint: '20')),
        const SizedBox(width: 8),
        Expanded(child: _Num(controller: input.repsController, hint: '10')),
        IconButton(
          icon: Icon(Icons.cancel_outlined,
              color: isDrop ? Colors.red.withOpacity(0.5) : Colors.grey,
              size: 20),
          onPressed: onRemove,
        ),
      ],
    );
  }
}

class _Num extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  const _Num({required this.controller, required this.hint});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: TextField(
        controller: controller,
        keyboardType:
        const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'[\d.]'))
        ],
        textAlign: TextAlign.center,
        textInputAction: TextInputAction.next,
        onTap: () => controller.selection = TextSelection(
            baseOffset: 0, extentOffset: controller.text.length),
        decoration: InputDecoration(
          hintText: hint,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 10),
        ),
      ),
    );
  }
}