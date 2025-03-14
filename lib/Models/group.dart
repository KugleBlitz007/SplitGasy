import 'package:cloud_firestore/cloud_firestore.dart';
import 'app_user.dart';

class Group {
  final String id;
  final String profile; // e.g., a URL or asset path for the group image.
  String name;
  List<AppUser> members;

  Group({
    required this.id,
    required this.profile,
    required this.name,
    required this.members,
  });

  /// Creates a Group from a Firestore DocumentSnapshot.
  factory Group.fromSnapshot(DocumentSnapshot snapshot) {
    final data = snapshot.data() as Map<String, dynamic>;

    // Assuming members are stored as a list of maps.
    final membersData = data['members'] as List<dynamic>? ?? [];
    List<AppUser> members = membersData.map((memberData) {
      return AppUser(
        id: memberData['id'] as String,
        profile: memberData['profile'] as String,
        name: memberData['name'] as String,
        email: memberData['email'] as String,
      );
    }).toList();

    return Group(
      id: snapshot.id,
      profile: data['profile'] as String? ?? '',
      name: data['name'] as String,
      members: members,
    );
  }

  /// Converts the Group instance to a Map for Firestore.
  Map<String, dynamic> toMap() {
    return {
      'profile': profile,
      'name': name,
      'members': members
          .map((user) => user.toMap()..addAll({'id': user.id}))
          .toList(),
    };
  }

  void removeGroup(AppUser user) {
    members.add(user);
    // Optionally update Firestore.
  }

  void modifyGroup(AppUser user) {
    members.removeWhere((u) => u.id == user.id);
    // Optionally update Firestore.
  }

}
