import 'package:flutter/material.dart';
import '../../../data/models/routine_model.dart';
import '../../../data/repositories/routine_repository.dart';
import 'exercise_pick_screen.dart';
import 'workout_log_screen.dart';

class RoutineDetailScreen extends StatefulWidget {
  final RoutineModel routine;
  const RoutineDetailScreen({super.key, required this.routine});

  @override
  State<RoutineDetailScreen> createState() => _RoutineDetailScreenState();
}

class _RoutineDetailScreenState extends State<RoutineDetailScreen> {
  final _repository = RoutineRepository();
  bool _isEditMode = false;
  late List<_RowItem> _rows;
  final Set<int> _selecting = {};

  // 편집 모드 진입 전 스냅샷 — 저장 없이 나가면 복구
  List<_RowItem>? _rowsSnapshot;

  @override
  void initState() {
    super.initState();
    _initRows();
  }

  void _initRows() {
    final exercises = widget.routine.exercises;
    final rows = <_RowItem>[];
    final visited = <int>{};

    for (int i = 0; i < exercises.length; i++) {
      if (visited.contains(i)) continue;
      final ex = exercises[i];
      if (ex.supersetGroup == null) {
        rows.add(_SingleItem(exercise: ex));
      } else {
        final group = <RoutineExerciseModel>[ex];
        visited.add(i);
        for (int j = i + 1; j < exercises.length; j++) {
          if (exercises[j].supersetGroup == ex.supersetGroup) {
            group.add(exercises[j]);
            visited.add(j);
          }
        }
        rows.add(_SupersetItem(exercises: group, groupId: ex.supersetGroup!));
      }
    }
    _rows = rows;
  }

  int get _totalExerciseCount => _rows.fold(
      0, (sum, r) => sum + (r is _SupersetItem ? r.exercises.length : 1));

  Set<int> get _currentExerciseIds {
    final ids = <int>{};
    for (final row in _rows) {
      if (row is _SingleItem) ids.add(row.exercise.exerciseId);
      if (row is _SupersetItem) {
        ids.addAll(row.exercises.map((e) => e.exerciseId));
      }
    }
    return ids;
  }

  void _toggleSelect(int index) {
    if (_rows[index] is! _SingleItem) return;
    setState(() {
      if (_selecting.contains(index)) {
        _selecting.remove(index);
      } else {
        _selecting.add(index);
      }
    });
  }

  void _applySuperset() {
    if (_selecting.length < 2) return;
    final indices = _selecting.toList()..sort();
    final groupId = DateTime.now().millisecondsSinceEpoch % 100000;
    final exercises =
    indices.map((i) => (_rows[i] as _SingleItem).exercise).toList();

    setState(() {
      for (final i in indices.reversed) _rows.removeAt(i);
      _rows.insert(
          indices.first, _SupersetItem(exercises: exercises, groupId: groupId));
      _selecting.clear();
    });
  }

  void _breakSuperset(int rowIndex) {
    setState(() {
      final superset = _rows[rowIndex] as _SupersetItem;
      final singles =
      superset.exercises.map((e) => _SingleItem(exercise: e)).toList();
      _rows.removeAt(rowIndex);
      _rows.insertAll(rowIndex, singles);
      _selecting.clear();
    });
  }

  // 삭제 + Undo 스낵바
  void _removeRow(int index) {
    final removed = _rows[index];

    setState(() {
      _rows.removeAt(index);
      final newSelecting = <int>{};
      for (final i in _selecting) {
        if (i < index) newSelecting.add(i);
        else if (i > index) newSelecting.add(i - 1);
      }
      _selecting..clear()..addAll(newSelecting);
    });

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          removed is _SingleItem
              ? '\'${removed.exercise.exerciseName}\' 삭제됨'
              : '슈퍼세트 삭제됨',
        ),
        action: SnackBarAction(
          label: '되돌리기',
          onPressed: () {
            setState(() => _rows.insert(index, removed));
          },
        ),
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      ),
    );
  }

  Future<void> _saveChanges() async {
    try {
      final exercises = <Map<String, dynamic>>[];
      int order = 0;

      for (final row in _rows) {
        if (row is _SingleItem) {
          exercises.add({
            'exerciseId': row.exercise.exerciseId,
            'orderIndex': order++,
            'supersetGroup': null,
          });
        } else if (row is _SupersetItem) {
          for (final ex in row.exercises) {
            exercises.add({
              'exerciseId': ex.exerciseId,
              'orderIndex': order++,
              'supersetGroup': row.groupId,
            });
          }
        }
      }

      await _repository.saveRoutineDetail(widget.routine.id, exercises);

      if (mounted) {
        setState(() {
          _isEditMode = false;
          _selecting.clear();
          _rowsSnapshot = null; // 저장 성공 시 스냅샷 제거
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle_outline, color: Colors.white, size: 18),
                SizedBox(width: 8),
                Text('저장되었습니다.'),
              ],
            ),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.error_outline, color: Colors.white, size: 18),
                SizedBox(width: 8),
                Text('저장에 실패했습니다.'),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          ),
        );
      }
    }
  }

  // 저장 없이 편집 모드 종료 → 스냅샷으로 복구
  void _exitEditMode() {
    setState(() {
      _isEditMode = false;
      _selecting.clear();
      if (_rowsSnapshot != null) {
        _rows = List.from(_rowsSnapshot!);
        _rowsSnapshot = null;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_isEditMode,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && _isEditMode) _exitEditMode();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.routine.name,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold)),
              Text('총 $_totalExerciseCount개의 운동',
                  style: const TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
          actions: [
            // 편집 모드가 아닐 때만 + 버튼 표시
            if (!_isEditMode)
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ExercisePickScreen(
                        alreadyAdded: _currentExerciseIds,
                        onComplete: (exercises) {
                          setState(() {
                            for (final ex in exercises) {
                              _rows.add(_SingleItem(
                                exercise: RoutineExerciseModel(
                                  id: -DateTime.now().millisecondsSinceEpoch,
                                  exerciseId: ex.id,
                                  exerciseName: ex.name,
                                  target: ex.target,
                                  orderIndex: _rows.length,
                                ),
                              ));
                            }
                          });
                        },
                      ),
                    ),
                  );
                },
              ),
            // 편집 모드 토글 버튼
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: _isEditMode
                  ? TextButton.icon(
                key: const ValueKey('save'),
                onPressed: _saveChanges,
                icon: const Icon(Icons.check, size: 18),
                label: const Text('저장'),
                style:
                TextButton.styleFrom(foregroundColor: Colors.blue),
              )
                  : IconButton(
                key: const ValueKey('edit'),
                icon: const Icon(Icons.tune_rounded),
                onPressed: () => setState(() {
                  _isEditMode = true;
                  _selecting.clear();
                  // 편집 모드 진입 시 스냅샷 저장
                  _rowsSnapshot = List.from(_rows);
                }),
              ),
            ),
          ],
        ),
        body: AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: _isEditMode ? _buildEditMode() : _buildNormalMode(),
        ),
      ),
    );
  }

  // ── 일반 모드 ──
  Widget _buildNormalMode() {
    if (_rows.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.fitness_center, size: 48, color: Colors.grey),
            SizedBox(height: 12),
            Text('운동을 추가해보세요',
                style: TextStyle(color: Colors.grey, fontSize: 15)),
          ],
        ),
      );
    }

    return ListView.builder(
      key: const ValueKey('normal'),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: _rows.length,
      itemBuilder: (_, i) {
        final row = _rows[i];
        if (row is _SingleItem) {
          return _SingleCard(
            item: row,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => WorkoutLogScreen.single(row.exercise)),
            ),
          );
        } else {
          final ss = row as _SupersetItem;
          return _SupersetCard(
            item: ss,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => WorkoutLogScreen.superset(ss.exercises)),
            ),
          );
        }
      },
    );
  }

  // ── 편집 모드 ──
  Widget _buildEditMode() {
    return Column(
      key: const ValueKey('edit'),
      children: [
        _buildBanner(),
        Expanded(
          child: ReorderableListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            buildDefaultDragHandles: false,
            itemCount: _rows.length,
            onReorder: (oldIndex, newIndex) {
              if (newIndex > oldIndex) newIndex--;
              setState(() {
                final item = _rows.removeAt(oldIndex);
                _rows.insert(newIndex, item);
                _selecting.clear();
              });
            },
            itemBuilder: (_, i) {
              final row = _rows[i];
              if (row is _SingleItem) {
                return Dismissible(
                  key: ValueKey('s_${row.exercise.exerciseId}_$i'),
                  direction: DismissDirection.endToStart,
                  dismissThresholds: const {
                    DismissDirection.endToStart: 0.35
                  },
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 24),
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(
                      color: Colors.red.shade400,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.delete_outline,
                            color: Colors.white, size: 22),
                        SizedBox(height: 2),
                        Text('삭제',
                            style: TextStyle(
                                color: Colors.white, fontSize: 11)),
                      ],
                    ),
                  ),
                  onDismissed: (_) => _removeRow(i),
                  child: _EditSingleCard(
                    index: i,
                    item: row,
                    isSelected: _selecting.contains(i),
                    onSelect: () => _toggleSelect(i),
                  ),
                );
              } else {
                final ss = row as _SupersetItem;
                return _EditSupersetCard(
                  key: ValueKey('ss_${ss.groupId}_$i'),
                  index: i,
                  item: ss,
                  onBreak: () => _breakSuperset(i),
                );
              }
            },
          ),
        ),
      ],
    );
  }

  // ── 배너 ──
  Widget _buildBanner() {
    return AnimatedSize(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      child: _selecting.isEmpty
          ? Container(
        width: double.infinity,
        padding:
        const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.grey.withOpacity(0.08),
          border: Border(
            bottom: BorderSide(
                color: Colors.grey.withOpacity(0.15), width: 1),
          ),
        ),
        child: Row(
          children: [
            Icon(Icons.info_outline,
                size: 14, color: Colors.grey.shade500),
            const SizedBox(width: 6),
            Text(
              '← 스와이프 삭제  ·  ○ 탭 후 슈퍼세트 묶기  ·  ≡ 드래그 순서변경',
              style: TextStyle(
                  fontSize: 11, color: Colors.grey.shade500),
            ),
          ],
        ),
      )
          : Container(
        width: double.infinity,
        padding:
        const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.blue.withOpacity(0.07),
          border: Border(
            bottom: BorderSide(
                color: Colors.blue.withOpacity(0.2), width: 1),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.blue,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${_selecting.length}개 선택',
                style: const TextStyle(
                    fontSize: 12,
                    color: Colors.white,
                    fontWeight: FontWeight.bold),
              ),
            ),
            const Spacer(),
            TextButton(
              onPressed: () => setState(() => _selecting.clear()),
              style: TextButton.styleFrom(
                padding:
                const EdgeInsets.symmetric(horizontal: 8),
                foregroundColor: Colors.grey,
              ),
              child:
              const Text('취소', style: TextStyle(fontSize: 13)),
            ),
            const SizedBox(width: 4),
            FilledButton.icon(
              onPressed:
              _selecting.length >= 2 ? _applySuperset : null,
              icon: const Icon(Icons.link_rounded, size: 16),
              label: const Text('슈퍼세트로 묶기',
                  style: TextStyle(fontSize: 13)),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.orange,
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── 데이터 모델 ──
abstract class _RowItem {}

class _SingleItem extends _RowItem {
  final RoutineExerciseModel exercise;
  _SingleItem({required this.exercise});
}

class _SupersetItem extends _RowItem {
  final List<RoutineExerciseModel> exercises;
  final int groupId;
  _SupersetItem({required this.exercises, required this.groupId});
}

// ── 일반 모드 단일 카드 ──
class _SingleCard extends StatelessWidget {
  final _SingleItem item;
  final VoidCallback onTap;
  const _SingleCard({required this.item, required this.onTap});

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
        const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.08),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.fitness_center_rounded,
              size: 20, color: Colors.blue),
        ),
        title: Text(item.exercise.exerciseName,
            style: const TextStyle(
                fontWeight: FontWeight.w600, fontSize: 15)),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Text(item.exercise.target,
              style:
              TextStyle(fontSize: 12, color: Colors.grey.shade500)),
        ),
        trailing:
        const Icon(Icons.chevron_right, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }
}

// ── 일반 모드 슈퍼세트 카드 ──
class _SupersetCard extends StatelessWidget {
  final _SupersetItem item;
  final VoidCallback onTap;
  const _SupersetCard({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: Colors.orange.withOpacity(0.3)),
      ),
      color: Colors.orange.withOpacity(0.04),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 4),
                margin: const EdgeInsets.only(right: 12, top: 2),
                decoration: BoxDecoration(
                  color: Colors.orange,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text('SS',
                    style: TextStyle(
                        fontSize: 11,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5)),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: item.exercises.map((ex) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        children: [
                          Container(
                              width: 3,
                              height: 16,
                              decoration: BoxDecoration(
                                  color: Colors.orange,
                                  borderRadius:
                                  BorderRadius.circular(2))),
                          const SizedBox(width: 8),
                          Text(ex.exerciseName,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14)),
                          const SizedBox(width: 6),
                          Text(ex.target,
                              style: TextStyle(
                                  color: Colors.grey.shade500,
                                  fontSize: 12)),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
              const Icon(Icons.chevron_right,
                  color: Colors.grey, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

// ── 편집 모드 단일 카드 ──
class _EditSingleCard extends StatelessWidget {
  final int index;
  final _SingleItem item;
  final bool isSelected;
  final VoidCallback onSelect;

  const _EditSingleCard({
    required this.index,
    required this.item,
    required this.isSelected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isSelected
            ? Colors.blue.withOpacity(0.07)
            : Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isSelected
              ? Colors.blue.withOpacity(0.4)
              : Colors.grey.withOpacity(0.15),
          width: isSelected ? 1.5 : 1,
        ),
      ),
      child: ListTile(
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        leading: GestureDetector(
          onTap: onSelect,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected
                    ? Colors.blue
                    : Colors.grey.shade400,
                width: 2,
              ),
              color: isSelected ? Colors.blue : Colors.transparent,
            ),
            child: isSelected
                ? const Icon(Icons.check,
                size: 16, color: Colors.white)
                : null,
          ),
        ),
        title: Text(item.exercise.exerciseName,
            style: const TextStyle(
                fontWeight: FontWeight.w600, fontSize: 15)),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Text(item.exercise.target,
              style:
              TextStyle(fontSize: 12, color: Colors.grey.shade500)),
        ),
        trailing: ReorderableDragStartListener(
          index: index,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Icon(Icons.drag_handle_rounded,
                color: Colors.grey.shade400, size: 22),
          ),
        ),
      ),
    );
  }
}

// ── 편집 모드 슈퍼세트 카드 ──
class _EditSupersetCard extends StatelessWidget {
  final int index;
  final _SupersetItem item;
  final VoidCallback onBreak;

  const _EditSupersetCard({
    super.key,
    required this.index,
    required this.item,
    required this.onBreak,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.orange.withOpacity(0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ReorderableDragStartListener(
                  index: index,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Icon(Icons.drag_handle_rounded,
                        color: Colors.grey.shade400, size: 22),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.orange,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'SS  ${item.exercises.length}개',
                    style: const TextStyle(
                        fontSize: 11,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5),
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: onBreak,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      border: Border.all(
                          color: Colors.orange.withOpacity(0.5)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text('해제',
                        style: TextStyle(
                            color: Colors.orange,
                            fontSize: 12,
                            fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ...item.exercises.map((ex) => Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 8),
              child: Row(
                children: [
                  Container(
                    width: 3,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.orange,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(ex.exerciseName,
                            style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14)),
                        Text(ex.target,
                            style: TextStyle(
                                color: Colors.grey.shade500,
                                fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ),
            )),
            Row(
              children: [
                const SizedBox(width: 4),
                Icon(Icons.swipe_left_outlined,
                    size: 13, color: Colors.grey.shade400),
                const SizedBox(width: 4),
                Text('해제 후 스와이프로 삭제',
                    style: TextStyle(
                        fontSize: 11, color: Colors.grey.shade400)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}