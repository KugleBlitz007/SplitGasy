import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'home_page.dart';
import 'package:splitgasy/components/bill_list_item.dart';
import 'new_bill_page.dart';
import 'edit_group.dart';
import 'package:splitgasy/Models/app_user.dart';

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

                    // Available Balance
                    Row(
                      children: [
                        // Left column (Texts: "You Owe" & "You Are Owed")
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "You Owe",
                                style: GoogleFonts.poppins(
                                  color: Colors.white54,
                                  fontSize: 17,
                                ),
                              ),
                              const SizedBox(height: 22),
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
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              "\$120.03", // Example amount you owe
                              style: GoogleFonts.poppins(
                                color: const Color.fromARGB(255, 255, 194, 194),
                                fontSize: 25,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              "\$85.26", // Example amount you are owed
                              style: GoogleFonts.poppins(
                                color: const Color.fromARGB(255, 193, 255, 225),
                                fontSize: 25,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
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
                                  date: (bill['date'] as Timestamp).toDate(),
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