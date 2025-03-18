import 'package:cloud_firestore/cloud_firestore.dart';
import 'app_user.dart';

class Expense {
  final String id;
  final String description;
  final double amount;
  final AppUser paidBy;
  final Map<String, double> shares;
  final DateTime date;

  Expense({
    required this.id,
    required this.description,
    required this.amount,
    required this.paidBy,
    required this.shares,
    required this.date,
  });

  /// Creates an Expense from a Firestore DocumentSnapshot.
  factory Expense.fromSnapshot(DocumentSnapshot snapshot) {
    final data = snapshot.data() as Map<String, dynamic>;
    return Expense(
      id: snapshot.id,
      description: data['description'] as String,
      amount: (data['amount'] as num).toDouble(),
      paidBy: AppUser(
        id: data['paidBy']['id'] as String,
        name: data['paidBy']['name'] as String,
        email: data['paidBy']['email'] as String,
      ),
      shares: Map<String, double>.from(
        (data['shares'] as Map).map(
          (key, value) => MapEntry(key, (value as num).toDouble()),
        ),
      ),
      date: (data['date'] as Timestamp).toDate(),
    );
  }

  /// Converts the Expense instance to a Map for Firestore.
  Map<String, dynamic> toMap() {
    return {
      'description': description,
      'amount': amount,
      'paidBy': {
        'id': paidBy.id,
        'name': paidBy.name,
        'email': paidBy.email,
      },
      'shares': shares,
      'date': date, // Consider converting to a Timestamp if needed.
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
