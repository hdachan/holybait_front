import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../provider/routine_provider.dart';
import '../../../data/models/exercise_model.dart';

class ExercisePickScreen extends StatefulWidget {
  final void Function(List<ExerciseModel>)? onComplete;
  final Set<int> alreadyAdded; // 이미 추가된 exerciseId 목록

  const ExercisePickScreen({
    super.key,
    this.onComplete,
    this.alreadyAdded = const {},
  });

  @override
  State<ExercisePickScreen> createState() => _ExercisePickScreenState();
}

class _ExercisePickScreenState extends State<ExercisePickScreen> {
  final _searchController = TextEditingController();
  String? _selectedTarget;
  final List<String> _targets = ['전체', '하체', '가슴', '등', '어깨', '팔'];

  bool get _isStandaloneMode => widget.onComplete != null;
  final List<ExerciseModel> _localSelected = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RoutineProvider>().loadExercises();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _search(String keyword) {
    context.read<RoutineProvider>().loadExercises(
        keyword: keyword.isEmpty ? null : keyword);
  }

  void _filterTarget(String? target) {
    setState(() => _selectedTarget = target == '전체' ? null : target);
    context.read<RoutineProvider>().loadExercises(
        target: target == '전체' ? null : target);
  }

  bool _isSelected(ExerciseModel ex) {
    if (_isStandaloneMode) {
      return _localSelected.any((e) => e.id == ex.id);
    }
    return context.read<RoutineProvider>().selectedExercises.any((e) => e.id == ex.id);
  }

  void _toggle(ExerciseModel ex) {
    if (_isStandaloneMode) {
      setState(() {
        if (_localSelected.any((e) => e.id == ex.id)) {
          _localSelected.removeWhere((e) => e.id == ex.id);
        } else {
          _localSelected.add(ex);
        }
      });
    } else {
      context.read<RoutineProvider>().toggleExercise(ex);
    }
  }

  int get _selectedCount => _isStandaloneMode
      ? _localSelected.length
      : context.read<RoutineProvider>().selectedExercises.length;

  void _complete() {
    if (_isStandaloneMode) {
      widget.onComplete!(_localSelected);
      Navigator.pop(context);
    } else {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<RoutineProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('운동 추가'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: '검색하기',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  onChanged: _search,
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _targets.map((t) {
                      final isSelected =
                          (t == '전체' && _selectedTarget == null) ||
                              t == _selectedTarget;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(t),
                          selected: isSelected,
                          onSelected: (_) => _filterTarget(t),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('운동 목록',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                TextButton(
                  onPressed: () => _showCustomAddDialog(context),
                  child: const Text('+ 직접 추가'),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: provider.exercises.length,
              itemBuilder: (_, i) {
                final ex = provider.exercises[i];
                final isSelected = _isSelected(ex);
                final isAlreadyAdded = widget.alreadyAdded.contains(ex.id);

                return ListTile(
                  title: Text(
                    ex.name,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isAlreadyAdded ? Colors.grey : Colors.black,
                    ),
                  ),
                  subtitle: Text(
                    ex.target,
                    style: TextStyle(
                      color: isAlreadyAdded ? Colors.grey.shade400 : null,
                    ),
                  ),
                  trailing: isAlreadyAdded
                      ? Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      '추가됨',
                      style: TextStyle(
                          color: Colors.grey, fontSize: 12),
                    ),
                  )
                      : isSelected
                      ? const Icon(Icons.check_circle,
                      color: Colors.blue)
                      : const Icon(Icons.add_circle_outline),
                  onTap: isAlreadyAdded
                      ? null
                      : () => setState(() => _toggle(ex)),
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton(
            onPressed: _selectedCount == 0 ? null : _complete,
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 52),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: Text('완료하기 ($_selectedCount)',
                style: const TextStyle(fontSize: 16)),
          ),
        ),
      ),
    );
  }

  void _showCustomAddDialog(BuildContext context) {
    final nameController = TextEditingController();
    String selectedTarget = '하체';

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('운동 직접 추가'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('운동 이름'),
              const SizedBox(height: 8),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  hintText: '예: 벤치 프레스',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              const Text('타겟'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: ['하체', '가슴', '등', '어깨', '팔'].map((t) {
                  return ChoiceChip(
                    label: Text(t),
                    selected: selectedTarget == t,
                    onSelected: (_) => setState(() => selectedTarget = t),
                  );
                }).toList(),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('취소'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.trim().isEmpty) return;
                await context.read<RoutineProvider>().addCustomExercise(
                    nameController.text.trim(), selectedTarget);
                if (context.mounted) Navigator.pop(context);
              },
              child: const Text('추가하기'),
            ),
          ],
        ),
      ),
    );
  }
}
