import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';

class BillListItem extends StatelessWidget {
  final String title;
  final double amount;
  final String paidBy;
  final String paidById;
  final DateTime date;
  final List<Map<String, dynamic>> participants;
  final String splitMethod;

  const BillListItem({
    super.key,
    required this.title,
    required this.amount,
    required this.paidBy,
    required this.paidById,
    required this.date,
    required this.participants,
    required this.splitMethod,
  });

  double _calculateShare(String userId) {
    switch (splitMethod.toLowerCase()) {
      case 'equal':
        return amount / participants.length;
      case 'custom':
        // Find the participant's custom share
        final participant = participants.firstWhere(
          (p) => p['id'] == userId,
          orElse: () => {'share': 0.0},
        );
        return (participant['share'] as num?)?.toDouble() ?? 0.0;
      case 'proportional':
        // TODO: Implement proportional split when that feature is added
        return amount / participants.length;
      default:
        return amount / participants.length;
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return const SizedBox();

    final yourShare = _calculateShare(currentUser.uid);
    double youOwe = 0.0;
    double youAreOwed = 0.0;

    if (paidById == currentUser.uid) {
      // You paid, others owe you
      youAreOwed = amount - yourShare;
    } else {
      // Someone else paid, you owe your share
      youOwe = yourShare;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 15),
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Text(
                  '\$${amount.toStringAsFixed(2)}',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF043E50),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Paid by $paidBy',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                Text(
                  _formatDate(date),
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            if (youOwe > 0 || youAreOwed > 0) ...[
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (youOwe > 0)
                    Text(
                      'You owe: \$${youOwe.toStringAsFixed(2)}',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: const Color.fromARGB(255, 153, 76, 76),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  if (youAreOwed > 0)
                    Text(
                      'You are owed: \$${youAreOwed.toStringAsFixed(2)}',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: const Color.fromARGB(255, 80, 146, 115),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}