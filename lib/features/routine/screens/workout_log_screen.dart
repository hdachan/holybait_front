import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../data/models/routine_model.dart';
import '../../../data/models/workout_model.dart';
import '../../../data/repositories/routine_repository.dart';
import '../../currency/provider/currency_provider.dart';

class WorkoutLogScreen extends StatefulWidget {
  final List<RoutineExerciseModel> exercises;

  const WorkoutLogScreen({super.key, required this.exercises});

  factory WorkoutLogScreen.single(RoutineExerciseModel exercise) =>
      WorkoutLogScreen(exercises: [exercise]);

  factory WorkoutLogScreen.superset(List<RoutineExerciseModel> exercises) =>
      WorkoutLogScreen(exercises: exercises);

  bool get isSuperset => exercises.length > 1;

  @override
  State<WorkoutLogScreen> createState() => _WorkoutLogScreenState();
}

class _WorkoutLogScreenState extends State<WorkoutLogScreen>
    with TickerProviderStateMixin {
  final _repository = RoutineRepository();
  late TabController? _tabController;

  late List<List<_SetGroup>> _allSets;
  late List<List<WorkoutSetModel>> _allRecentSets;

  bool _isSaving = false;
  bool _isLoaded = false;

  late AnimationController _coinAnim;
  late Animation<double> _coinFade;
  late Animation<Offset> _coinSlide;
  int _lastGranted = 0;

  @override
  void initState() {
    super.initState();
    _tabController = widget.isSuperset
        ? TabController(length: widget.exercises.length, vsync: this)
        : null;

    _allSets = List.generate(widget.exercises.length, (_) => []);
    _allRecentSets = List.generate(widget.exercises.length, (_) => []);

    _coinAnim = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200));
    _coinFade = Tween<double>(begin: 1, end: 0).animate(
        CurvedAnimation(parent: _coinAnim, curve: Curves.easeOut));
    _coinSlide =
        Tween<Offset>(begin: Offset.zero, end: const Offset(0, -1.5))
            .animate(CurvedAnimation(
            parent: _coinAnim, curve: Curves.easeOut));

    _loadAll();
  }

  @override
  void dispose() {
    _tabController?.dispose();
    _coinAnim.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    for (int i = 0; i < widget.exercises.length; i++) {
      await _loadSets(i);
    }
    if (mounted) setState(() => _isLoaded = true);
  }

  Future<void> _loadSets(int index) async {
    try {
      final response =
      await _repository.getRecentSets(widget.exercises[index].id);

      if (response == null) {
        if (mounted) setState(() => _allSets[index] = [_SetGroup(setNumber: 1)]);
        return;
      }

      debugPrint('📥 [$index] isToday=${response.isToday} sets=${response.sets.length}');
      if (mounted) {
        setState(() {
          if (response.isToday) {
            // 오늘 기록 → 입력창 복원, 최근기록 섹션 비움
            _allSets[index] = _buildGroupsFromSets(response.sets);
            _allRecentSets[index] = [];
          } else {
            // 전날 이전 → 빈 세트 1개, 최근기록 섹션에 표시
            _allSets[index] = [_SetGroup(setNumber: 1)];
            _allRecentSets[index] = response.sets;
          }
        });
      }
    } catch (e) {
      debugPrint('❌ loadSets[$index] error: $e');
      if (mounted) {
        setState(() => _allSets[index] = [_SetGroup(setNumber: 1)]);
      }
    }
  }

  List<_SetGroup> _buildGroupsFromSets(List<WorkoutSetModel> sets) {
    final groups = <_SetGroup>[];
    int setNum = 1;

    for (int i = 0; i < sets.length; i++) {
      final s = sets[i];
      if (s.isDropset) continue;

      final group = _SetGroup(setNumber: setNum++);
      group.main.weightController.text = s.weightKg?.toString() ?? '';
      group.main.repsController.text = s.reps?.toString() ?? '';

      int j = i + 1;
      while (j < sets.length && sets[j].isDropset) {
        final drop = _SetInput();
        drop.weightController.text = sets[j].weightKg?.toString() ?? '';
        drop.repsController.text = sets[j].reps?.toString() ?? '';
        group.dropsets.add(drop);
        j++;
      }
      i = j - 1;
      groups.add(group);
    }

    return groups.isEmpty ? [_SetGroup(setNumber: 1)] : groups;
  }

  void _addSet(int index) {
    setState(() {
      final groups = _allSets[index];
      final group = _SetGroup(setNumber: groups.length + 1);
      if (groups.isNotEmpty) {
        group.main.weightController.text =
            groups.last.main.weightController.text;
        group.main.repsController.text =
            groups.last.main.repsController.text;
      }
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
    setState(
            () => _allSets[index][groupIndex].dropsets.removeAt(dropIndex));
  }

  // 빈 세트(무게/횟수 모두 0) 제외하고 payload 빌드
  List<Map<String, dynamic>> _buildPayload(List<_SetGroup> groups) {
    final result = <Map<String, dynamic>>[];
    for (final g in groups) {
      final w = double.tryParse(g.main.weightController.text) ?? 0;
      final r = int.tryParse(g.main.repsController.text) ?? 0;
      // 무게와 횟수 둘 다 0이면 빈 세트 → 저장 안 함
      if (w == 0 && r == 0) continue;
      result.add({'weightKg': w, 'reps': r, 'isDropset': false});
      for (final d in g.dropsets) {
        final dw = double.tryParse(d.weightController.text) ?? 0;
        final dr = int.tryParse(d.repsController.text) ?? 0;
        if (dw == 0 && dr == 0) continue;
        result.add({'weightKg': dw, 'reps': dr, 'isDropset': true});
      }
    }
    return result;
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    int totalGranted = 0;
    bool hasError = false;

    for (int i = 0; i < widget.exercises.length; i++) {
      final payload = _buildPayload(_allSets[i]);
      // 빈 세트만 있으면 이 운동은 저장 스킵
      if (payload.isEmpty) continue;

      try {
        final result = await _repository.saveWorkout(
          widget.exercises[i].id,
          payload,
        );
        totalGranted += result.grantedShoeCoin;
        debugPrint('✅ save[$i] granted=${result.grantedShoeCoin}');
      } catch (e) {
        debugPrint('❌ save[$i] error: $e');
        hasError = true;
      }
    }

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (hasError) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Row(children: [
          Icon(Icons.error_outline, color: Colors.white, size: 18),
          SizedBox(width: 8),
          Text('일부 저장에 실패했습니다.'),
        ]),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      ));
      return;
    }

    context.read<CurrencyProvider>().load();

    if (totalGranted > 0) {
      setState(() => _lastGranted = totalGranted);
      _coinAnim.forward(from: 0);
    }

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        const Icon(Icons.check_circle_outline,
            color: Colors.white, size: 18),
        const SizedBox(width: 8),
        Text(totalGranted > 0
            ? '저장되었습니다.  👟 +$totalGranted'
            : '저장되었습니다.'),
      ]),
      behavior: SnackBarBehavior.floating,
      shape:
      RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      duration: const Duration(seconds: 2),
    ));
    // 화면 유지, 입력값 그대로
  }

  @override
  Widget build(BuildContext context) {
    final currency = context.watch<CurrencyProvider>();

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
            Row(children: [
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
            ]),
            Text(
              widget.exercises.map((e) => e.exerciseName).join(' + '),
              style: const TextStyle(fontSize: 13),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        )
            : Text(widget.exercises.first.exerciseName),
        actions: [
          _CoinCapBadge(currency: currency),
          const SizedBox(width: 8),
        ],
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
      body: Stack(
        children: [
          !_isLoaded
              ? const Center(child: CircularProgressIndicator())
              : widget.isSuperset
              ? TabBarView(
            controller: _tabController,
            children: List.generate(
                widget.exercises.length,
                    (i) => _buildEditor(i)),
          )
              : _buildEditor(0),

          if (_lastGranted > 0)
            Positioned(
              top: 60,
              right: 20,
              child: AnimatedBuilder(
                animation: _coinAnim,
                builder: (_, __) => FadeTransition(
                  opacity: _coinFade,
                  child: SlideTransition(
                    position: _coinSlide,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.orange,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.orange.withOpacity(0.4),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          )
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('👟',
                              style: TextStyle(fontSize: 16)),
                          const SizedBox(width: 4),
                          Text('+$_lastGranted',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
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

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Padding(
          padding: EdgeInsets.only(bottom: 8),
          child: Row(children: [
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
          ]),
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
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
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

class _CoinCapBadge extends StatelessWidget {
  final CurrencyProvider currency;
  const _CoinCapBadge({required this.currency});

  @override
  Widget build(BuildContext context) {
    final isCapped = currency.isCapped;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: isCapped
            ? Colors.grey.withOpacity(0.12)
            : Colors.orange.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('👟', style: TextStyle(fontSize: 13)),
          const SizedBox(width: 4),
          Text(
            isCapped
                ? '오늘 최대'
                : '${currency.todayShoeCoin} / ${currency.dailyCap}',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: isCapped ? Colors.grey : Colors.orange,
            ),
          ),
        ],
      ),
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
        Expanded(
            child: _Num(controller: input.weightController, hint: '20')),
        const SizedBox(width: 8),
        Expanded(
            child: _Num(controller: input.repsController, hint: '10')),
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
          hintStyle: TextStyle(color: Colors.grey.shade400),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 10),
        ),
      ),
    );
  }
}
