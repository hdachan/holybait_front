import 'package:flutter/material.dart';

import '../../../data/models/exercise_model.dart';
import '../../../data/models/routine_model.dart';
import '../../../data/repositories/routine_repository.dart';


class RoutineProvider extends ChangeNotifier {
  final _repository = RoutineRepository();

  List<RoutineModel> _routines = [];
  List<ExerciseModel> _exercises = [];
  List<ExerciseModel> _selectedExercises = [];
  bool _isLoading = false;
  String? _error;

  List<RoutineModel> get routines => _routines;
  List<ExerciseModel> get exercises => _exercises;
  List<ExerciseModel> get selectedExercises => _selectedExercises;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // 루틴 목록 조회
  Future<void> loadRoutines() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _routines = await _repository.getRoutines();
    } catch (e) {
      _error = '루틴을 불러오지 못했습니다.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // 운동 목록 조회
  Future<void> loadExercises({String? target, String? keyword}) async {
    try {
      _exercises = await _repository.getExercises(target: target, keyword: keyword);
      notifyListeners();
    } catch (e) {
      _error = '운동 목록을 불러오지 못했습니다.';
      notifyListeners();
    }
  }

  // 운동 선택/해제
  void toggleExercise(ExerciseModel exercise) {
    if (_selectedExercises.any((e) => e.id == exercise.id)) {
      _selectedExercises.removeWhere((e) => e.id == exercise.id);
    } else {
      _selectedExercises.add(exercise);
    }
    notifyListeners();
  }

  // 선택 초기화
  void clearSelected() {
    _selectedExercises = [];
    notifyListeners();
  }

  // 기존 루틴 운동으로 선택 세팅 (수정 모드)
  void setSelectedFromRoutine(RoutineModel routine) {
    _selectedExercises = routine.exercises
        .map((re) => ExerciseModel(
              id: re.exerciseId,
              name: re.exerciseName,
              target: re.target,
              isCustom: false,
            ))
        .toList();
    notifyListeners();
  }

  // 루틴 추가
  Future<bool> createRoutine(String name) async {
    try {
      final ids = _selectedExercises.map((e) => e.id).toList();
      final routine = await _repository.createRoutine(name, ids);
      _routines.insert(0, routine);
      clearSelected();
      notifyListeners();
      return true;
    } catch (e) {
      _error = '루틴 저장에 실패했습니다.';
      notifyListeners();
      return false;
    }
  }

  // 루틴 수정
  Future<bool> updateRoutine(int routineId, String name) async {
    try {
      final ids = _selectedExercises.map((e) => e.id).toList();
      final updated = await _repository.updateRoutine(routineId, name, ids);
      final idx = _routines.indexWhere((r) => r.id == routineId);
      if (idx != -1) _routines[idx] = updated;
      clearSelected();
      notifyListeners();
      return true;
    } catch (e) {
      _error = '루틴 수정에 실패했습니다.';
      notifyListeners();
      return false;
    }
  }

  // 루틴 삭제
  Future<void> deleteRoutine(int routineId) async {
    try {
      await _repository.deleteRoutine(routineId);
      _routines.removeWhere((r) => r.id == routineId);
      notifyListeners();
    } catch (e) {
      _error = '루틴 삭제에 실패했습니다.';
      notifyListeners();
    }
  }

  // 커스텀 운동 추가
  Future<void> addCustomExercise(String name, String target) async {
    try {
      final exercise = await _repository.createCustomExercise(name, target);
      _exercises.insert(0, exercise);
      notifyListeners();
    } catch (e) {
      _error = '운동 추가에 실패했습니다.';
      notifyListeners();
    }
  }
}
