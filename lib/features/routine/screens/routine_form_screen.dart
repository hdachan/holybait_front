import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../provider/routine_provider.dart';
import '../../../data/models/routine_model.dart';
import 'exercise_pick_screen.dart';

class RoutineFormScreen extends StatefulWidget {
  final RoutineModel? routine; // null이면 추가 모드, 값이 있으면 수정 모드

  const RoutineFormScreen({super.key, this.routine});

  @override
  State<RoutineFormScreen> createState() => _RoutineFormScreenState();
}

class _RoutineFormScreenState extends State<RoutineFormScreen> {
  final _nameController = TextEditingController();
  bool get isEditMode => widget.routine != null;

  @override
  void initState() {
    super.initState();
    if (isEditMode) {
      _nameController.text = widget.routine!.name;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<RoutineProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditMode ? '수정하기' : '새로운 루틴'),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 루틴 이름 입력
                const Text('루틴 이름',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                TextField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    hintText: 'ex) 가슴 박살내기',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    suffixIcon: _nameController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _nameController.clear();
                              setState(() {});
                            },
                          )
                        : null,
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 20),

                // 운동 불러오기
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('운동 불러오기',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    TextButton(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ExercisePickScreen(),
                        ),
                      ),
                      child: const Text('불러오기'),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // 선택된 운동 목록
          Expanded(
            child: provider.selectedExercises.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.fitness_center, size: 48, color: Colors.grey),
                        SizedBox(height: 12),
                        Text('운동을 추가해주세요',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        SizedBox(height: 4),
                        Text('나만의 완벽한 운동 루틴을 만들어보세요.',
                            style: TextStyle(color: Colors.grey, fontSize: 13)),
                      ],
                    ),
                  )
                : ReorderableListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: provider.selectedExercises.length,
                    onReorder: (oldIndex, newIndex) {
                      if (newIndex > oldIndex) newIndex--;
                      final item = provider.selectedExercises.removeAt(oldIndex);
                      provider.selectedExercises.insert(newIndex, item);
                      provider.notifyListeners();
                    },
                    itemBuilder: (_, i) {
                      final ex = provider.selectedExercises[i];
                      return Card(
                        key: ValueKey(ex.id),
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          title: Text(ex.name,
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text(ex.target),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline,
                                color: Colors.grey),
                            onPressed: () => provider.toggleExercise(ex),
                          ),
                          leading: const Icon(Icons.drag_handle,
                              color: Colors.grey),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),

      // 저장 버튼
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton(
            onPressed: _nameController.text.trim().isEmpty ||
                    provider.selectedExercises.isEmpty
                ? null
                : () async {
                    final name = _nameController.text.trim();
                    bool success;
                    if (isEditMode) {
                      success = await provider.updateRoutine(widget.routine!.id, name);
                    } else {
                      success = await provider.createRoutine(name);
                    }
                    if (success && context.mounted) Navigator.pop(context);
                  },
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 52),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(isEditMode ? '업장하기' : '저장하기',
                style: const TextStyle(fontSize: 16)),
          ),
        ),
      ),
    );
  }
}
