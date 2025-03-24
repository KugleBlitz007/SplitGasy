import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:splitgasy/Models/app_user.dart';
import 'search_friends.dart';

class SendInvitesPage extends StatefulWidget {
  const SendInvitesPage({super.key});

  @override
  State<SendInvitesPage> createState() => _SendInvitesPageState();
}

class _SendInvitesPageState extends State<SendInvitesPage> {
  final List<AppUser> selectedUsers = [];
  final currentUser = FirebaseAuth.instance.currentUser;

  Future<void> _sendInvitations() async {
    if (selectedUsers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one friend')),
      );
      return;
    }

    try {
      final batch = FirebaseFirestore.instance.batch();
      final currentUserDoc = FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser?.uid);

      // Get current user's data
      final currentUserData = await currentUserDoc.get();
      final currentUserInfo = currentUserData.data() as Map<String, dynamic>;

      for (var user in selectedUsers) {
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
          'fromUserName': currentUserInfo['name'],
          'fromUserEmail': currentUserInfo['email'],
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
          'fromUserName': currentUserInfo['name'],
          'fromUserEmail': currentUserInfo['email'],
          'timestamp': FieldValue.serverTimestamp(),
          'status': 'pending',
          'invitationId': invitationRef.id,
        });
      }

      await batch.commit();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invitations sent successfully!')),
      );

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error sending invitations: $e')),
      );
    }
  }

  void _addFriend() async {
    final List<AppUser>? selectedUsers = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SearchPage(existingFriends: []),
      ),
    );

    if (selectedUsers != null && selectedUsers.isNotEmpty) {
      setState(() {
        for (var user in selectedUsers) {
          if (!this.selectedUsers.any((friend) => friend.id == user.id)) {
            this.selectedUsers.add(user);
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
                  "Send Friend Invitations",
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 20),
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
                          "Selected Friends",
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
                        children: selectedUsers.map((friend) {
                          return CheckboxListTile(
                            value: true,
                            activeColor: const Color(0xFF043E50),
                            checkColor: Colors.white,
                            onChanged: (bool? value) {
                              if (value == false) {
                                setState(() {
                                  selectedUsers.removeWhere((f) => f.id == friend.id);
                                });
                              }
                            },
                            title: Text(
                              friend.name,
                              style: GoogleFonts.poppins(
                                fontSize: 18,
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
                            controlAffinity: ListTileControlAffinity.trailing,
                            contentPadding: EdgeInsets.zero,
                          );
                        }).toList(),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Send Button
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: ElevatedButton(
                        onPressed: _sendInvitations,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF043E50),
                          minimumSize: const Size(double.infinity, 50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          'Send Invitations',
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