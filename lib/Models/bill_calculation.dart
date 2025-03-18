import 'package:cloud_firestore/cloud_firestore.dart';

class BillCalculation {
  final String billId;
  final String billName;
  final double amount;
  final String paidById;
  final String paidByName;
  final double yourShare;
  final double balance;
  final DateTime date;

  BillCalculation({
    required this.billId,
    required this.billName,
    required this.amount,
    required this.paidById,
    required this.paidByName,
    required this.yourShare,
    required this.balance,
    required this.date,
  });

  factory BillCalculation.fromBill(
    DocumentSnapshot bill,
    String currentUserId,
    String currentUserName,
    List<Map<String, dynamic>> members,
  ) {
    final data = bill.data() as Map<String, dynamic>;
    final participants = List<Map<String, dynamic>>.from(data['participants']);
    
    // Find your share in this bill
    final yourParticipant = participants.firstWhere(
      (p) => p['id'] == currentUserId,
      orElse: () => {'share': 0.0},
    );
    final yourShare = (yourParticipant['share'] as num?)?.toDouble() ?? 
        (data['amount'] as num).toDouble() / participants.length;

    // Calculate balance
    final paidById = data['paidById'] as String;
    final balance = paidById == currentUserId
        ? (data['amount'] as num).toDouble() - yourShare  // You paid, others owe you
        : -yourShare;  // Someone else paid, you owe them

    // Get payer's name
    final payer = members.firstWhere(
      (m) => m['id'] == paidById,
      orElse: () => {'name': 'Unknown'},
    );

    return BillCalculation(
      billId: bill.id,
      billName: data['name'] as String,
      amount: (data['amount'] as num).toDouble(),
      paidById: paidById,
      paidByName: payer['name'] as String,
      yourShare: yourShare,
      balance: balance,
      date: (data['date'] as Timestamp).toDate(),
    );
  }

  bool get isPositive => balance > 0;
  bool get isNegative => balance < 0;
  bool get isZero => balance == 0;
} 