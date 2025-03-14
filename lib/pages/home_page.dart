
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:splitgasy/pages/group_page.dart';
import 'login_or_signup_page.dart';
import 'package:splitgasy/data/sample_data.dart';
import 'package:splitgasy/pages/add_group.dart';


class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final user = FirebaseAuth.instance.currentUser!;

  // sign out function
  void signOut(BuildContext context) async {
    await FirebaseAuth.instance.signOut();

    // Navigate to LoginOrSignupPage after signing out
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => LoginOrSignupPage()),
    );
  }


  @override
  Widget build(BuildContext context) {
    
    final expenseGroups = getSampleGroups();
    
    return Scaffold(
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
                          "Welcome to SplitGasy",
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
                      icon: const Icon(Icons.logout, color: Colors.white),
                      onPressed: () => signOut(context),
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
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisAlignment: MainAxisAlignment.end, // Align to bottom
                      children: [
                        Text(
                          "\$120.03", // You owe amount
                          style: GoogleFonts.poppins(
                            color: const Color(0xFFFFC2C2),
                            fontSize: 25,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 10),
                        Text(
                          "\$85.26", // You are owed amount
                          style: GoogleFonts.poppins(
                            color: const Color(0xFFC1FFE1),
                            fontSize: 25,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
          
          
                const SizedBox(height: 30),
          
                // Action Buttons (Send, Fund Wallet, Request, Pay Bills)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildActionButton("New Bill", Icons.receipt),
                    _buildActionButton("Settle Up", Icons.monetization_on),
                    _buildActionButton("New Group", Icons.add, onTap: () {
                     Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const AddGroupPage()),
                      );
                    }),
                    _buildActionButton("Request", Icons.request_page),
                    
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
                  // const SizedBox(height: 10),
                  // Use of StreamBuilder to load groups from Firestore
                  // "Your Groups" heading

                  const SizedBox(height: 10),

                  // Use a StreamBuilder to load groups from Firestore
                  Expanded(
                    child: StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance.collection('groups').snapshots(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        final docs = snapshot.data!.docs;
                        if (docs.isEmpty) {
                          return const Center(child: Text('No groups found.'));
                        }

                        return ListView.builder(
                          itemCount: docs.length,
                          itemBuilder: (context, index) {
                            final doc = docs[index];
                            final data = doc.data() as Map<String, dynamic>;

                            final groupName = data['name'] as String? ?? 'Unnamed Group';
                            final membersString = data['members'] as String? ?? '';

                            return Card(
                              margin: const EdgeInsets.only(bottom: 15),
                              elevation: 0,
                              color: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: GestureDetector(
                                onLongPress: () {
                                  // Show a dialog with edit and delete options
                                  showDialog(
                                    context: context,
                                    builder: (context) {
                                      return AlertDialog(
                                        title: Text("Select Action", style: GoogleFonts.poppins()),
                                        content: Text("Would you like to rename or delete this group?", style: GoogleFonts.poppins()),
                                        actions: [
                                          //rename group action
                                          TextButton(
                                            onPressed: () { 
                                              // Close the first dialog.
                                              Navigator.pop(context);
                                              // Then show a second dialog to rename.
                                              showDialog(
                                                context: context,
                                                builder: (context) {
                                                  // Create a controller pre-filled with the current group name.
                                                  final TextEditingController _renameController = TextEditingController(text: groupName);
                                                  return AlertDialog(
                                                    title: Text("Rename Group", style: GoogleFonts.poppins()),
                                                    content: TextField(
                                                      controller: _renameController,
                                                      style: GoogleFonts.poppins(),
                                                      decoration: InputDecoration(
                                                        labelText: "New Group Name",
                                                        labelStyle: GoogleFonts.poppins(),
                                                      ),
                                                    ),
                                                    actions: [
                                                      TextButton(
                                                        onPressed: () async {
                                                          final newName = _renameController.text.trim();
                                                          if (newName.isNotEmpty) {
                                                            await FirebaseFirestore.instance
                                                                .collection('groups')
                                                                .doc(doc.id)
                                                                .update({'name': newName});
                                                          }
                                                          Navigator.pop(context); // Close rename dialog.
                                                        },
                                                        child: Text("Rename", style: GoogleFonts.poppins(color: const Color(0xFF043E50))),
                                                      ),
                                                      TextButton(
                                                        onPressed: () {
                                                          Navigator.pop(context); // Cancel rename.
                                                        },
                                                        child: Text("Cancel", style: GoogleFonts.poppins(color: const Color(0xFF043E50))),
                                                      ),
                                                    ],
                                                  );
                                                },
                                              );
                                            },
                                          //Rename   
                                          child: Text("Rename", style: GoogleFonts.poppins(color: Color(0xFF043E50))),
                                          ),

                                          //delete group action
                                          TextButton(
                                            onPressed: () async {
                                              // Delete the group from Firestore.
                                              await FirebaseFirestore.instance
                                                  .collection('groups')
                                                  .doc(doc.id)
                                                  .delete();
                                              Navigator.pop(context);
                                            },
                                            child: Text("Delete", style: GoogleFonts.poppins(color: Colors.red)),
                                          ),

                                          //cancel 
                                          TextButton(
                                            onPressed: () {
                                              Navigator.pop(context);
                                            },
                                            child: Text("Cancel", style: GoogleFonts.poppins(color: Color(0xFF043E50))),
                                          ),
                                        ],
                                      );
                                    },
                                  );
                                },
                                child: ListTile(
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                  title: Text(
                                    groupName,
                                    style: GoogleFonts.poppins(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  subtitle: Text(
                                    membersString, // e.g., "David, Nael, Mbola"
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  onTap: () {
                                    // Navigate to GroupPage with the groupName.
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => GroupPage(groupName: groupName),
                                      ),
                                    );
                                  },
                                ),
                              ),
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