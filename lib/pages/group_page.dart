import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'home_page.dart';
import 'package:splitgasy/components/bill_list_item.dart';
import 'new_bill_page.dart';
import 'edit_group.dart';
import 'group_chat_page.dart';
import 'package:splitgasy/Models/app_user.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:splitgasy/services/balance_service.dart';
import 'package:splitgasy/services/notification_service.dart';

class GroupPage extends StatelessWidget {
  final String groupName;
  final String groupId;

  const GroupPage({
    super.key,
    required this.groupName,
    required this.groupId,
  });

  Widget _buildActionButton(String title, IconData icon, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 80, // Fixed width for each button
        child: Column(
          mainAxisSize: MainAxisSize.min, // Minimize the column's height
          children: [
            CircleAvatar(
              radius: 25,
              backgroundColor: Colors.white.withOpacity(0.15),
              child: Icon(icon, color: Colors.white, size: 24),
            ),
            const SizedBox(height: 5),
            Text(
              title,
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 12,
              ),
              textAlign: TextAlign.center, // Center the text
            ),
          ],
        ),
      ),
    );
  }

  /// Shows a dialog for settling up balances within a specific group.
  /// This method handles the settlement of debts between the current user and other group members.

  void _showSettleUpDialog(BuildContext context, String groupId, List<Map<String, dynamic>> members) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    // Get all balances for the current group where the user owes money or is owed money
    final balancesSnapshot = await FirebaseFirestore.instance
        .collection('balances')
        .where('groupId', isEqualTo: groupId)
        .where('fromUserId', isEqualTo: currentUser.uid)
        .get();

    final owedToUserSnapshot = await FirebaseFirestore.instance
        .collection('balances')
        .where('groupId', isEqualTo: groupId)
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
                  'No balances to settle in this group',
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
                  final userName = members
                      .firstWhere((m) => m['id'] == userId, orElse: () => {'name': 'Unknown User'})['name'];
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

                              // Create settlement notifications
                              await NotificationService.createSettlementNotifications(
                                groupId: groupId,
                                payerId: currentUser.uid,
                                payerName: currentUser.displayName ?? 'User',
                                receiverId: userId,
                                receiverName: userName,
                                amount: balance.abs(),
                              );
                            } else {
                              // Current user is owed money
                              await BalanceService.settleUp(
                                groupId,
                                userId,
                                currentUser.uid,
                              );

                              // Create settlement notifications
                              await NotificationService.createSettlementNotifications(
                                groupId: groupId,
                                payerId: userId,
                                payerName: userName,
                                receiverId: currentUser.uid,
                                receiverName: currentUser.displayName ?? 'User',
                                amount: balance.abs(),
                              );
                            }

                            // Remove the settled balance from netBalances
                            netBalances.remove(userId);

                            // Show success Snackbar using the root context
                            if (context.mounted) {
                              // Get the root scaffold messenger
                              final scaffoldMessenger = ScaffoldMessenger.of(context);
                              
                              // If there are no more balances to settle, close the dialog
                              if (netBalances.isEmpty) {
                                Navigator.pop(context);
                              } else {
                                // Otherwise, rebuild the dialog with updated balances
                                Navigator.pop(context);
                                _showSettleUpDialog(context, groupId, members);
                              }

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

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('groups')
          .doc(groupId)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final groupData = snapshot.data!.data() as Map<String, dynamic>;
        final members = (groupData['members'] as List<dynamic>?)
            ?.map((m) => m as Map<String, dynamic>)
            .toList() ?? [];

        return Scaffold(
          body: Column(
            children: [
              // Top part
              Container(
                padding: const EdgeInsets.only(left: 20, right: 20, top: 70, bottom: 30),
                decoration: const BoxDecoration(
                  color: Color(0xFF043E50),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Greeting and Notification Icon row
                    Row(
                      children: [
                        // Back IconButton
                        IconButton(
                          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                          onPressed: () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(builder: (context) => const HomePage()),
                            );
                          },
                        ),
                        const SizedBox(width: 10),
                        // Group info
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Your Group",
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.7),
                                fontSize: 13,
                              ),
                            ),
                            Text(
                              groupName,
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        )
                      ],
                    ),

                    const SizedBox(height: 15),

                    // Overall Balance
                    StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('balances')
                          .where('groupId', isEqualTo: groupId)
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return const CircularProgressIndicator();
                        }

                        final currentUser = FirebaseAuth.instance.currentUser;
                        if (currentUser == null) {
                          return const Text('Not signed in');
                        }

                        // Calculate net balances
                        final balances = <String, double>{};
                        for (var doc in snapshot.data!.docs) {
                          final data = doc.data() as Map<String, dynamic>;
                          final fromUserId = data['fromUserId'] as String;
                          final toUserId = data['toUserId'] as String;
                          final amount = (data['amount'] as num).toDouble();

                          if (fromUserId == currentUser.uid) {
                            // User owes money
                            balances[toUserId] = (balances[toUserId] ?? 0.0) - amount;
                          } else if (toUserId == currentUser.uid) {
                            // User is owed money
                            balances[fromUserId] = (balances[fromUserId] ?? 0.0) + amount;
                          }
                        }

                        // Remove any zero balances
                        balances.removeWhere((_, amount) => amount == 0);

                        final overallBalance = balances.values.fold(0.0, (sum, amount) => sum + amount);

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Overall balance
                            Text(
                              overallBalance == 0
                                ? "Everyone is settled up! 🎉"
                                : overallBalance > 0 
                                  ? "You are owed \$${overallBalance.abs().toStringAsFixed(2)} overall"
                                  : "You owe \$${overallBalance.abs().toStringAsFixed(2)} overall",
                              style: GoogleFonts.poppins(
                                color: overallBalance == 0
                                  ? const Color(0xFF6DEAC5)
                                  : overallBalance > 0 
                                    ? const Color(0xFF6DEAC5)
                                    : const Color(0xFFFFC2C2),
                                fontSize: 20,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Net balances with each person
                            if (balances.isEmpty)
                              Text(
                                "The group is all caught up!",
                                style: GoogleFonts.poppins(
                                  color: Colors.white70,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w400,
                                ),
                              )
                            else
                              ...balances.entries.map((entry) {
                                final balance = entry.value;
                                final otherPerson = members.firstWhere(
                                  (m) => m['id'] == entry.key,
                                  orElse: () => {'name': 'Unknown'},
                                );

                                if (balance == 0) return const SizedBox.shrink();

                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: RichText(
                                    text: TextSpan(
                                      style: GoogleFonts.poppins(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w400,
                                      ),
                                      children: [
                                        TextSpan(
                                          text: balance > 0
                                            ? "${otherPerson['name']} owes you "
                                            : "You owe ${otherPerson['name']} ",
                                        ),
                                        TextSpan(
                                          text: "\$${balance.abs().toStringAsFixed(2)}",
                                          style: TextStyle(
                                            color: balance > 0
                                              ? const Color(0xFF6DEAC5)
                                              : const Color(0xFFFFC2C2),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }),
                          ],
                        );
                      },
                    ),

                    const SizedBox(height: 30),

                    // Action Buttons row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildActionButton("Chat", Icons.chat, onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => GroupChatPage(
                                groupId: groupId,
                                groupName: groupName,
                                members: members,
                              ),
                            ),
                          );
                        }),

                        _buildActionButton("Edit Friends", Icons.group_add, onTap: () async {
                          // Fetch current group members
                          final groupDoc = await FirebaseFirestore.instance
                              .collection('groups')
                              .doc(groupId)
                              .get();
                          
                          if (groupDoc.exists) {
                            final membersData = groupDoc.data()?['members'] as List<dynamic>;
                            final currentMembers = membersData.map((member) => AppUser(
                              id: member['id'],
                              name: member['name'],
                              email: member['email'],
                            )).toList();

                            // Navigate to EditGroupPage
                            if (context.mounted) {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => EditGroupPage(
                                    groupId: groupId,
                                    groupName: groupName,
                                    currentMembers: currentMembers,
                                  ),
                                ),
                              );
                            }
                          }
                        }),
                        
                        _buildActionButton("Settle Up", Icons.monetization_on, onTap: () {
                          _showSettleUpDialog(context, groupId, members);
                        }),
                        
                      ],
                    ),
                  ],
                ),
              ),

              // Bottom part (Bills list)
              Expanded(
                child: Container(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Bills",
                        style: GoogleFonts.poppins(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF043E50),
                        ),
                      ),

                      // List of bills
                      Expanded(
                        child: StreamBuilder<QuerySnapshot>(
                          stream: FirebaseFirestore.instance
                              .collection('groups')
                              .doc(groupId)
                              .collection('bills')
                              .orderBy('date', descending: true)
                              .snapshots(),
                          builder: (context, snapshot) {
                            if (!snapshot.hasData) {
                              return const Center(child: CircularProgressIndicator());
                            }

                            final bills = snapshot.data!.docs;
                            if (bills.isEmpty) {
                              return Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.receipt_long_outlined,
                                      size: 64,
                                      color: Colors.grey[400],
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      "No bills yet",
                                      style: GoogleFonts.poppins(
                                        fontSize: 18,
                                        color: Colors.grey[600],
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      "Tap the + button to add your first bill",
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
                              padding: EdgeInsets.only(top: 20),
                              itemCount: bills.length,
                              itemBuilder: (context, index) {
                                final bill = bills[index].data() as Map<String, dynamic>;
                                final payer = members.firstWhere(
                                  (m) => m['id'] == bill['paidById'],
                                  orElse: () => {'name': 'Unknown'},
                                );

                                return BillListItem(
                                  title: bill['name'] as String? ?? 'Unnamed Bill',
                                  amount: (bill['amount'] as num?)?.toDouble() ?? 0.0,
                                  paidBy: payer['name'] as String? ?? 'Unknown',
                                  paidById: bill['paidById'] as String,
                                  date: (bill['date'] as Timestamp).toDate(),
                                  participants: List<Map<String, dynamic>>.from(bill['participants'] ?? []),
                                  splitMethod: bill['splitMethod'] as String? ?? 'equal',
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
          floatingActionButton: FloatingActionButton(
            backgroundColor: const Color(0xFF043E50),
            shape: const CircleBorder(),
            child: const Icon(Icons.add, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => NewBillPage(
                    groupId: groupId,
                    groupMembers: members,
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}