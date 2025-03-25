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
                child: Text(
                  groupName,
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF043E50),
                  ),
                ),
              ),
              if (balance != 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: balance >= 0 
                      ? const Color(0xFFC1FFE1).withOpacity(0.2)
                      : const Color(0xFFFFC2C2).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    balance >= 0 
                      ? "You are owed \$${balance.abs().toStringAsFixed(2)}"
                      : "You owe \$${balance.abs().toStringAsFixed(2)}",
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: balance >= 0 
                        ? const Color(0xFF043E50)
                        : const Color(0xFF043E50),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          // Members list
          Row(
            children: [
              Icon(
                Icons.group,
                size: 16,
                color: Colors.grey[600],
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  _getFormattedMembersString(),
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
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

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 2,
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => GroupPage(
                      groupName: groupName,
                      groupId: groupId,
                    ),
                  ),
                );
              },
              onLongPress: () {
                // Show a dialog with edit and delete options
                showDialog(
                  context: context,
                  builder: (context) {
                    return AlertDialog(
                      title: Text("Select Action", style: GoogleFonts.poppins()),
                      content: Text("Would you like to rename or delete this group?", style: GoogleFonts.poppins()),
                      actions: [
                        //rename group action
                        TextButton(
                          onPressed: () { 
                            // Close the first dialog.
                            Navigator.pop(context);
                            // Then show a second dialog to rename.
                            showDialog(
                              context: context,
                              builder: (context) {
                                // Create a controller pre-filled with the current group name.
                                final TextEditingController renameController = TextEditingController(text: groupName);
                                return AlertDialog(
                                  title: Text("Rename Group", style: GoogleFonts.poppins()),
                                  content: TextField(
                                    controller: renameController,
                                    style: GoogleFonts.poppins(),
                                    decoration: InputDecoration(
                                      labelText: "New Group Name",
                                      labelStyle: GoogleFonts.poppins(),
                                    ),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () async {
                                        final newName = renameController.text.trim();
                                        if (newName.isNotEmpty) {
                                          await FirebaseFirestore.instance
                                              .collection('groups')
                                              .doc(groupId)
                                              .update({'name': newName});
                                        }
                                        Navigator.pop(context); // Close rename dialog.
                                      },
                                      child: Text("Rename", style: GoogleFonts.poppins(color: const Color(0xFF043E50))),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        Navigator.pop(context); // Cancel rename.
                                      },
                                      child: Text("Cancel", style: GoogleFonts.poppins(color: const Color(0xFF043E50))),
                                    ),
                                  ],
                                );
                              },
                            );
                          },
                          child: Text("Rename", style: GoogleFonts.poppins(color: Color(0xFF043E50))),
                        ),

                        //delete group action
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
                          child: Text("Delete", style: GoogleFonts.poppins(color: Colors.red)),
                        ),

                        //cancel 
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          child: Text("Cancel", style: GoogleFonts.poppins(color: Color(0xFF043E50))),
                        ),
                      ],
                    );
                  },
                );
              },
              child: _buildListTile(context, groupBalance),
            ),
          ),
        );
      },
    );
  }
}