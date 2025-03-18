import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class BillListItem extends StatelessWidget {
  final String title;
  final List<String> items;
  final VoidCallback? onViewDetails;

  const BillListItem({
    super.key,
    required this.title,
    this.items = const [],
    this.onViewDetails,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ExpansionTile(
        title: Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF333533),
          ),
        ),
        children: [
          // Expense items
          ...items.map((item) {
            return ListTile(
              title: Text(
                item,
                style: GoogleFonts.poppins(fontSize: 14),
              ),
              trailing: Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                // Navigate to expense detail when tapped
                if (onViewDetails != null) {
                  onViewDetails!();
                }
              },
            );
          }),
          
        ],
      ),
    );
  }
}