import 'package:cloud_firestore/cloud_firestore.dart';
import 'app_user.dart';

class Balance {
  final AppUser user;
  double amount;

  Balance({
    required this.user,
    required this.amount,
  });

  /// Creates a Balance from a Firestore DocumentSnapshot.
  factory Balance.fromSnapshot(DocumentSnapshot snapshot) {
    final data = snapshot.data() as Map<String, dynamic>;
    return Balance(
      user: AppUser(
        id: data['user']['id'] as String,
        profile: data['user']['profile'] as String,
        name: data['user']['name'] as String,
        email: data['user']['email'] as String,
      ),
      amount: (data['amount'] as num).toDouble(),
    );
  }

  /// Converts the Balance instance to a Map for Firestore.
  Map<String, dynamic> toMap() {
    return {
      'user': {
        'id': user.id,
        'profile': user.profile,
        'name': user.name,
        'email': user.email,
      },
      'amount': amount,
    };
  }

  void updateBalance(double newAmount) {
    amount = newAmount;
    // Update Firestore document if needed.
  }
}
