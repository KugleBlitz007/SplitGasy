import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class BillProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Map<String, dynamic>> _bills = [];

  List<Map<String, dynamic>> get bills => _bills;

  Future<void> fetchBills(String groupId) async {
    final snapshot = await _firestore
        .collection('groups')
        .doc(groupId)
        .collection('bills')
        .get();
    _bills = snapshot.docs.map((doc) => doc.data()).toList();
    notifyListeners();
  }

  Future<void> addBill(String groupId, Map<String, dynamic> bill) async {
    await _firestore
        .collection('groups')
        .doc(groupId)
        .collection('bills')
        .add(bill);
    fetchBills(groupId); // Refresh the list after adding a bill
  }
}