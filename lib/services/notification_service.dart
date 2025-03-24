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

  // Create a payment request notification
  static Future<void> createPaymentRequestNotification({
    required String groupId,
    required String toUserId,
    required String toUserName,
    required double amount,
    required String requesterId,
    required String requesterName,
  }) async {
    try {
      // Create notification for the user who owes money
      await _firestore
          .collection('users')
          .doc(toUserId)
          .collection('activity')
          .add({
        'type': 'payment_request',
        'groupId': groupId,
        'fromUserId': requesterId,
        'fromUserName': requesterName,
        'amount': amount,
        'status': 'pending',
        'timestamp': FieldValue.serverTimestamp(),
        'isRead': false,
      });
    } catch (e) {
      print('Error creating payment request notification: $e');
      rethrow;
    }
  }

  // Create settlement notifications for both users
  static Future<void> createSettlementNotifications({
    required String groupId,
    required String payerId,
    required String payerName,
    required String receiverId,
    required String receiverName,
    required double amount,
  }) async {
    try {
      final batch = _firestore.batch();

      // Notification for the payer
      final payerNotificationRef = _firestore
          .collection('users')
          .doc(payerId)
          .collection('activity')
          .doc();

      batch.set(payerNotificationRef, {
        'type': 'settle_balance',
        'fromUserName': receiverName,
        'amount': amount,
        'isPaid': false, // payer paid
        'status': 'settled',
        'timestamp': FieldValue.serverTimestamp(),
      });

      // Notification for the receiver
      final receiverNotificationRef = _firestore
          .collection('users')
          .doc(receiverId)
          .collection('activity')
          .doc();

      batch.set(receiverNotificationRef, {
        'type': 'settle_balance',
        'fromUserName': payerName,
        'amount': amount,
        'isPaid': true, // receiver received payment
        'status': 'settled',
        'timestamp': FieldValue.serverTimestamp(),
      });

      await batch.commit();
    } catch (e) {
      print('Error creating settlement notifications: $e');
      rethrow;
    }
  }
} 