import '../core/utils.dart';

class UserModel {
  final String uid;
  final String email;
  final String displayName;
  final String role;
  
  // Ressources persistantes
  final int piecesOr;
  final DateTime? lastLoginAt;

  UserModel({
    required this.uid,
    required this.email,
    required this.displayName,
    this.role = 'player',
    this.piecesOr = 50,
    this.lastLoginAt,
  });

  UserModel copyWith({
    String? uid,
    String? email,
    String? displayName,
    String? role,
    int? piecesOr,
    DateTime? lastLoginAt,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      role: role ?? this.role,
      piecesOr: piecesOr ?? this.piecesOr,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
    );
  }

  bool get isAdmin => role == 'admin' || role == 'superAdmin';
  bool get isSuperAdmin => role == 'superAdmin';

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'role': role,
      'piecesOr': piecesOr,
      'lastLoginAt': lastLoginAt?.toIso8601String(),
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      email: map['email'] ?? '',
      displayName: map['displayName'] ?? '',
      role: map['role'] ?? 'player',
      piecesOr: ArchipelUtils.toInt(map['piecesOr']),
      lastLoginAt: map['lastLoginAt'] != null ? DateTime.parse(map['lastLoginAt']) : null,
    );
  }
}
