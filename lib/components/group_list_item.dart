import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:splitgasy/pages/group_page.dart';

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

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 15),
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      child: GestureDetector(
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
                          final TextEditingController _renameController = TextEditingController(text: groupName);
                          return AlertDialog(
                            title: Text("Rename Group", style: GoogleFonts.poppins()),
                            content: TextField(
                              controller: _renameController,
                              style: GoogleFonts.poppins(),
                              decoration: InputDecoration(
                                labelText: "New Group Name",
                                labelStyle: GoogleFonts.poppins(),
                              ),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () async {
                                  final newName = _renameController.text.trim();
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
                      // Delete the group from Firestore.
                      await FirebaseFirestore.instance
                          .collection('groups')
                          .doc(groupId)
                          .delete();
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
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          title: Text(
            groupName,
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          subtitle: Text(
            membersString, // e.g., "David, Nael, Mbola"
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          onTap: () {
            // Navigate to GroupPage with the groupName.
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
        ),
      ),
    );
  }
}