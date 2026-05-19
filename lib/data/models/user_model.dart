class UserModel {
  final String uuid;
  final String email;
  final String nickname;
  final String provider;
  final String status;
  final String? createdAt;

  UserModel({
    required this.uuid,
    required this.email,
    required this.nickname,
    required this.provider,
    required this.status,
    this.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
    uuid:      json['uuid']      as String,
    email:     json['email']     as String,
    nickname:  json['nickname']  as String,
    provider:  json['provider']  as String,
    status:    json['status']    as String,
    createdAt: json['createdAt'] as String?,
  );
}
