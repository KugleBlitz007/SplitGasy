import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:splizzy/components/group_list_item.dart';
import 'package:splizzy/pages/add_group.dart';
import 'package:splizzy/pages/login_or_signup_page.dart';
import 'package:splizzy/pages/activity_page.dart';
import 'package:splizzy/pages/add_friends.dart';
import 'package:splizzy/services/balance_service.dart';
import 'package:splizzy/services/notification_service.dart';


class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final user = FirebaseAuth.instance.currentUser!;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // sign out function
  void signOut(BuildContext context) async {
    await FirebaseAuth.instance.signOut();

    // Navigate to LoginOrSignupPage after signing out
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => LoginOrSignupPage()),
    );
  }

  // delete account function
  Future<void> deleteAccount(BuildContext context) async {
    try {
      // Show confirmation dialog
      bool? confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Delete Account'),
          content: const Text('Are you sure you want to delete your account?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel', style: TextStyle(color: Color(0xFF043E50))),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      );

      if (confirm == true) {
        // Delete user data from Firestore
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .delete();

        // Delete the user account
        await user.delete();

        // Navigate to login page
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => LoginOrSignupPage()),
        );
      }
    } catch (e) {
      // Show error dialog
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Error'),
          content: Text('Failed to delete account: ${e.toString()}'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  void _showSettleUpDialog(BuildContext context) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    // Get all balances where the user owes money or is owed money
    final balancesSnapshot = await FirebaseFirestore.instance
        .collection('balances')
        .where('fromUserId', isEqualTo: currentUser.uid)
        .get();

    final owedToUserSnapshot = await FirebaseFirestore.instance
        .collection('balances')
        .where('toUserId', isEqualTo: currentUser.uid)
        .get();

    // Combine and process balances
    final Map<String, Map<String, dynamic>> netBalances = {};

    // Process balances where user owes money
    for (var doc in balancesSnapshot.docs) {
      final data = doc.data();
      final toUserId = data['toUserId'] as String;
      final amount = (data['amount'] as num).toDouble();
      
      netBalances[toUserId] = {
        'amount': -(amount),
        'groupId': data['groupId'],
      };
    }

    // Process balances where user is owed money
    for (var doc in owedToUserSnapshot.docs) {
      final data = doc.data();
      final fromUserId = data['fromUserId'] as String;
      final amount = (data['amount'] as num).toDouble();
      
      if (netBalances.containsKey(fromUserId)) {
        netBalances[fromUserId]!['amount'] = 
            (netBalances[fromUserId]!['amount'] as double) + amount;
      } else {
        netBalances[fromUserId] = {
          'amount': amount,
          'groupId': data['groupId'],
        };
      }
    }

    if (netBalances.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.info_outline, color: Colors.white),
                const SizedBox(width: 8),
                Text(
                  'No balances to settle',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF043E50),
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
      return;
    }

    // Get user details for all involved users
    final userDetails = <String, String>{};
    for (var userId in netBalances.keys) {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();
      userDetails[userId] = userDoc.data()?['name'] ?? 'Unknown User';
    }

    if (context.mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: Colors.white.withOpacity(0.95),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: Row(
            children: [
              const Icon(
                Icons.account_balance_wallet,
                color: Color(0xFF043E50),
                size: 28,
              ),
              const SizedBox(width: 10),
              Text(
                'Settle Up',
                style: GoogleFonts.poppins(
                  color: const Color(0xFF043E50),
                  fontWeight: FontWeight.w600,
                  fontSize: 20,
                ),
              ),
            ],
          ),
          content: Container(
            constraints: const BoxConstraints(maxHeight: 400),
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: netBalances.entries.map((entry) {
                  final userId = entry.key;
                  final balance = entry.value['amount'] as double;
                  final userName = userDetails[userId] ?? 'Unknown User';
                  final groupId = entry.value['groupId'] as String;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: Colors.grey[300]!,
                        width: 1,
                      ),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      title: Text(
                        userName,
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w500,
                          fontSize: 16,
                        ),
                      ),
                      subtitle: Text(
                        balance > 0
                            ? 'Owes you \$${balance.abs().toStringAsFixed(2)}'
                            : 'You owe \$${balance.abs().toStringAsFixed(2)}',
                        style: GoogleFonts.poppins(
                          color: balance > 0 ? Colors.green : Colors.red,
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                        ),
                      ),
                      trailing: ElevatedButton(
                        onPressed: () async {
                          try {
                            if (balance < 0) {
                              // Current user owes money
                              await BalanceService.settleUp(
                                groupId,
                                currentUser.uid,
                                userId,
                              );
                            } else {
                              // Current user is owed money
                              await BalanceService.settleUp(
                                groupId,
                                userId,
                                currentUser.uid,
                              );
                            }

                            // Show success Snackbar using the root context
                            if (context.mounted) {
                              // Get the root scaffold messenger
                              final scaffoldMessenger = ScaffoldMessenger.of(context);
                              
                              // Close the dialog first
                              Navigator.pop(context);

                              // Show the snackbar after a short delay to ensure it appears after dialog dismissal
                              Future.delayed(const Duration(milliseconds: 100), () {
                                scaffoldMessenger.showSnackBar(
                                  SnackBar(
                                    content: Row(
                                      children: [
                                        const Icon(Icons.check_circle, color: Colors.white),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            'Successfully settled up with $userName',
                                            style: GoogleFonts.poppins(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    backgroundColor: const Color(0xFF046007),
                                    duration: const Duration(seconds: 3),
                                    behavior: SnackBarBehavior.floating,
                                    margin: const EdgeInsets.all(16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                );
                              });
                            }
                          } catch (e) {
                            if (context.mounted) {
                              // Get the root scaffold messenger
                              final scaffoldMessenger = ScaffoldMessenger.of(context);
                              
                              // Close the dialog first
                              Navigator.pop(context);

                              // Show the error snackbar after a short delay
                              Future.delayed(const Duration(milliseconds: 100), () {
                                scaffoldMessenger.showSnackBar(
                                  SnackBar(
                                    content: Row(
                                      children: [
                                        const Icon(Icons.error_outline, color: Colors.white),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            'Error settling up: $e',
                                            style: GoogleFonts.poppins(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    backgroundColor: const Color(0xFFB00020),
                                    duration: const Duration(seconds: 3),
                                    behavior: SnackBarBehavior.floating,
                                    margin: const EdgeInsets.all(16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                );
                              });
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF043E50),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                        ),
                        child: Text(
                          'Settle',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF043E50),
              ),
              child: Text(
                'Close',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      );
    }
  }

  void _showRequestDialog(BuildContext context) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    // Get all balances where the user is owed money
    final owedToUserSnapshot = await FirebaseFirestore.instance
        .collection('balances')
        .where('toUserId', isEqualTo: currentUser.uid)
        .get();

    if (owedToUserSnapshot.docs.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.info_outline, color: Colors.white),
                const SizedBox(width: 8),
                Text(
                  'No pending balances to request',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF043E50),
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
      return;
    }

    // Get user details for all users who owe money
    final Map<String, Map<String, dynamic>> debtors = {};
    for (var doc in owedToUserSnapshot.docs) {
      final data = doc.data();
      final fromUserId = data['fromUserId'] as String;
      final amount = (data['amount'] as num).toDouble();
      final groupId = data['groupId'] as String;

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(fromUserId)
          .get();
      
      debtors[fromUserId] = {
        'name': userDoc.data()?['name'] ?? 'Unknown User',
        'amount': amount,
        'groupId': groupId,
      };
    }

    if (context.mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: Colors.white.withOpacity(0.95),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: Row(
            children: [
              const Icon(
                Icons.request_page,
                color: Color(0xFF043E50),
                size: 28,
              ),
              const SizedBox(width: 10),
              Text(
                'Request Payment',
                style: GoogleFonts.poppins(
                  color: const Color(0xFF043E50),
                  fontWeight: FontWeight.w600,
                  fontSize: 20,
                ),
              ),
            ],
          ),
          content: Container(
            constraints: const BoxConstraints(maxHeight: 400),
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: debtors.entries.map((entry) {
                  final userId = entry.key;
                  final userData = entry.value;
                  final userName = userData['name'] as String;
                  final amount = userData['amount'] as double;
                  final groupId = userData['groupId'] as String;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: Colors.grey[300]!,
                        width: 1,
                      ),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      title: Text(
                        userName,
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w500,
                          fontSize: 16,
                        ),
                      ),
                      subtitle: Text(
                        'Owes you \$${amount.toStringAsFixed(2)}',
                        style: GoogleFonts.poppins(
                          color: const Color(0xFF046007),
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                        ),
                      ),
                      trailing: ElevatedButton(
                        onPressed: () async {
                          try {
                            await NotificationService.createPaymentRequestNotification(
                              groupId: groupId,
                              toUserId: userId,
                              toUserName: userName,
                              amount: amount,
                              requesterId: currentUser.uid,
                              requesterName: currentUser.displayName ?? 'You',
                            );

                            // Show success Snackbar using the root context
                            if (context.mounted) {
                              // Get the root scaffold messenger
                              final scaffoldMessenger = ScaffoldMessenger.of(context);
                              
                              // Close the dialog first
                              Navigator.pop(context);

                              // Show the snackbar after a short delay to ensure it appears after dialog dismissal
                              Future.delayed(const Duration(milliseconds: 100), () {
                                scaffoldMessenger.showSnackBar(
                                  SnackBar(
                                    content: Row(
                                      children: [
                                        const Icon(Icons.check_circle, color: Colors.white),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            'Payment requested from $userName',
                                            style: GoogleFonts.poppins(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    backgroundColor: const Color(0xFF046007),
                                    duration: const Duration(seconds: 3),
                                    behavior: SnackBarBehavior.floating,
                                    margin: const EdgeInsets.all(16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                );
                              });
                            }
                          } catch (e) {
                            if (context.mounted) {
                              // Get the root scaffold messenger
                              final scaffoldMessenger = ScaffoldMessenger.of(context);
                              
                              // Close the dialog first
                              Navigator.pop(context);

                              // Show the error snackbar after a short delay
                              Future.delayed(const Duration(milliseconds: 100), () {
                                scaffoldMessenger.showSnackBar(
                                  SnackBar(
                                    content: Row(
                                      children: [
                                        const Icon(Icons.error_outline, color: Colors.white),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            'Error requesting payment: $e',
                                            style: GoogleFonts.poppins(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    backgroundColor: const Color(0xFFB00020),
                                    duration: const Duration(seconds: 3),
                                    behavior: SnackBarBehavior.floating,
                                    margin: const EdgeInsets.all(16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                );
                              });
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF043E50),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                        ),
                        child: Text(
                          'Request',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF043E50),
              ),
              child: Text(
                'Close',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      );
    }
  }

  void _addFriend() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AddFriendsPage(showInviteButton: true),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    
    return Scaffold(
    key: _scaffoldKey,

    endDrawer: Drawer(
                      child: ListView(
                        children: [
                          ListTile(
                            title: Text(
                              "Activity",
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                color: Color(0xFF043E50),
                              ),
                            ),
                            leading: const Icon(Icons.notifications, color: Color(0xFF043E50)),
                            onTap: () {
                              Navigator.pop(context);
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const ActivityPage()),
                              );
                            },
                          ),
                          ListTile(
                            title: Text(
                              "Delete Account",
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                color: Color(0xFF043E50),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            leading: const Icon(Icons.delete_forever, color: Color(0xFF043E50)),
                            onTap: () {
                              Navigator.pop(context);
                              deleteAccount(context);
                            },
                          ),
                          ListTile(
                            title: Text(
                              "Logout",
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                color: Color(0xFF043E50),
                              ),
                            ),
                            leading: const Icon(Icons.logout, color: Color(0xFF043E50)),
                            onTap: () {
                              Navigator.pop(context); 
                              signOut(context); 
                            },
                          ),
                        ],
                      ),
                    ),

      body: Column(
        children: [
          // Top part
          Container(
            padding: const EdgeInsets.only(left: 20, right: 20, top: 70, bottom: 20),
            decoration: const BoxDecoration(
              color: Color(0xFF043E50), // Dark green color
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Greeting and Notification Icon
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Welcome to Splizzy",
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                          ),
                        ),
                        Text(
                          user.displayName ?? 'User',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        // const SizedBox(height: 3),
                      ],
                    ),
                    
                    StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('notifications')
                          .where('userId', isEqualTo: user.uid)
                          .where('isRead', isEqualTo: false)
                          .snapshots(),
                      builder: (context, snapshot) {
                        final hasUnread = snapshot.hasData && snapshot.data!.docs.isNotEmpty;
                        return Badge(
                          isLabelVisible: hasUnread,
                          backgroundColor: Colors.red,
                          child: IconButton(
                            icon: const Icon(Icons.menu, color: Colors.white),
                            onPressed: () {
                              _scaffoldKey.currentState?.openEndDrawer();
                            },
                          ),
                        );
                      },
                    ),
                  ],
                ),
          
                const SizedBox(height: 15),
          
                // Combined Balance Display with Dropdown
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('balances')
                      .snapshots(),
                  builder: (context, snapshot) {
                    double youOwe = 0.0;
                    double youAreOwed = 0.0;

                    if (snapshot.hasData) {
                      for (var doc in snapshot.data!.docs) {
                        final data = doc.data() as Map<String, dynamic>;
                        final status = data['status'] as String?;
                        
                        // Skip settled balances
                        if (status == 'settled') continue;
                        
                        final amount = (data['amount'] as num).toDouble();
                        final fromUserId = data['fromUserId'] as String;
                        final toUserId = data['toUserId'] as String;

                        if (fromUserId == user.uid) {
                          // Current user owes money
                          youOwe += amount;
                        } else if (toUserId == user.uid) {
                          // Current user is owed money
                          youAreOwed += amount;
                        }
                      }
                    }

                    // Calculate overall balance
                    double overallBalance = youAreOwed - youOwe;
                    String balanceText = overallBalance >= 0 
                      ? "+\$${overallBalance.toStringAsFixed(2)}" 
                      : "-\$${overallBalance.abs().toStringAsFixed(2)}";
                    Color balanceColor = overallBalance >= 0 
                      ? const Color(0xFFC1FFE1) 
                      : const Color(0xFFFFC2C2);
                    String balanceLabel = overallBalance >= 0 
                      ? "Overall, you are owed" 
                      : "Overall, you owe";

                    return _ExpandableBalanceWidget(
                      youOwe: youOwe,
                      youAreOwed: youAreOwed,
                      overallBalance: overallBalance,
                      balanceLabel: balanceLabel,
                      balanceText: balanceText,
                      balanceColor: balanceColor,
                    );
                  },
                ),
          
                const SizedBox(height: 20),
          
                // Action Buttons (Send, Fund Wallet, Request, Pay Bills)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildActionButton(
                      "Add Friends",
                      Icons.person_add,
                      onTap: () => _addFriend(),
                    ),
                    _buildActionButton(
                      "Settle Up",
                      Icons.monetization_on,
                      onTap: () => _showSettleUpDialog(context),
                    ),
                    _buildActionButton("New Group", Icons.add, onTap: () {
                     Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const AddGroupPage()),
                      );
                    }),
                    _buildActionButton(
                      "Request",
                      Icons.request_page,
                      onTap: () => _showRequestDialog(context),
                    ),
                  ],
                ),
              ],
            ),
          ),
      
          // Bottom part
          Expanded(
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Your Groups",
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF043E50),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF043E50).withOpacity(0.06),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.group,
                              size: 16,
                              color: const Color(0xFF043E50),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              "Groups",
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: const Color(0xFF043E50),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Use a StreamBuilder to load groups from Firestore
                  Expanded(
                    child: StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('groups')
                          .where('members', arrayContains: {
                            'id': user.uid,
                            'name': user.displayName ?? 'User',
                            'email': user.email ?? '',
                          })
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        
                        // Get and sort docs by last modified date
                        final docs = snapshot.data!.docs.toList();
                        docs.sort((a, b) {
                          final aData = a.data() as Map<String, dynamic>;
                          final bData = b.data() as Map<String, dynamic>;
                          
                          // Get last modified timestamp - use updatedAt if available, otherwise createdAt
                          // If both are null, use epoch timestamp (Jan 1, 1970)
                          final aUpdated = aData['updatedAt'] as Timestamp?;
                          final aCreated = aData['createdAt'] as Timestamp?;
                          final bUpdated = bData['updatedAt'] as Timestamp?;
                          final bCreated = bData['createdAt'] as Timestamp?;
                          
                          // Use the most recent of either timestamp
                          final aTimestamp = aUpdated ?? aCreated;
                          final bTimestamp = bUpdated ?? bCreated;
                          
                          if (aTimestamp == null && bTimestamp == null) return 0;
                          if (aTimestamp == null) return 1; // null timestamps at the end
                          if (bTimestamp == null) return -1;
                          
                          // Sort in descending order (newest first)
                          return bTimestamp.compareTo(aTimestamp);
                        });
                        
                        if (docs.isEmpty) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.group_outlined,
                                  size: 64,
                                  color: Colors.grey[400],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  "No groups yet",
                                  style: GoogleFonts.poppins(
                                    fontSize: 18,
                                    color: Colors.grey[600],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  "Create a group to start splitting bills",
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    color: Colors.grey[500],
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          );
                        }

                        return ListView.builder(
                          padding: EdgeInsets.zero,
                          itemCount: docs.length,
                          itemBuilder: (context, index) {
                            final doc = docs[index];
                            final data = doc.data() as Map<String, dynamic>;

                            final groupName = data['name'] as String? ?? 'Unnamed Group';
                            final members = data['members'] as List<dynamic>? ?? [];
                            final membersString = members
                                .map((m) => (m as Map<String, dynamic>)['name'] as String)
                                .join(', ');

                            return GroupListItem(
                              groupId: doc.id,
                              groupName: groupName,
                              membersString: membersString,
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),

        ],
      ),
    );
  }

/// Builds an action button widget that displays an icon and a title.
  Widget _buildActionButton(String title, IconData icon, {VoidCallback? onTap}) {
    // Wrap the button in a GestureDetector to handle taps.
    return GestureDetector(
      onTap: onTap,
      child: Column(
      children: [
        CircleAvatar(
          radius: 25,
          backgroundColor: Colors.white12,
          child: Icon(icon, color: Colors.white, size: 24),
        ),
        const SizedBox(height: 5),
        Text(
          title,
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 12,
          ),
        ),
      ],
      )
    );
  }
}

class _ExpandableBalanceWidget extends StatefulWidget {
  final double youOwe;
  final double youAreOwed;
  final double overallBalance;
  final String balanceLabel;
  final String balanceText;
  final Color balanceColor;

  const _ExpandableBalanceWidget({
    required this.youOwe,
    required this.youAreOwed,
    required this.overallBalance,
    required this.balanceLabel,
    required this.balanceText,
    required this.balanceColor,
  });

  @override
  State<_ExpandableBalanceWidget> createState() => _ExpandableBalanceWidgetState();
}

class _ExpandableBalanceWidgetState extends State<_ExpandableBalanceWidget> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        setState(() {
          _expanded = !_expanded;
        });
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.balanceLabel,
                      style: GoogleFonts.poppins(
                        color: Colors.white70,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.balanceText,
                      style: GoogleFonts.poppins(
                        color: widget.balanceColor,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                AnimatedRotation(
                  duration: const Duration(milliseconds: 200),
                  turns: _expanded ? 0.5 : 0,
                  child: Icon(
                    Icons.keyboard_arrow_down,
                    color: Colors.white70,
                    size: 28,
                  ),
                ),
              ],
            ),
            
            // Expandable details section
            AnimatedCrossFade(
              firstChild: const SizedBox.shrink(),
              secondChild: Column(
                children: [
                  const SizedBox(height: 16),
                  const Divider(height: 1, color: Colors.white24),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "You owe",
                        style: GoogleFonts.poppins(
                          color: Colors.white54,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        "\$${widget.youOwe.toStringAsFixed(2)}",
                        style: GoogleFonts.poppins(
                          color: const Color(0xFFFFC2C2),
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "You are owed",
                        style: GoogleFonts.poppins(
                          color: Colors.white54,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        "\$${widget.youAreOwed.toStringAsFixed(2)}",
                        style: GoogleFonts.poppins(
                          color: const Color(0xFFC1FFE1),
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              crossFadeState: _expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 120),
            ),
          ],
        ),
      ),
    );
  }
}