import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:splitgasy/services/notification_service.dart';
import 'package:splitgasy/pages/group_chat_page.dart';

class ActivityPage extends StatefulWidget {
  const ActivityPage({super.key});

  @override
  State<ActivityPage> createState() => _ActivityPageState();
}

class _ActivityPageState extends State<ActivityPage> {
  String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return 'Just now';
    
    final now = DateTime.now();
    final date = timestamp.toDate();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  Future<void> _handleFriendRequest(
    BuildContext context,
    String invitationId,
    String fromUserId,
    String fromUserName,
    String fromUserEmail,
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

      // Check if invitation exists before updating
      final invitationDoc = await invitationRef.get();
      if (invitationDoc.exists) {
        batch.update(invitationRef, {
          'status': accept ? 'accepted' : 'rejected',
          'respondedAt': FieldValue.serverTimestamp(),
        });
      }

      // Update activity status
      final activityRef = FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .collection('activity')
          .doc(invitationId);

      // Check if activity exists before updating
      final activityDoc = await activityRef.get();
      if (activityDoc.exists) {
        batch.update(activityRef, {
          'status': accept ? 'accepted' : 'rejected',
          'respondedAt': FieldValue.serverTimestamp(),
        });
      }

      if (accept) {
        // Add to current user's friends collection
        final currentUserFriendsRef = FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .collection('friends')
            .doc(fromUserId);

        batch.set(currentUserFriendsRef, {
          'id': fromUserId,
          'name': fromUserName,
          'email': fromUserEmail,
          'addedAt': FieldValue.serverTimestamp(),
        });

        // Add to sender's friends collection
        final senderFriendsRef = FirebaseFirestore.instance
            .collection('users')
            .doc(fromUserId)
            .collection('friends')
            .doc(currentUser.uid);

        final currentUserDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .get();
        
        // Create user document if it doesn't exist
        if (!currentUserDoc.exists) {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(currentUser.uid)
              .set({
                'name': currentUser.displayName ?? 'User',
                'email': currentUser.email ?? '',
                'createdAt': FieldValue.serverTimestamp(),
              });
        }

        final currentUserData = currentUserDoc.data() ?? {
          'name': currentUser.displayName ?? 'User',
        };

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

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              accept ? 'Friend request accepted!' : 'Friend request rejected',
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Widget _buildFriendRequestCard(
    BuildContext context,
    String fromUserName,
    String status,
    String? invitationId,
    String? fromUserId,
    String? fromUserEmail,
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
                      fromUserEmail ?? '',
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
                      fromUserEmail ?? '',
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

  Widget _buildSettleBalanceCard(
    String fromUserName,
    double amount,
    bool isPaid,
    String status,
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
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: const Color(0xFF043E50),
            child: Icon(
              isPaid ? Icons.check_circle : Icons.attach_money,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  status == 'settled'
                      ? 'You and $fromUserName are now settled up!'
                      : isPaid
                          ? '$fromUserName paid you \$${amount.toStringAsFixed(2)}'
                          : 'You paid $fromUserName \$${amount.toStringAsFixed(2)}',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (status == 'settled')
                  Text(
                    'All balances have been cleared',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.green,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpenseUpdateCard(
    String fromUserName,
    String groupName,
    double amount,
    String expenseName,
    bool isCreator,
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
      child: Row(
        children: [
          const CircleAvatar(
            backgroundColor: Color(0xFF043E50),
            child: Icon(Icons.receipt_long, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isCreator
                      ? 'You added a new expense'
                      : '$fromUserName added a new expense',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  '"$expenseName" - \$${amount.toStringAsFixed(2)}',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                Text(
                  'Group: $groupName',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatMessageCard(Map<String, dynamic> activity) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 16),
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
      child: InkWell(
        onTap: () async {
          // Mark notification as read
          await NotificationService.markNotificationAsRead(activity['id']);
          
          // Navigate to group chat and scroll to the specific message
          if (context.mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => GroupChatPage(
                  groupId: activity['groupId'],
                  groupName: activity['groupName'],
                  members: [], // You'll need to pass the members list here
                ),
              ),
            ).then((_) {
              // After returning from the chat, refresh the activity list
              setState(() {});
            });
          }
        },
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: const Color(0xFF043E50),
              child: const Icon(
                Icons.chat_bubble_outline,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${activity['fromUserName']} sent a message in ${activity['groupName']}',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    activity['message'],
                    style: GoogleFonts.poppins(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatTimestamp(activity['timestamp']),
                    style: GoogleFonts.poppins(
                      color: Colors.grey[500],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            if (!activity['isRead'])
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Color(0xFF043E50),
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentRequestCard(Map<String, dynamic> activity) {
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
      child: InkWell(
        onTap: () async {
          // Mark notification as read
          await NotificationService.markNotificationAsRead(activity['id']);
          
          if (context.mounted) {
            // Close the activity page and return to home page
            Navigator.pop(context);
            
            // The home page will show the settle up dialog automatically
          }
        },
        child: Row(
          children: [
            const CircleAvatar(
              backgroundColor: Color(0xFF043E50),
              child: Icon(Icons.request_page, color: Colors.white),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${activity['fromUserName']} requested payment',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '\$${(activity['amount'] as num).toStringAsFixed(2)}',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF043E50),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatTimestamp(activity['timestamp']),
                    style: GoogleFonts.poppins(
                      color: Colors.grey[500],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            if (!activity['isRead'])
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Color(0xFF043E50),
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
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
      backgroundColor: const Color(0xFF043E50),
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
                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        'Error loading activities',
                        style: GoogleFonts.poppins(
                          color: Colors.grey[600],
                          fontSize: 16,
                        ),
                      ),
                    );
                  }

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
                      activity['id'] = activities[index].id;

                      switch (activity['type']) {
                        case 'friend_request':
                          return _buildFriendRequestCard(
                            context,
                            activity['fromUserName'] ?? 'Unknown User',
                            activity['status'] ?? 'pending',
                            activity['id'],
                            activity['fromUserId'] as String?,
                            activity['fromUserEmail'] as String?,
                          );
                        case 'friend_request_accepted':
                          return _buildFriendRequestAcceptedCard(
                            activity['fromUserName'] ?? 'Unknown User',
                          );
                        case 'settle_balance':
                          return _buildSettleBalanceCard(
                            activity['fromUserName'] ?? 'Unknown User',
                            (activity['amount'] as num).toDouble(),
                            activity['isPaid'] as bool? ?? false,
                            activity['status'] as String? ?? 'pending',
                          );
                        case 'expense_update':
                          return _buildExpenseUpdateCard(
                            activity['fromUserName'] ?? 'Unknown User',
                            activity['groupName'] as String? ?? 'Unknown Group',
                            (activity['amount'] as num).toDouble(),
                            activity['expenseName'] as String? ?? 'Expense',
                            activity['isCreator'] as bool? ?? false,
                          );
                        case 'chat_message':
                          return _buildChatMessageCard(activity);
                        case 'payment_request':
                          return _buildPaymentRequestCard(activity);
                        default:
                          return const SizedBox.shrink();
                      }
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
} 