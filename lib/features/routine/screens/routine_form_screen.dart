import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../provider/routine_provider.dart';
import '../../../data/models/routine_model.dart';
import 'exercise_pick_screen.dart';
import '../../../core/widgets/app_background.dart';

class RoutineFormScreen extends StatefulWidget {
  final RoutineModel? routine;

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
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: const Color(0xFF160d1f),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          isEditMode ? '수정하기' : '새로운 루틴',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: AppBackground(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 루틴 이름 입력
                  Text('루틴 이름',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white.withOpacity(0.8))),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _nameController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'ex) 가슴 박살내기',
                      hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.07),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                            color: Color(0xFFF4A259), width: 1.5),
                      ),
                      suffixIcon: _nameController.text.isNotEmpty
                          ? IconButton(
                        icon: Icon(Icons.clear,
                            color: Colors.white.withOpacity(0.4)),
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
                      Text('운동 불러오기',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.white.withOpacity(0.8))),
                      TextButton(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ExercisePickScreen(),
                          ),
                        ),
                        child: const Text('불러오기',
                            style: TextStyle(color: Color(0xFFF4A259))),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // 선택된 운동 목록
            Expanded(
              child: provider.selectedExercises.isEmpty
                  ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.fitness_center,
                        size: 48, color: Colors.white.withOpacity(0.2)),
                    const SizedBox(height: 12),
                    Text('운동을 추가해주세요',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white.withOpacity(0.6))),
                    const SizedBox(height: 4),
                    Text('나만의 완벽한 운동 루틴을 만들어보세요.',
                        style: TextStyle(
                            color: Colors.white.withOpacity(0.3),
                            fontSize: 13)),
                  ],
                ),
              )
                  : ReorderableListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: provider.selectedExercises.length,
                onReorder: (oldIndex, newIndex) {
                  if (newIndex > oldIndex) newIndex--;
                  final item =
                  provider.selectedExercises.removeAt(oldIndex);
                  provider.selectedExercises.insert(newIndex, item);
                  provider.notifyListeners();
                },
                itemBuilder: (_, i) {
                  final ex = provider.selectedExercises[i];
                  return Container(
                    key: ValueKey(ex.id),
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1225),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: Colors.white.withOpacity(0.06)),
                    ),
                    child: ListTile(
                      leading: Icon(Icons.drag_handle,
                          color: Colors.white.withOpacity(0.3)),
                      title: Text(ex.name,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.white)),
                      subtitle: Text(ex.target,
                          style: TextStyle(
                              color: Colors.white.withOpacity(0.4),
                              fontSize: 12)),
                      trailing: IconButton(
                        icon: Icon(Icons.delete_outline,
                            color: Colors.white.withOpacity(0.3)),
                        onPressed: () => provider.toggleExercise(ex),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),

      // 저장 버튼
      bottomNavigationBar: Container(
        color: const Color(0xFF160d1f),
        child: SafeArea(
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
                  success = await provider.updateRoutine(
                      widget.routine!.id, name);
                } else {
                  success = await provider.createRoutine(name);
                }
                if (success && context.mounted) Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF4A259),
                foregroundColor: Colors.black,
                disabledBackgroundColor: Colors.white.withOpacity(0.1),
                minimumSize: const Size(double.infinity, 52),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: Text(
                isEditMode ? '업데이트하기' : '저장하기',
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ),
      ),
    );
  }
}