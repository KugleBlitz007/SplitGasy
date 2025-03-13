import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:splitgasy/pages/groupe_page.dart';
import 'login_or_signup_page.dart';
import 'package:splitgasy/data/sample_data.dart';

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
                            color: const Color.fromARGB(255, 255, 194, 194),
                            fontSize: 25,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 10),
                        Text(
                          "\$85.26", // You are owed amount
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
          
                // Action Buttons (Send, Fund Wallet, Request, Pay Bills)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildActionButton("New Bill", Icons.receipt),
                    _buildActionButton("Settle Up", Icons.monetization_on),
                    _buildActionButton("New Group", Icons.add),
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
                  Expanded(
                    child: ListView.builder(
                      itemCount: expenseGroups.length,
                      itemBuilder: (context, index) {
                        final expenseGroup = expenseGroups[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 15),
                          elevation: 0,
                          color: const Color.fromARGB(255, 255, 255, 255),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                            title: Text(
                              expenseGroup.name,  // Display name
                              style: GoogleFonts.poppins(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(
                              expenseGroup.members.map((member) => member.name).join(', '),  // Join member names with commas
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                            // trailing: Text(
                            //   "\$${expenseGroup.amount}",  // Replace with the amount or total of the group
                            //   style: GoogleFonts.poppins(
                            //     fontSize: 16,
                            //     color: Colors.greenAccent,
                            //     fontWeight: FontWeight.bold,
                            //   ),
                            // ),
                            onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => GroupPage(groupName: expenseGroup.name),
                                    ),
                                  );
                                },
                          ),
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

  Widget _buildActionButton(String title, IconData icon) {
    return Column(
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
    );
  }
}