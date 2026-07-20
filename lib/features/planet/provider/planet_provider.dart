import 'package:flutter/material.dart';
import '../../../data/datasources/planet_remote_ds.dart';
import '../../../data/models/planet_model.dart';

class PlanetProvider extends ChangeNotifier {
  final _remote = PlanetRemoteDataSource();

  List<PlanetModel> planets = [];
  PlanetModel? selectedPlanet;
  bool isLoading = false;
  String? error;

  Future<void> loadPlanets() async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      planets = await _remote.getPlanets();
    } catch (e) {
      error = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> selectPlanet(int planetId) async {
    isLoading = true;
    notifyListeners();
    try {
      selectedPlanet = await _remote.getPlanet(planetId);
    } catch (e) {
      error = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}