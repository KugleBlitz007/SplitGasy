import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotificationService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Create a chat notification
  static Future<void> createChatNotification({
    required String groupId,
    required String groupName,
    required String senderId,
    required String senderName,
    required String message,
    required String messageId,
    required List<Map<String, dynamic>> recipients,
  }) async {
    final batch = _firestore.batch();

    // Create notifications for each recipient except the sender
    for (var recipient in recipients) {
      if (recipient['id'] != senderId) {
        final notificationRef = _firestore
            .collection('users')
            .doc(recipient['id'])
            .collection('activity')
            .doc();

        batch.set(notificationRef, {
          'type': 'chat_message',
          'groupId': groupId,
          'groupName': groupName,
          'fromUserId': senderId,
          'fromUserName': senderName,
          'message': message,
          'messageId': messageId,
          'timestamp': FieldValue.serverTimestamp(),
          'isRead': false,
        });
      }
    }

    await batch.commit();
  }

  // Mark a notification as read
  static Future<void> markNotificationAsRead(String notificationId) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    await _firestore
        .collection('users')
        .doc(userId)
        .collection('activity')
        .doc(notificationId)
        .update({'isRead': true});
  }

  // Get unread notifications count
  static Stream<int> getUnreadNotificationsCount() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return Stream.value(0);

    return _firestore
        .collection('users')
        .doc(userId)
        .collection('activity')
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }
} 