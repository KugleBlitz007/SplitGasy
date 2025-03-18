import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:splitgasy/Models/app_user.dart';
import 'search_friends.dart';

class EditGroupPage extends StatefulWidget {
  final String groupId;
  final String groupName;
  final List<AppUser> currentMembers;

  const EditGroupPage({
    Key? key,
    required this.groupId,
    required this.groupName,
    required this.currentMembers,
  }) : super(key: key);

  @override
  State<EditGroupPage> createState() => _EditGroupPageState();
}

class _EditGroupPageState extends State<EditGroupPage> {
  // List of friends using AppUser model
  final List<AppUser> friends = [];
  final Set<String> selectedFriendIds = {};

  @override
  void initState() {
    super.initState();
    // Initialize friends list with current members
    friends.addAll(widget.currentMembers);
  }

  // Navigate to SearchPage and Get Selected Users
  Future<void> openSearchPage() async {
    final List<AppUser>? selectedUsers = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => SearchPage(existingFriends: friends)),
    );

    if (selectedUsers != null && selectedUsers.isNotEmpty) {
      setState(() {
        for (var user in selectedUsers) {
          if (!friends.any((friend) => friend.id == user.id)) {
            friends.add(user);
          }
        }
      });
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  // Updates the group members in Firestore
  Future<void> _saveGroup() async {
    if (friends.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one friend')),
      );
      return;
    }

    try {
      // Get the group document reference
      final groupRef = FirebaseFirestore.instance.collection('groups').doc(widget.groupId);

      // Update the members list in the group document
      await groupRef.update({
        'members': friends.map((f) => f.toMap()..addAll({'id': f.id})).toList(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Group updated successfully!')),
      );

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating group: $e')),
      );
    }
  }

  // Called when the "Add friends" icon is tapped
  void _addFriend() async {
    final List<AppUser>? selectedUsers = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SearchPage(existingFriends: friends),
      ),
    );

    if (selectedUsers != null && selectedUsers.isNotEmpty) {
      setState(() {
        for (var user in selectedUsers) {
          if (!friends.any((friend) => friend.id == user.id)) {
            friends.add(user);
          }
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF043E50),
      body: Column(
        children: [
          // TOP SECTION
          Container(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: MediaQuery.of(context).padding.top + 20,
              bottom: 30
            ),
            decoration: const BoxDecoration(
              color: Color(0xFF043E50),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    Column(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.group_add, color: Colors.white),
                          onPressed: _addFriend,
                        ),
                        Text(
                          "Add friends",
                          style: GoogleFonts.poppins(
                            color: Colors.white70,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  "Edit Group: ${widget.groupName}",
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          // FRIENDS LIST SECTION
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                color: Color(0xFFE0E0E0),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          "Group Members",
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF043E50),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),

                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 20),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: friends.map((friend) {
                          return ListTile(
                            title: Text(
                              friend.name,
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: Colors.black87,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            subtitle: Text(
                              friend.email,
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.remove_circle_outline),
                              onPressed: () {
                                setState(() {
                                  friends.removeWhere((f) => f.id == friend.id);
                                });
                              },
                            ),
                          );
                        }).toList(),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // SAVE button
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _saveGroup,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF043E50),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(
                            "Save Changes",
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
} 