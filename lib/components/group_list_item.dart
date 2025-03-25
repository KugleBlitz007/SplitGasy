import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:splitgasy/pages/group_page.dart';
import 'package:firebase_auth/firebase_auth.dart';

class GroupListItem extends StatelessWidget {
  final String groupId;
  final String groupName;
  final String membersString;

  const GroupListItem({
    super.key,
    required this.groupId,
    required this.groupName,
    required this.membersString,
  });

  String _getFormattedMembersString() {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return membersString;

    // Split the members string into a list
    final members = membersString.split(', ');
    
    // Replace the current user's name with "You"
    final formattedMembers = members.map((member) {
      if (member == currentUser.displayName) {
        return 'You';
      }
      return member;
    });

    return formattedMembers.join(', ');
  }

  Widget _buildListTile(BuildContext context, double balance) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Group name and balance row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      groupName,
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF043E50),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.group,
                          size: 16,
                          color: const Color(0xFF6B7280),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            _getFormattedMembersString(),
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: const Color(0xFF6B7280),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: balance == 0
                      ? const Color(0xFFDCFCE7).withOpacity(0.5)
                      : balance > 0 
                          ? const Color(0xFFDCFCE7).withOpacity(0.5)
                          : const Color(0xFFFEE2E2).withOpacity(0.5),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      balance == 0
                          ? Icons.check_circle
                          : balance > 0 
                              ? Icons.arrow_downward 
                              : Icons.arrow_upward,
                      size: 16,
                      color: balance == 0
                          ? const Color(0xFF059669)
                          : balance > 0 
                              ? const Color(0xFF059669)
                              : const Color(0xFFDC2626),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      balance == 0
                          ? "All settled up!"
                          : balance > 0 
                              ? "You are owed \$${balance.abs().toStringAsFixed(2)}"
                              : "You owe \$${balance.abs().toStringAsFixed(2)}",
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: balance == 0
                            ? const Color(0xFF059669)
                            : balance > 0 
                                ? const Color(0xFF059669)
                                : const Color(0xFFDC2626),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('balances')
          .where('groupId', isEqualTo: groupId)
          .snapshots(),
      builder: (context, snapshot) {
        double groupBalance = 0.0;
        
        if (snapshot.hasData && currentUser != null) {
          for (var doc in snapshot.data!.docs) {
            final data = doc.data() as Map<String, dynamic>;
            final amount = (data['amount'] as num).toDouble();
            final fromUserId = data['fromUserId'] as String;
            final toUserId = data['toUserId'] as String;

            if (fromUserId == currentUser.uid) {
              // Current user owes money
              groupBalance -= amount;
            } else if (toUserId == currentUser.uid) {
              // Current user is owed money
              groupBalance += amount;
            }
          }
        }

        return GestureDetector(
          onLongPress: () {
            showDialog(
              context: context,
              builder: (context) {
                return AlertDialog(
                  title: Text(
                    "Group Options",
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ListTile(
                        leading: const Icon(Icons.edit, color: Color(0xFF043E50)),
                        title: Text(
                          "Rename Group",
                          style: GoogleFonts.poppins(),
                        ),
                        onTap: () {
                          Navigator.pop(context);
                          // Show rename dialog
                          showDialog(
                            context: context,
                            builder: (context) {
                              final TextEditingController controller = TextEditingController(text: groupName);
                              return AlertDialog(
                                title: Text(
                                  "Rename Group",
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                content: TextField(
                                  controller: controller,
                                  autofocus: true,
                                  decoration: InputDecoration(
                                    hintText: "Enter new group name",
                                    hintStyle: GoogleFonts.poppins(),
                                  ),
                                  style: GoogleFonts.poppins(),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () {
                                      Navigator.pop(context);
                                    },
                                    child: Text(
                                      "Cancel",
                                      style: GoogleFonts.poppins(
                                        color: const Color(0xFF043E50),
                                      ),
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () async {
                                      final newName = controller.text.trim();
                                      if (newName.isNotEmpty) {
                                        await FirebaseFirestore.instance
                                            .collection('groups')
                                            .doc(groupId)
                                            .update({'name': newName});
                                      }
                                      Navigator.pop(context);
                                    },
                                    child: Text(
                                      "Rename",
                                      style: GoogleFonts.poppins(
                                        color: const Color(0xFF043E50),
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            },
                          );
                        },
                      ),
                      ListTile(
                        leading: const Icon(Icons.delete, color: Colors.red),
                        title: Text(
                          "Delete Group",
                          style: GoogleFonts.poppins(),
                        ),
                        onTap: () {
                          Navigator.pop(context);
                          // Show delete confirmation dialog
                          showDialog(
                            context: context,
                            builder: (context) {
                              return AlertDialog(
                                title: Text(
                                  "Delete Group",
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                content: Text(
                                  "Are you sure you want to delete this group?",
                                  style: GoogleFonts.poppins(),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () async {
                                      // Delete all balances associated with the group
                                      final balancesSnapshot = await FirebaseFirestore.instance
                                          .collection('balances')
                                          .where('groupId', isEqualTo: groupId)
                                          .get();
                                      
                                      // Create a batch operation for efficient deletion
                                      final batch = FirebaseFirestore.instance.batch();
                                      
                                      // Add balance deletions to batch
                                      for (var doc in balancesSnapshot.docs) {
                                        batch.delete(doc.reference);
                                      }
                                      
                                      // Add group deletion to batch
                                      batch.delete(FirebaseFirestore.instance
                                          .collection('groups')
                                          .doc(groupId));
                                      
                                      // Execute all deletions in a single atomic operation
                                      await batch.commit();
                                      
                                      Navigator.pop(context);
                                    },
                                    child: Text(
                                      "Delete",
                                      style: GoogleFonts.poppins(color: Colors.red),
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      Navigator.pop(context);
                                    },
                                    child: Text(
                                      "Cancel",
                                      style: GoogleFonts.poppins(
                                        color: const Color(0xFF043E50),
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            },
                          );
                        },
                      ),
                    ],
                  ),
                );
              },
            );
          },
          child: Card(
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
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF043E50).withOpacity(0.04),
                    offset: const Offset(0, 4),
                    blurRadius: 8,
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => GroupPage(
                          groupId: groupId,
                          groupName: groupName,
                        ),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(10),
                  child: _buildListTile(context, groupBalance),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}