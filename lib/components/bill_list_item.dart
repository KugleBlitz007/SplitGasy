import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';

class BillListItem extends StatefulWidget {
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

  @override
  State<BillListItem> createState() => _BillListItemState();
}

class _BillListItemState extends State<BillListItem> {
  bool _isExpanded = false;

  double _calculateShare(String userId) {
    switch (widget.splitMethod.toLowerCase()) {
      case 'equal':
        return widget.amount / widget.participants.length;
      case 'custom':
        // Find the participant's custom share
        final participant = widget.participants.firstWhere(
          (p) => p['id'] == userId,
          orElse: () => {'share': 0.0},
        );
        return (participant['share'] as num?)?.toDouble() ?? 0.0;
      case 'proportional':
        // Find the participant's share based on their percentage
        final participant = widget.participants.firstWhere(
          (p) => p['id'] == userId,
          orElse: () => {'share': 0.0},
        );
        return (participant['share'] as num?)?.toDouble() ?? 0.0;
      default:
        return widget.amount / widget.participants.length;
    }
  }

  Widget _buildSplitDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(height: 24),
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            'Split Details',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey[800],
            ),
          ),
        ),
        ...widget.participants.map((participant) {
          final share = _calculateShare(participant['id']);
          final percentage = (share / widget.amount * 100).toStringAsFixed(1);
          
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    participant['name'],
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.grey[700],
                    ),
                  ),
                ),
                Row(
                  children: [
                    if (widget.splitMethod.toLowerCase() == 'proportional') ...[
                      Text(
                        '$percentage%',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                    Text(
                      '\$${share.toStringAsFixed(2)}',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: const Color(0xFF043E50),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return const SizedBox();

    final yourShare = _calculateShare(currentUser.uid);
    double youOwe = 0.0;
    double youAreOwed = 0.0;

    if (widget.paidById == currentUser.uid) {
      // You paid, others owe you
      youAreOwed = widget.amount - yourShare;
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
        side: BorderSide(
          color: Colors.grey.shade200,
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: () => setState(() => _isExpanded = !_isExpanded),
        borderRadius: BorderRadius.circular(10),
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.title,
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF043E50),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFF043E50).withOpacity(0.06),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Row(
                                children: [
                                  Text(
                                    widget.splitMethod.toLowerCase(),
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      color: const Color(0xFF043E50),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  AnimatedRotation(
                                    duration: const Duration(milliseconds: 200),
                                    turns: _isExpanded ? 0.5 : 0,
                                    child: Icon(
                                      Icons.keyboard_arrow_down,
                                      size: 16,
                                      color: const Color(0xFF043E50),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF043E50).withOpacity(0.06),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '\$${widget.amount.toStringAsFixed(2)}',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF043E50),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.person,
                        size: 16,
                        color: Color(0xFF6B7280),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Paid by ${widget.paidBy}',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: const Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                  Text(
                    _formatDate(widget.date),
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: const Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
              if (youOwe > 0 || youAreOwed > 0) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: youOwe > 0 
                      ? const Color(0xFFFEE2E2).withOpacity(0.5)
                      : const Color(0xFFDCFCE7).withOpacity(0.5),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        youOwe > 0 ? Icons.arrow_upward : Icons.arrow_downward,
                        size: 16,
                        color: youOwe > 0 
                          ? const Color(0xFFDC2626)
                          : const Color(0xFF059669),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        youOwe > 0
                          ? 'You owe: \$${youOwe.toStringAsFixed(2)}'
                          : 'You are owed: \$${youAreOwed.toStringAsFixed(2)}',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: youOwe > 0 
                            ? const Color(0xFFDC2626)
                            : const Color(0xFF059669),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              AnimatedCrossFade(
                firstChild: const SizedBox.shrink(),
                secondChild: _buildSplitDetails(),
                crossFadeState: _isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                duration: const Duration(milliseconds: 200),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}