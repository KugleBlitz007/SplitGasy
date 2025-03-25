import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:splitgasy/components/group_list_item.dart';
import 'package:splitgasy/pages/add_group.dart';
import 'package:splitgasy/pages/login_or_signup_page.dart';
import 'package:splitgasy/pages/activity_page.dart';
import 'package:splitgasy/pages/send_invites.dart';
import 'package:splitgasy/services/balance_service.dart';
import 'package:splitgasy/services/notification_service.dart';


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
            padding: const EdgeInsets.only(left: 20, right: 20, top: 70, bottom: 30),
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
                    
                    IconButton(
                      icon: const Icon(Icons.menu, color: Colors.white),
                      //onPressed: () => signOut(context),
                      onPressed:() { 
                      _scaffoldKey.currentState?.openEndDrawer();
                      },
                    ),
                    
                  ],
                ),
          
                const SizedBox(height: 15),
          
                // Available Balance
                Row(
                  children: [
                    // Left column (Texts: "You Owe" & "You Are Owed")
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.end, // Align to bottom
                        children: [
                          Text(
                            "You Owe",
                            style: GoogleFonts.poppins(
                              color: Colors.white54,
                              fontSize: 17,
                            ),
                          ),
                          SizedBox(height: 22), // Space between the two texts
                          Text(
                            "You Are Owed",
                            style: GoogleFonts.poppins(
                              color: Colors.white54,
                              fontSize: 17,
                            ),
                          ),
                        ],
                      ),
                    ),
          
                    // Right column (Balances)
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

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          mainAxisAlignment: MainAxisAlignment.end, // Align to bottom
                          children: [
                            Text(
                              "\$${youOwe.toStringAsFixed(2)}", // You owe amount
                              style: GoogleFonts.poppins(
                                color: const Color(0xFFFFC2C2),
                                fontSize: 25,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 10),
                            Text(
                              "\$${youAreOwed.toStringAsFixed(2)}", // You are owed amount
                              style: GoogleFonts.poppins(
                                color: const Color(0xFFC1FFE1),
                                fontSize: 25,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
          
          
                const SizedBox(height: 30),
          
                // Action Buttons (Send, Fund Wallet, Request, Pay Bills)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildActionButton(
                      "Add Friends",
                      Icons.person_add,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const SendInvitesPage()),
                        );
                      },
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
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Color(0xFFE0E0E0),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Your Groups",
                    style: GoogleFonts.poppins(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF333533),
                    ),
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
                        final docs = snapshot.data!.docs;
                        if (docs.isEmpty) {
                          return const Center(child: Text('No groups found.'));
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