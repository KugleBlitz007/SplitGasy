import 'package:cloud_firestore/cloud_firestore.dart';
import 'app_user.dart';

class Bill {
  final String id;
  final String name;
  final String groupId;
  final String paidById;
  final double amount;
  final DateTime date;
  final String splitMethod;
  final List<Map<String, dynamic>> participants;

  Bill({
    required this.id,
    required this.name,
    required this.groupId,
    required this.paidById,
    required this.amount,
    required this.date,
    required this.splitMethod,
    required this.participants,
  });

  /// Creates an Expense from a Firestore DocumentSnapshot.
  factory Bill.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Bill(
      id: doc.id,
      name: data['name'] ?? '',
      groupId: data['groupId'] ?? '',
      paidById: data['paidById'] ?? '',
      amount: (data['amount'] ?? 0.0).toDouble(),
      date: (data['date'] as Timestamp).toDate(),
      splitMethod: data['splitMethod'] ?? 'equal',
      participants: List<Map<String, dynamic>>.from(data['participants'] ?? []),
    );
  }

  /// Converts the Expense instance to a Map for Firestore.
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'groupId': groupId,
      'paidById': paidById,
      'amount': amount,
      'date': Timestamp.fromDate(date),
      'splitMethod': splitMethod,
      'participants': participants,
    };
  }

  void addExpense() {
    // Code to add expense to Firestore.
  }

  void modifyExpense() {
    // Code to update expense in Firestore.
  }

  void deleteExpense() {
    // Code to delete expense from Firestore.
  }
}
