import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../provider/routine_provider.dart';
import '../../../data/models/exercise_model.dart';
import '../../../core/widgets/app_background.dart';

class ExercisePickScreen extends StatefulWidget {
  final void Function(List<ExerciseModel>)? onComplete;
  final Set<int> alreadyAdded;

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
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: const Color(0xFF160d1f),
        elevation: 0,
        title: const Text('운동 추가',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.white),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: AppBackground(
        child: Column(
          children: [
            // 검색 + 필터
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  TextField(
                    controller: _searchController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: '검색하기',
                      hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
                      prefixIcon: Icon(Icons.search,
                          color: Colors.white.withOpacity(0.4)),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.07),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
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
                            selectedColor: const Color(0xFFF4A259).withOpacity(0.2),
                            checkmarkColor: const Color(0xFFF4A259),
                            labelStyle: TextStyle(
                              color: isSelected
                                  ? const Color(0xFFF4A259)
                                  : Colors.black.withOpacity(0.6),
                              fontSize: 13,
                            ),
                            backgroundColor: Colors.white.withOpacity(0.07),
                            side: BorderSide(
                              color: isSelected
                                  ? const Color(0xFFF4A259).withOpacity(0.5)
                                  : Colors.black.withOpacity(0.1),
                            ),
                            onSelected: (_) => _filterTarget(t),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),

            // 헤더
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('운동 목록',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white.withOpacity(0.8))),
                  TextButton(
                    onPressed: () => _showCustomAddDialog(context),
                    child: const Text('+ 직접 추가',
                        style: TextStyle(color: Color(0xFFF4A259))),
                  ),
                ],
              ),
            ),

            // 운동 목록
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                itemCount: provider.exercises.length,
                itemBuilder: (_, i) {
                  final ex = provider.exercises[i];
                  final isSelected = _isSelected(ex);
                  final isAlreadyAdded = widget.alreadyAdded.contains(ex.id);

                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFFF4A259).withOpacity(0.1)
                          : Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFFF4A259).withOpacity(0.4)
                            : Colors.white.withOpacity(0.07),
                      ),
                    ),
                    child: ListTile(
                      leading: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A3A4A),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.open_in_full_rounded,
                            size: 18, color: Color(0xFF42A5F5)),
                      ),
                      title: Text(
                        ex.name,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isAlreadyAdded
                              ? Colors.white.withOpacity(0.3)
                              : Colors.white,
                          fontSize: 14,
                        ),
                      ),
                      subtitle: Text(
                        ex.target,
                        style: TextStyle(
                          color: isAlreadyAdded
                              ? Colors.white.withOpacity(0.2)
                              : Colors.white.withOpacity(0.4),
                          fontSize: 12,
                        ),
                      ),
                      trailing: isAlreadyAdded
                          ? Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.07),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text('추가됨',
                            style: TextStyle(
                                color: Colors.white.withOpacity(0.3),
                                fontSize: 12)),
                      )
                          : isSelected
                          ? const Icon(Icons.check_circle,
                          color: Color(0xFFF4A259))
                          : Icon(Icons.add_circle_outline,
                          color: Colors.white.withOpacity(0.3)),
                      onTap: isAlreadyAdded
                          ? null
                          : () => setState(() => _toggle(ex)),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        color: const Color(0xFF160d1f),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton(
              onPressed: _selectedCount == 0 ? null : _complete,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF4A259),
                foregroundColor: Colors.black,
                disabledBackgroundColor: Colors.white.withOpacity(0.1),
                minimumSize: const Size(double.infinity, 52),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: Text('완료하기 ($_selectedCount)',
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold)),
            ),
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
          backgroundColor: const Color(0xFF1E1225),
          title: const Text('운동 직접 추가',
              style: TextStyle(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('운동 이름',
                  style: TextStyle(color: Colors.white.withOpacity(0.7))),
              const SizedBox(height: 8),
              TextField(
                controller: nameController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: '예: 벤치 프레스',
                  hintStyle:
                  TextStyle(color: Colors.white.withOpacity(0.3)),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.07),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text('타겟',
                  style: TextStyle(color: Colors.white.withOpacity(0.7))),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: ['하체', '가슴', '등', '어깨', '팔'].map((t) {
                  return ChoiceChip(
                    label: Text(t),
                    selected: selectedTarget == t,
                    selectedColor: const Color(0xFFF4A259).withOpacity(0.2),
                    labelStyle: TextStyle(
                      color: selectedTarget == t
                          ? const Color(0xFFF4A259)
                          : Colors.black.withOpacity(0.6),
                    ),
                    backgroundColor: Colors.white.withOpacity(0.07),
                    onSelected: (_) => setState(() => selectedTarget = t),
                  );
                }).toList(),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('취소',
                  style: TextStyle(color: Colors.white.withOpacity(0.5))),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.trim().isEmpty) return;
                await context.read<RoutineProvider>().addCustomExercise(
                    nameController.text.trim(), selectedTarget);
                if (context.mounted) Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF4A259),
                foregroundColor: Colors.black,
              ),
              child: const Text('추가하기'),
            ),
          ],
        ),
      ),
    );
  }
}