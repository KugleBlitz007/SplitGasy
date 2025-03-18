import 'package:cloud_firestore/cloud_firestore.dart';
import 'app_user.dart';

class Balance {
  final String userId;
  final String groupId;
  final double amount;
  final DateTime lastUpdated;

  Balance({
    required this.userId,
    required this.groupId,
    required this.amount,
    required this.lastUpdated,
  });

  /// Creates a Balance from a Firestore DocumentSnapshot.
  factory Balance.fromSnapshot(DocumentSnapshot snapshot) {
    final data = snapshot.data() as Map<String, dynamic>;
    return Balance(
      userId: data['userId'] as String,
      groupId: data['groupId'] as String,
      amount: (data['amount'] as num).toDouble(),
      lastUpdated: DateTime.parse(data['lastUpdated'] as String),
    );
  }

  /// Converts the Balance instance to a Map for Firestore.
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'groupId': groupId,
      'amount': amount,
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }

  void updateBalance(double newAmount) {
    // Update Firestore document if needed.
  }

  factory Balance.fromMap(Map<String, dynamic> map) {
    return Balance(
      userId: map['userId'],
      groupId: map['groupId'],
      amount: map['amount'].toDouble(),
      lastUpdated: DateTime.parse(map['lastUpdated']),
    );
  }
}
