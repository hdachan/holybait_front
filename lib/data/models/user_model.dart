class UserModel {
  final String uuid;
  final String email;
  final String nickname;
  final String provider;
  final String status;
  final String createdAt;
  final bool marketingAgreed;
  final bool consentCompleted;
  final int totalSteps;

  UserModel({
    required this.uuid,
    required this.email,
    required this.nickname,
    required this.provider,
    required this.status,
    required this.createdAt,
    required this.marketingAgreed,
    required this.consentCompleted,
    this.totalSteps = 0,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
    uuid:              json['uuid'] ?? '',
    email:             json['email'] ?? '',
    nickname:          json['nickname'] ?? '',
    provider:          json['provider']?.toString() ?? '',
    status:            json['status']?.toString() ?? '',
    createdAt:         json['createdAt']?.toString() ?? '',
    marketingAgreed:   json['marketingAgreed'] ?? false,
    consentCompleted:  json['consentCompleted'] ?? false,
    totalSteps:        json['totalSteps'] ?? 0,
  );
}