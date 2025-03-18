import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class GroupProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Map<String, dynamic>> _groups = [];

  List<Map<String, dynamic>> get groups => _groups;

  Future<void> fetchGroups() async {
    final snapshot = await _firestore.collection('groups').get();
    _groups = snapshot.docs.map((doc) => doc.data()).toList();
    notifyListeners();
  }

  Future<void> addGroup(String name, List<String> members) async {
    await _firestore.collection('groups').add({
      'name': name,
      'members': members.join(', '),
    });
    fetchGroups(); // Refresh the list after adding a group
  }
}