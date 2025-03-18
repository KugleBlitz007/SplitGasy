import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:splitgasy/components/group_list_item.dart';
import 'package:splitgasy/pages/group_page.dart';
import 'login_or_signup_page.dart';
import 'package:splitgasy/pages/add_group.dart';
import 'search_friends.dart';


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

  @override
  Widget build(BuildContext context) {
    
    return Scaffold(
    key: _scaffoldKey,

    endDrawer: Drawer(
                      child: ListView(
                        children: [
                          ListTile(
                            title: Text(
                              "Placeholder",
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                color: Color(0xFF043E50),
                              ),
                            ),
                            onTap: (){},
                          ),
                          ListTile(
                            title: Text(
                              "Search Friends",
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                color: Color(0xFF043E50),
                              ),
                            ),
                            leading: const Icon(Icons.search, color: Color(0xFF043E50)),
                            onTap: (){
                               Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => const Placeholder()),
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