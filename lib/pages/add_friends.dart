import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:splitgasy/Models/app_user.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AddFriendsPage extends StatefulWidget {
  final List<AppUser>? existingFriends;
  final bool showInviteButton;

  const AddFriendsPage({
    super.key, 
    this.existingFriends,
    this.showInviteButton = true,
  });

  @override
  _AddFriendsPageState createState() => _AddFriendsPageState();
}

class _AddFriendsPageState extends State<AddFriendsPage> {
  final TextEditingController _searchController = TextEditingController();
  List<AppUser> allUsers = [];
  List<AppUser> searchResults = [];
  List<AppUser> selectedUsers = [];
  bool isLoading = true;
  final currentUser = FirebaseAuth.instance.currentUser;
  Map<String, bool> isFriendMap = {};

  @override
  void initState() {
    super.initState();
    _loadAllUsers();
  }

  // Load all users from Firestore
  Future<void> _loadAllUsers() async {
    try {
      if (currentUser == null) return;

      // First, get all users
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .get();

      final users = snapshot.docs
          .where((doc) => doc.id != currentUser?.uid)
          .map((doc) => AppUser(
                id: doc.id,
                name: doc['name'] ?? 'Unknown User',
                email: doc['email'] ?? '',
              ))
          .toList();

      // Then, get the current user's friends
      final friendsSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser!.uid)
          .collection('friends')
          .get();

      // Create a map of friend IDs
      final friendIds = friendsSnapshot.docs.map((doc) => doc.id).toSet();

      // Update the isFriendMap for each user
      for (var user in users) {
        isFriendMap[user.id] = friendIds.contains(user.id);
      }

      setState(() {
        allUsers = users;
        searchResults = users;
        isLoading = false;
      });
    } catch (e) {
      print('Error loading users: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  // Search Users
  void searchUsers(String query) {
    if (query.isEmpty) {
      setState(() {
        searchResults = allUsers;
      });
      return;
    }

    String lowerQuery = query.toLowerCase();
    setState(() {
      searchResults = allUsers
          .where((user) => 
              user.name.toLowerCase().contains(lowerQuery) ||
              user.email.toLowerCase().contains(lowerQuery))
          .toList();
    });
  }

  // Toggle User Selection
  void toggleUserSelection(AppUser user) {
    setState(() {
      if (selectedUsers.contains(user)) {
        selectedUsers.remove(user);
      } else {
        selectedUsers.add(user);
      }
    });
  }

  // Confirm Selection & Return to Previous Screen
  void confirmSelection() {
    Navigator.pop(context, selectedUsers);
  }

  // Send invitation to a user
  Future<void> _sendInvitation(AppUser user) async {
    try {
      final batch = FirebaseFirestore.instance.batch();
      
      // Get current user's data
      final currentUserDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser?.uid)
          .get();
      final currentUserData = currentUserDoc.data() as Map<String, dynamic>;

      // Create invitation document
      final invitationRef = FirebaseFirestore.instance
          .collection('users')
          .doc(user.id)
          .collection('invitations')
          .doc();

      // Add invitation to recipient's invitations
      batch.set(invitationRef, {
        'type': 'friend_request',
        'fromUserId': currentUser?.uid,
        'fromUserName': currentUserData['name'],
        'fromUserEmail': currentUserData['email'],
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'pending',
      });

      // Add notification to recipient's activity
      final activityRef = FirebaseFirestore.instance
          .collection('users')
          .doc(user.id)
          .collection('activity')
          .doc();

      batch.set(activityRef, {
        'type': 'friend_request',
        'fromUserId': currentUser?.uid,
        'fromUserName': currentUserData['name'],
        'fromUserEmail': currentUserData['email'],
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'pending',
        'invitationId': invitationRef.id,
      });

      await batch.commit();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 8),
              Text(
                'Invitation sent to ${user.name}',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF043E50),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white),
              const SizedBox(width: 8),
              Text(
                'Error sending invitation: $e',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF043E50),
      body: SafeArea(
        child: Column(
          children: [
            // Custom AppBar
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Color(0xFF043E50),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    widget.showInviteButton ? "Add Friends" : "Select Friends",
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  if (!widget.showInviteButton && selectedUsers.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.check, color: Colors.white),
                      onPressed: confirmSelection,
                    ),
                ],
              ),
            ),

            // Search and Results
            Expanded(
              child: Container(
                color: const Color(0xFF043E50),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      // Search Bar
                      TextField(
                        controller: _searchController,
                        onTap: () {
                          _searchController.clear();
                        },
                        onChanged: searchUsers,
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                        decoration: InputDecoration(
                          hintText: widget.showInviteButton ? 'Search friends' : 'Search users',
                          hintStyle: GoogleFonts.poppins(
                            color: Colors.grey.shade400,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                          prefixIcon: Icon(Icons.search, color: Colors.grey.shade400),
                          filled: true,
                          fillColor: Colors.black26,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Results List
                      Expanded(
                        child: isLoading
                            ? const Center(child: CircularProgressIndicator())
                            : searchResults.isEmpty
                                ? Center(
                                    child: Text(
                                      "No users found",
                                      style: GoogleFonts.poppins(
                                        color: Colors.grey.shade400,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  )
                                : ListView.builder(
                                    itemCount: searchResults.length,
                                    itemBuilder: (context, index) {
                                      final user = searchResults[index];
                                      final isFriend = isFriendMap[user.id] ?? false;
                                      
                                      return Container(
                                        margin: const EdgeInsets.only(bottom: 10),
                                        decoration: BoxDecoration(
                                          color: Colors.black26,
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: widget.showInviteButton
                                            ? ListTile(
                                                title: Text(
                                                  user.name,
                                                  style: GoogleFonts.poppins(
                                                    color: Colors.white,
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                                subtitle: Text(
                                                  user.email,
                                                  style: GoogleFonts.poppins(
                                                    color: Colors.grey.shade400,
                                                    fontSize: 14,
                                                  ),
                                                ),
                                                trailing: isFriend
                                                    ? const Icon(
                                                        Icons.check_circle,
                                                        color: Colors.green,
                                                      )
                                                    : IconButton(
                                                        icon: const Icon(
                                                          Icons.person_add,
                                                          color: Colors.white,
                                                        ),
                                                        onPressed: () => _sendInvitation(user),
                                                      ),
                                              )
                                            : CheckboxListTile(
                                                value: selectedUsers.contains(user),
                                                onChanged: (selected) {
                                                  toggleUserSelection(user);
                                                },
                                                activeColor: const Color(0xFF043E50),
                                                checkColor: Colors.white,
                                                title: Text(
                                                  user.name,
                                                  style: GoogleFonts.poppins(
                                                    color: Colors.white,
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                                subtitle: Text(
                                                  user.email,
                                                  style: GoogleFonts.poppins(
                                                    color: Colors.grey.shade400,
                                                    fontSize: 14,
                                                  ),
                                                ),
                                              ),
                                      );
                                    },
                                  ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 