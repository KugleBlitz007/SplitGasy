import 'package:cloud_firestore/cloud_firestore.dart';

class Balance {
  final String groupId;
  final String fromUserId;
  final String toUserId;
  final double amount;
  final DateTime lastUpdated;

  Balance({
    required this.groupId,
    required this.fromUserId,
    required this.toUserId,
    required this.amount,
    required this.lastUpdated,
  });

  /// Creates a Balance from a Firestore DocumentSnapshot.
  factory Balance.fromSnapshot(DocumentSnapshot snapshot) {
    final data = snapshot.data() as Map<String, dynamic>;
    return Balance(
      groupId: data['groupId'] as String,
      fromUserId: data['fromUserId'] as String,
      toUserId: data['toUserId'] as String,
      amount: (data['amount'] as num).toDouble(),
      lastUpdated: DateTime.parse(data['lastUpdated'] as String),
    );
  }

  /// Converts the Balance instance to a Map for Firestore.
  Map<String, dynamic> toMap() {
    return {
      'groupId': groupId,
      'fromUserId': fromUserId,
      'toUserId': toUserId,
      'amount': amount,
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }

  // Helper method to update balance in Firestore
  static Future<void> updateBalance(
    String groupId,
    String fromUserId,
    String toUserId,
    double amount,
  ) async {
    final db = FirebaseFirestore.instance;
    
    // Get existing balance document
    final balanceDoc = await db
        .collection('balances')
        .where('groupId', isEqualTo: groupId)
        .where('fromUserId', isEqualTo: fromUserId)
        .where('toUserId', isEqualTo: toUserId)
        .get();

    if (balanceDoc.docs.isEmpty) {
      // Create new balance document
      await db.collection('balances').add({
        'groupId': groupId,
        'fromUserId': fromUserId,
        'toUserId': toUserId,
        'amount': amount,
        'lastUpdated': FieldValue.serverTimestamp(),
      });
    } else {
      // Update existing balance
      final currentAmount = (balanceDoc.docs.first.data()['amount'] as num).toDouble();
      final newAmount = currentAmount + amount;
      
      if (newAmount == 0) {
        // If balance is zero, delete the document
        await balanceDoc.docs.first.reference.delete();
      } else {
        // Update the amount
        await balanceDoc.docs.first.reference.update({
          'amount': newAmount,
          'lastUpdated': FieldValue.serverTimestamp(),
        });
      }
    }
  }

  // Helper method to get all balances for a group
  static Stream<List<Balance>> getGroupBalances(String groupId) {
    return FirebaseFirestore.instance
        .collection('balances')
        .where('groupId', isEqualTo: groupId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Balance.fromMap(doc.data()))
            .toList());
  }

  // Helper method to get user's net balance in a group
  static Stream<double> getUserNetBalance(String groupId, String userId) {
    return FirebaseFirestore.instance
        .collection('balances')
        .where('groupId', isEqualTo: groupId)
        .where('toUserId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) => snapshot.docs.fold(
            0.0,
            (sum, doc) => sum + (doc.data()['amount'] as num).toDouble(),
          ));
  }

  factory Balance.fromMap(Map<String, dynamic> map) {
    return Balance(
      groupId: map['groupId'],
      fromUserId: map['fromUserId'],
      toUserId: map['toUserId'],
      amount: (map['amount'] as num).toDouble(),
      lastUpdated: (map['lastUpdated'] as Timestamp).toDate(),
    );
  }
}
