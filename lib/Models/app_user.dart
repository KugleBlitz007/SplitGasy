import 'package:cloud_firestore/cloud_firestore.dart';

class AppUser {
  final String id;
  final String profile;
  final String name;
  final String email;

  AppUser({
    required this.id,
    required this.profile,
    required this.name,
    required this.email,
  });

  /// Creates a User from a Firestore DocumentSnapshot.
  factory AppUser.fromSnapshot(DocumentSnapshot snapshot) {
    final data = snapshot.data() as Map<String, dynamic>;
    return AppUser(
      id: snapshot.id,
      profile: data['profile'] as String,
      name: data['name'] as String,
      email: data['email'] as String,
    );
  }

  /// Converts the User instance to a Map for Firestore.
  Map<String, dynamic> toMap() {
    return {
      'profile': profile,
      'name': name,
      'email': email,
    };
  }

}
