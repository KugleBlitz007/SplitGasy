import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:splitgasy/Models/app_user.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'search_friends.dart';

class AddGroupPage extends StatefulWidget {
  const AddGroupPage({Key? key}) : super(key: key);

  @override
  State<AddGroupPage> createState() => _AddGroupPageState();
}

class _AddGroupPageState extends State<AddGroupPage> {
  final TextEditingController _groupNameController = TextEditingController();
  final currentUser = FirebaseAuth.instance.currentUser;

  // List of friends using AppUser model
  final List<AppUser> friends = [];
  final Set<String> selectedFriendIds = {};

  @override
  void initState() {
    super.initState();
    _loadFriends();
  }

  // Load friends from Firestore
  Future<void> _loadFriends() async {
    if (currentUser == null) return;

    try {
      // Add current user first
      final currentUserDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser!.uid)
          .get();

      final currentUserData = currentUserDoc.data() as Map<String, dynamic>? ?? {
        'name': currentUser?.displayName ?? 'User',
        'email': currentUser?.email ?? '',
      };

      setState(() {
        friends.clear();
        // Add current user first
        friends.add(AppUser(
          id: currentUser!.uid,
          name: currentUserData['name'],
          email: currentUserData['email'],
        ));
      });

      // Then load friends
      final friendsSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser!.uid)
          .collection('friends')
          .get();

      setState(() {
        for (var doc in friendsSnapshot.docs) {
          friends.add(AppUser(
            id: doc.data()['id'],
            name: doc.data()['name'],
            email: doc.data()['email'] ?? '',
          ));
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading friends: $e')),
        );
      }
    }
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
      // Add current user to the members list
      final currentUserDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser?.uid)
          .get();

      final currentUserData = currentUserDoc.data() as Map<String, dynamic>? ?? {
        'name': currentUser?.displayName ?? 'User',
        'email': currentUser?.email ?? '',
      };

      final currentUserMember = AppUser(
        id: currentUser!.uid,
        name: currentUserData['name'],
        email: currentUserData['email'],
      );

      final allMembers = [currentUserMember, ...selectedFriends];

      // Add a new document to the 'groups' collection in Firestore
      await FirebaseFirestore.instance.collection('groups').add({
        'name': groupName,
        'members': allMembers.map((f) => f.toMap()..addAll({'id': f.id})).toList(),
        'createdAt': FieldValue.serverTimestamp(),
        'createdBy': currentUser!.uid,
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
                          "Select Friends",
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
                          final isCurrentUser = friend.id == currentUser?.uid;
                          return CheckboxListTile(
                            value: isCurrentUser ? true : selectedFriendIds.contains(friend.id),
                            activeColor: const Color(0xFF043E50),
                            checkColor: Colors.white,
                            onChanged: isCurrentUser ? null : (bool? value) {
                              _toggleFriendSelection(friend.id);
                            },
                            title: Text(
                              friend.name + (isCurrentUser ? ' (You)' : ''),
                              style: GoogleFonts.poppins(
                                fontSize: 18,
                                color: Colors.black87,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            subtitle: isCurrentUser ? null : Text(
                              friend.email,
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                            controlAffinity: ListTileControlAffinity.trailing,
                            contentPadding: EdgeInsets.zero,
                          );
                        }).toList(),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Save Button
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: ElevatedButton(
                        onPressed: _saveGroup,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF043E50),
                          minimumSize: const Size(double.infinity, 50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          'Create Group',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
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
