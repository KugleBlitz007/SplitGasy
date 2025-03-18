import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:splitgasy/Models/bill_calculation.dart';

class BillCalculationService {
  static Future<List<BillCalculation>> getBillCalculations(
    String groupId,
    String currentUserId,
    String currentUserName,
    List<Map<String, dynamic>> members,
  ) async {
    final billsSnapshot = await FirebaseFirestore.instance
        .collection('groups')
        .doc(groupId)
        .collection('bills')
        .orderBy('date', descending: true)
        .get();

    return billsSnapshot.docs
        .map((bill) => BillCalculation.fromBill(
              bill,
              currentUserId,
              currentUserName,
              members,
            ))
        .where((calc) => !calc.isZero) // Only include non-zero balances
        .toList();
  }

  static double calculateOverallBalance(List<BillCalculation> calculations) {
    return calculations.fold(0.0, (sum, calc) => sum + calc.balance);
  }

  static Map<String, double> calculateBalancesByPerson(
    List<BillCalculation> calculations,
    List<Map<String, dynamic>> members,
  ) {
    final Map<String, double> balances = {};
    
    for (var member in members) {
      balances[member['id']] = 0.0;
    }

    for (var calc in calculations) {
      if (calc.paidById == calc.paidById) {
        // You paid, others owe you
        balances[calc.paidById] = (balances[calc.paidById] ?? 0.0) + calc.balance;
      } else {
        // Someone else paid, you owe them
        balances[calc.paidById] = (balances[calc.paidById] ?? 0.0) + calc.balance;
      }
    }

    return balances;
  }
} 