import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String name;
  final String email;
  final String mobile;
  final String dob;
  final String? avatarUrl;
  final DateTime? createdAt;
  final DateTime? lastLogin;
  final Map<String, dynamic> settings;

  const UserModel({
    required this.uid,
    required this.name,
    required this.email,
    this.mobile = '',
    this.dob = '',
    this.avatarUrl,
    this.createdAt,
    this.lastLogin,
    this.settings = const {},
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return UserModel(
      uid: doc.id,
      name: data['name'] ?? 'User',
      email: data['email'] ?? '',
      mobile: data['mobile'] ?? '',
      dob: data['dob'] ?? '',
      avatarUrl: data['avatar_url'],
      createdAt: (data['created_at'] as Timestamp?)?.toDate(),
      lastLogin: (data['last_login'] as Timestamp?)?.toDate(),
      settings: data['settings'] is Map ? Map<String, dynamic>.from(data['settings']) : {},
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'mobile': mobile,
      'dob': dob,
      if (avatarUrl != null) 'avatar_url': avatarUrl,
      if (createdAt != null) 'created_at': Timestamp.fromDate(createdAt!),
      if (lastLogin != null) 'last_login': Timestamp.fromDate(lastLogin!),
      if (settings.isNotEmpty) 'settings': settings,
    };
  }

  UserModel copyWith({
    String? name,
    String? mobile,
    String? dob,
    String? avatarUrl,
    Map<String, dynamic>? settings,
  }) {
    return UserModel(
      uid: uid,
      name: name ?? this.name,
      email: email,
      mobile: mobile ?? this.mobile,
      dob: dob ?? this.dob,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      createdAt: createdAt,
      lastLogin: lastLogin,
      settings: settings ?? this.settings,
    );
  }
}
