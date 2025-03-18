import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'home_page.dart';
import 'package:splitgasy/components/bill_list_item.dart';
import 'new_bill_page.dart';
import 'edit_group.dart';
import 'package:splitgasy/Models/app_user.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
                  color: Color(0xFF333533),
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
                                color: Colors.white70,
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
                          .collection('groups')
                          .doc(groupId)
                          .collection('bills')
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return const CircularProgressIndicator();
                        }

                        final bills = snapshot.data!.docs;
                        final currentUser = FirebaseAuth.instance.currentUser;
                        if (currentUser == null) {
                          return const Text('Not signed in');
                        }

                        // Calculate balances per person
                        Map<String, double> balancesByPerson = {};
                        for (var member in members) {
                          balancesByPerson[member['id']] = 0.0;
                        }

                        for (var bill in bills) {
                          final billData = bill.data() as Map<String, dynamic>;
                          final amount = (billData['amount'] as num).toDouble();
                          final paidById = billData['paidById'] as String;
                          final participants = List<Map<String, dynamic>>.from(billData['participants']);
                          final splitMethod = billData['splitMethod'] as String? ?? 'equal';
                          
                          // Calculate shares for this bill
                          Map<String, double> shares = {};
                          for (var participant in participants) {
                            final userId = participant['id'] as String;
                            double share;
                            switch (splitMethod.toLowerCase()) {
                              case 'custom':
                                share = (participant['share'] as num?)?.toDouble() ?? 0.0;
                                break;
                              case 'proportional':
                                // TODO: Implement proportional split
                                share = amount / participants.length;
                                break;
                              default: // 'equal'
                                share = amount / participants.length;
                            }
                            shares[userId] = share;
                          }

                          // Update balances
                          for (var userId in shares.keys) {
                            if (userId == paidById) {
                              // This person paid, they are owed everyone else's shares
                              balancesByPerson[userId] = (balancesByPerson[userId] ?? 0.0) + 
                                  (amount - (shares[userId] ?? 0.0));
                            } else {
                              // This person owes their share to the payer
                              balancesByPerson[userId] = (balancesByPerson[userId] ?? 0.0) - 
                                  (shares[userId] ?? 0.0);
                            }
                          }
                        }

                        // Calculate overall balance for current user
                        final overallBalance = balancesByPerson[currentUser.uid] ?? 0.0;

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
                                  ? const Color.fromARGB(255, 193, 255, 225)
                                  : const Color.fromARGB(255, 255, 194, 194),
                                fontSize: 20,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Individual balances
                            ...members.where((m) => m['id'] != currentUser.uid).map((member) {
                              final balance = balancesByPerson[member['id']] ?? 0.0;
                              // Invert the balance since we're showing it from current user's perspective
                              final displayBalance = -balance;
                              
                              if (displayBalance == 0) return const SizedBox.shrink();

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
                                        text: displayBalance > 0
                                          ? "${member['name']} owes you "
                                          : "You owe ${member['name']} ",
                                      ),
                                      TextSpan(
                                        text: "\$${displayBalance.abs().toStringAsFixed(2)}",
                                        style: TextStyle(
                                          color: displayBalance > 0
                                            ? const Color.fromARGB(255, 193, 255, 225)
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
                          // TODO: Add "Request" functionality for group page
                        }),
                        _buildActionButton("Settle Up", Icons.monetization_on, onTap: () {
                          // TODO: Add "Settle Up" functionality for group page
                        }),
                        _buildActionButton("Add", Icons.group_add, onTap: () async {
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
                        _buildActionButton("Remove", Icons.group_remove, onTap: () {
                          // TODO: Add "Remove" functionality for group page
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
                          color: Color(0xFF333533),
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
                              return const Center(child: Text('No bills yet'));
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