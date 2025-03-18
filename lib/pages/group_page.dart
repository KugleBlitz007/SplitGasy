import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'home_page.dart';
import 'package:splitgasy/components/bill_list_item.dart';
import 'new_bill_page.dart';
class GroupPage extends StatelessWidget {
  final String groupName;

  const GroupPage({
    super.key,
    required this.groupName,
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
    return Scaffold(
      body: Column(
        children: [
          // Top part (no changes here)
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

                // Action Buttons row (copied from HomePage)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildActionButton("Chat", Icons.chat, onTap: () {
                      // TODO: Add "Request" functionality for group page
                    }),
                    _buildActionButton("Settle Up", Icons.monetization_on, onTap: () {
                      // TODO: Add "Settle Up" functionality for group page
                    }),
                    _buildActionButton("Add ", Icons.group_add, onTap: () {
                      // TODO: Add "New Group" functionality for group page
                    }),
                    _buildActionButton("Remove", Icons.group_remove, onTap: () {
                      // TODO: Add "New Bill" functionality for group page
                    }),
                  ],
                ),
              ],
            ),
          ),

          // Bottom part (list of expense categories and bottom buttons)
          Expanded(
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
              decoration: const BoxDecoration(
                color: Color(0xFFE0E0E0), // Light grey background
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

                  // List of expense categories using the new component
                  Expanded(
                    child: ListView(
                      padding: EdgeInsets.only(top: 20),
                      children: [
                        BillListItem(
                          title: "Groceries",
                          items: const [
                            "Milk \$2.50",
                            "Bread \$1.99",
                            "Eggs \$3.20",
                            "Cheese \$4.50",
                          ],
                          onViewDetails: () {
                            // TODO: Navigate to expense details
                            print("View expense details");
                          },

                        ),
                        BillListItem(
                          title: "Furniture",
                         
                        ),
                        BillListItem(
                          title: "Shared car",
                          
                        ),
                        BillListItem(
                          title: "Rent",
                          
                        ),
                        BillListItem(
                          title: "Wifi",
                          
                        ),
                      ],
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
            MaterialPageRoute(builder: (context) => const NewBillPage()),
          );
        },
      ),
    );
  }
}