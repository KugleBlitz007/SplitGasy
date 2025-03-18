import 'package:cloud_firestore/cloud_firestore.dart';
import '../Models/balance.dart';

class BalanceService {
  static Future<void> updateBalancesForBill(
    String groupId,
    String billId,
    String paidById,
    List<Map<String, dynamic>> participants,
  ) async {
    final db = FirebaseFirestore.instance;
    final billDoc = await db
        .collection('groups')
        .doc(groupId)
        .collection('bills')
        .doc(billId)
        .get();

    if (!billDoc.exists) return;

    final billData = billDoc.data() as Map<String, dynamic>;
    final amount = (billData['amount'] as num).toDouble();

    // Calculate each person's share
    for (var participant in participants) {
      final userId = participant['id'] as String;
      final share = (participant['share'] as num).toDouble();
      final hasPaid = participant['paid'] as bool? ?? false;

      if (!hasPaid) {
        // If this person hasn't paid, they owe the payer
        await Balance.updateBalance(
          groupId,
          userId, // from
          paidById, // to
          share, // amount
        );
      }
    }
  }

  static Future<void> settleUp(
    String groupId,
    String fromUserId,
    String toUserId,
  ) async {
    final db = FirebaseFirestore.instance;
    
    // Get the current balance
    final balanceDoc = await db
        .collection('balances')
        .where('groupId', isEqualTo: groupId)
        .where('fromUserId', isEqualTo: fromUserId)
        .where('toUserId', isEqualTo: toUserId)
        .get();

    if (balanceDoc.docs.isNotEmpty) {
      final currentAmount = (balanceDoc.docs.first.data()['amount'] as num).toDouble();
      
      // Create a settlement record
      await db.collection('settlements').add({
        'groupId': groupId,
        'fromUserId': fromUserId,
        'toUserId': toUserId,
        'amount': currentAmount,
        'date': FieldValue.serverTimestamp(),
      });

      // Delete the balance document
      await balanceDoc.docs.first.reference.delete();
    }
  }

  static Stream<Map<String, double>> getUserBalances(
    String groupId,
    String userId,
  ) {
    return FirebaseFirestore.instance
        .collection('balances')
        .where('groupId', isEqualTo: groupId)
        .where('fromUserId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
          final balances = <String, double>{};
          for (var doc in snapshot.docs) {
            final data = doc.data();
            balances[data['toUserId']] = (data['amount'] as num).toDouble();
          }
          return balances;
        });
  }

  static Stream<Map<String, double>> getBalancesWithUser(
    String groupId,
    String userId,
  ) {
    // Create a stream that combines both owed and owing balances
    return FirebaseFirestore.instance
        .collection('balances')
        .where('groupId', isEqualTo: groupId)
        .where('toUserId', isEqualTo: userId)
        .snapshots()
        .map((owedToUser) {
          final balances = <String, double>{};
          
          // Add money owed to user (positive)
          for (var doc in owedToUser.docs) {
            final data = doc.data();
            balances[data['fromUserId']] = (data['amount'] as num).toDouble();
          }
          
          return balances;
        })
        .asyncMap((balances) async {
          // Get money user owes (negative)
          final userOwes = await FirebaseFirestore.instance
              .collection('balances')
              .where('groupId', isEqualTo: groupId)
              .where('fromUserId', isEqualTo: userId)
              .get();

          // Subtract money user owes
          for (var doc in userOwes.docs) {
            final data = doc.data();
            final currentBalance = balances[data['toUserId']] ?? 0.0;
            balances[data['toUserId']] = currentBalance - (data['amount'] as num).toDouble();
          }
          
          return balances;
        });
  }
} 