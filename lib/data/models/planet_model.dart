// 탐험 구역 (기존 StageModel과 동일하게 매핑)
class PlanetStageModel {
  final int id;
  final String name;
  final String description;
  final int minLevel;
  final int maxLevel;
  final int shoeCoinCost;
  final String? imageKey;
  final int sortOrder;

  PlanetStageModel({
    required this.id,
    required this.name,
    required this.description,
    required this.minLevel,
    required this.maxLevel,
    required this.shoeCoinCost,
    this.imageKey,
    required this.sortOrder,
  });

  factory PlanetStageModel.fromJson(Map<String, dynamic> json) =>
      PlanetStageModel(
        id: json['id'],
        name: json['name'],
        description: json['description'] ?? '',
        minLevel: json['minLevel'],
        maxLevel: json['maxLevel'],
        shoeCoinCost: json['shoeCoinCost'],
        imageKey: json['imageKey'],
        sortOrder: json['sortOrder'] ?? 1,
      );
}

// 행성 모델
class PlanetModel {
  final int id;
  final String name;
  final String? description;
  final String? imageKey;
  final String? theme;
  final String? interviewPersonName;
  final String? interviewPersonJob;
  final List<PlanetStageModel> stages;

  PlanetModel({
    required this.id,
    required this.name,
    this.description,
    this.imageKey,
    this.theme,
    this.interviewPersonName,
    this.interviewPersonJob,
    required this.stages,
  });

  factory PlanetModel.fromJson(Map<String, dynamic> json) => PlanetModel(
    id: json['id'],
    name: json['name'],
    description: json['description'],
    imageKey: json['imageKey'],
    theme: json['theme'],
    interviewPersonName: json['interviewPersonName'],
    interviewPersonJob: json['interviewPersonJob'],
    stages: (json['stages'] as List? ?? [])
        .map((e) => PlanetStageModel.fromJson(e))
        .toList(),
  );
}