import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:splitgasy/Models/app_user.dart';

class ActivityPage extends StatelessWidget {
  const ActivityPage({Key? key}) : super(key: key);

  Future<void> _handleFriendRequest(
    BuildContext context,
    String invitationId,
    String fromUserId,
    String fromUserName,
    bool accept,
  ) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    try {
      final batch = FirebaseFirestore.instance.batch();

      // Update invitation status
      final invitationRef = FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .collection('invitations')
          .doc(invitationId);

      batch.update(invitationRef, {
        'status': accept ? 'accepted' : 'rejected',
        'respondedAt': FieldValue.serverTimestamp(),
      });

      // Update activity status
      final activityRef = FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .collection('activity')
          .doc(invitationId);

      batch.update(activityRef, {
        'status': accept ? 'accepted' : 'rejected',
        'respondedAt': FieldValue.serverTimestamp(),
      });

      if (accept) {
        // Add to current user's friends
        final currentUserFriendsRef = FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .collection('friends')
            .doc(fromUserId);

        batch.set(currentUserFriendsRef, {
          'id': fromUserId,
          'name': fromUserName,
          'addedAt': FieldValue.serverTimestamp(),
        });

        // Add to sender's friends
        final senderFriendsRef = FirebaseFirestore.instance
            .collection('users')
            .doc(fromUserId)
            .collection('friends')
            .doc(currentUser.uid);

        final currentUserDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .get();
        final currentUserData = currentUserDoc.data() as Map<String, dynamic>;

        batch.set(senderFriendsRef, {
          'id': currentUser.uid,
          'name': currentUserData['name'],
          'addedAt': FieldValue.serverTimestamp(),
        });

        // Add notification to sender's activity
        final senderActivityRef = FirebaseFirestore.instance
            .collection('users')
            .doc(fromUserId)
            .collection('activity')
            .doc();

        batch.set(senderActivityRef, {
          'type': 'friend_request_accepted',
          'fromUserId': currentUser.uid,
          'fromUserName': currentUserData['name'],
          'timestamp': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            accept
                ? 'Friend request accepted!'
                : 'Friend request rejected',
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      return const Scaffold(
        body: Center(child: Text('Not signed in')),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFE0E0E0),
      body: SafeArea(
        child: Column(
          children: [
            // Header
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
                    "Activity",
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

            // Activity List
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .doc(currentUser.uid)
                    .collection('activity')
                    .orderBy('timestamp', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final activities = snapshot.data!.docs;
                  if (activities.isEmpty) {
                    return Center(
                      child: Text(
                        'No activity yet',
                        style: GoogleFonts.poppins(
                          color: Colors.grey[600],
                          fontSize: 16,
                        ),
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: activities.length,
                    itemBuilder: (context, index) {
                      final activity = activities[index].data() as Map<String, dynamic>;
                      final type = activity['type'] as String;
                      final status = activity['status'] as String?;
                      final timestamp = activity['timestamp'] as Timestamp?;
                      final fromUserName = activity['fromUserName'] as String?;
                      final invitationId = activity['invitationId'] as String?;

                      Widget activityWidget;
                      switch (type) {
                        case 'friend_request':
                          activityWidget = _buildFriendRequestCard(
                            context,
                            fromUserName ?? 'Unknown User',
                            status ?? 'pending',
                            invitationId,
                            activity['fromUserId'],
                          );
                          break;
                        case 'friend_request_accepted':
                          activityWidget = _buildFriendRequestAcceptedCard(
                            fromUserName ?? 'Unknown User',
                          );
                          break;
                        default:
                          activityWidget = const SizedBox.shrink();
                      }

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: activityWidget,
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFriendRequestCard(
    BuildContext context,
    String fromUserName,
    String status,
    String? invitationId,
    String? fromUserId,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const CircleAvatar(
                backgroundColor: Color(0xFF043E50),
                child: Icon(Icons.person_add, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '$fromUserName sent you a friend request',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          if (status == 'pending' && invitationId != null && fromUserId != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => _handleFriendRequest(
                      context,
                      invitationId,
                      fromUserId,
                      fromUserName,
                      false,
                    ),
                    child: Text(
                      'Reject',
                      style: GoogleFonts.poppins(
                        color: Colors.red,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () => _handleFriendRequest(
                      context,
                      invitationId,
                      fromUserId,
                      fromUserName,
                      true,
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF043E50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      'Accept',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          if (status != 'pending')
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                status == 'accepted' ? 'Request accepted' : 'Request rejected',
                style: GoogleFonts.poppins(
                  color: status == 'accepted' ? Colors.green : Colors.red,
                  fontSize: 14,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFriendRequestAcceptedCard(String fromUserName) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          const CircleAvatar(
            backgroundColor: Color(0xFF043E50),
            child: Icon(Icons.check_circle, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '$fromUserName accepted your friend request',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
} 