import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'home_page.dart';
import 'package:splitgasy/components/bill_list_item.dart';
import 'new_bill_page.dart';
import 'edit_group.dart';
import 'group_chat.dart';
import 'package:splitgasy/Models/app_user.dart';
import 'package:splitgasy/Models/bill_calculation.dart';
import 'package:splitgasy/services/bill_calculation_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:splitgasy/Models/balance.dart';
import 'package:splitgasy/services/balance_service.dart';

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

                        final overallBalance = balances.values.fold(0.0, (sum, amount) => sum + amount);

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Overall balance
                            Text(
                              overallBalance >= 0 
                                ? "You are owed \$${overallBalance.abs().toStringAsFixed(2)} overall"
                                : "You owe \$${overallBalance.abs().toStringAsFixed(2)} overall",
                              style: GoogleFonts.poppins(
                                color: overallBalance >= 0 
                                  ? const Color.fromARGB(255, 109, 234, 197)
                                  : const Color.fromARGB(255, 255, 194, 194),
                                fontSize: 20,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Net balances with each person
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
                                            ? const Color.fromARGB(255, 109, 234, 197)
                                            : const Color.fromARGB(255, 255, 194, 194),
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
                          // TODO: Add "Settle Up" functionality for group page
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