import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:splitgasy/Models/app_user.dart';
import 'search_friends.dart';

class AddGroupPage extends StatefulWidget {
  const AddGroupPage({Key? key}) : super(key: key);

  @override
  State<AddGroupPage> createState() => _AddGroupPageState();
}

class _AddGroupPageState extends State<AddGroupPage> {
  final TextEditingController _groupNameController = TextEditingController();

  // List of friends using AppUser model
  final List<AppUser> friends = [];
  final Set<String> selectedFriendIds = {};

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
    _groupNameController.dispose();
    super.dispose();
  }

  // Toggles selection of a friend from the list
  void _toggleFriendSelection(String userId) {
    setState(() {
      if (selectedFriendIds.contains(userId)) {
        selectedFriendIds.remove(userId);
      } else {
        selectedFriendIds.add(userId);
      }
    });
  }

  // Saves the new group to Firestore
  Future<void> _saveGroup() async {
    final groupName = _groupNameController.text.trim();

    if (groupName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Group name cannot be empty')),
      );
      return;
    }

    final selectedFriends = friends
        .where((f) => selectedFriendIds.contains(f.id))
        .toList();

    if (selectedFriends.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one friend')),
      );
      return;
    }

    try {
      // Add a new document to the 'groups' collection in Firestore
      await FirebaseFirestore.instance.collection('groups').add({
        'name': groupName,
        'members': selectedFriends.map((f) => f.toMap()..addAll({'id': f.id})).toList(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Group created successfully!')),
      );

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error creating group: $e')),
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
      backgroundColor: const Color(0xFFE0E0E0),
      body: SafeArea(
        child: Column(
          children: [
            // TOP SECTION
            Container(
              padding: const EdgeInsets.only(left: 20, right: 20, top: 20, bottom: 30),
              decoration: const BoxDecoration(
                color: Color.fromARGB(255, 1, 87, 77),
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
                    "Create a group",
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 20),

                  TextField(
                    controller: _groupNameController,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: Colors.black,
                    ),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white,
                      hintText: 'Group Name',
                      hintStyle: GoogleFonts.poppins(
                        color: Colors.grey[600],
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // FRIENDS LIST SECTION
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          "Select Friends",
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: const Color.fromARGB(255, 1, 87, 77),
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
                          return CheckboxListTile(
                            value: selectedFriendIds.contains(friend.id),
                            activeColor: const Color.fromARGB(255, 1, 87, 77),
                            onChanged: (bool? value) {
                              _toggleFriendSelection(friend.id);
                            },
                            title: Text(
                              friend.name,
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: Colors.black87,
                              ),
                            ),
                            subtitle: Text(
                              friend.email,
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                            controlAffinity: ListTileControlAffinity.trailing,
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
                            backgroundColor: const Color.fromARGB(255, 1, 87, 77),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(
                            "Save",
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
          ],
        ),
      ),
    );
  }
}
