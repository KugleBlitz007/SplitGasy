import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:splitgasy/Models/app_user.dart';
import 'package:google_fonts/google_fonts.dart';

class SearchPage extends StatefulWidget {
  final List<AppUser> existingFriends;

  const SearchPage({super.key, required this.existingFriends});

  @override
  _SearchPageState createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _searchController = TextEditingController();
  List<AppUser> searchResults = [];
  List<AppUser> selectedUsers = [];

  // 🔹 Search Users from Firestore
  Future<void> searchUsers(String query) async {
    if (query.isEmpty) {
      setState(() {
        searchResults = [];
      });
      return;
    }

    // Convert search query to lowercase
    String lowerQuery = query.toLowerCase();

    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('users')
        .get();

    List<AppUser> filteredUsers = snapshot.docs
      .where((doc) => doc['name'].toString().toLowerCase().contains(lowerQuery))
      .map((doc) => AppUser(
            id: doc.id,
            name: doc['name'],
            email: doc['email'],
          ))
      .toList();

    setState(() {
      searchResults = filteredUsers;
    });
  }

  // 🔹 Toggle User Selection
  void toggleUserSelection(AppUser user) {
    setState(() {
      if (selectedUsers.contains(user)) {
        selectedUsers.remove(user);
      } else {
        selectedUsers.add(user);
      }
    });
  }

  // 🔹 Confirm Selection & Return to AddGroupPage
  void confirmSelection() {
    Navigator.pop(context, selectedUsers); // Return selected users to previous screen
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF043E50),
      body: SafeArea(
        child: Column(
          children: [
            // Custom AppBar
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Color(0xFF043E50),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    "Search Friends",
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  if (selectedUsers.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.check, color: Colors.white),
                      onPressed: confirmSelection,
                    ),
                ],
              ),
            ),

            // Search and Results
            Expanded(
              child: Container(
                color: const Color(0xFF043E50),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      // Search Bar
                      TextField(
                        controller: _searchController,
                        onTap: () {
                          _searchController.clear();
                        },
                        onChanged: (value) => searchUsers(value),
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Enter friend name',
                          hintStyle: GoogleFonts.poppins(
                            color: Colors.grey.shade400,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                          prefixIcon: Icon(Icons.search, color: Colors.grey.shade400),
                          filled: true,
                          fillColor: Colors.black26,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Search Results
                      Expanded(
                        child: searchResults.isEmpty
                            ? Center(
                                child: Text(
                                  "No users found",
                                  style: GoogleFonts.poppins(
                                    color: Colors.grey.shade400,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              )
                            : ListView.builder(
                                itemCount: searchResults.length,
                                itemBuilder: (context, index) {
                                  final user = searchResults[index];
                                  return CheckboxListTile(
                                    title: Text(
                                      user.name,
                                      style: GoogleFonts.poppins(
                                        color: Colors.white,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    subtitle: Text(
                                      user.email,
                                      style: GoogleFonts.poppins(
                                        color: Colors.grey.shade400,
                                        fontSize: 12,
                                      ),
                                    ),
                                    value: selectedUsers.contains(user),
                                    onChanged: (selected) {
                                      toggleUserSelection(user);
                                    },
                                    activeColor: const Color(0xFF043E50),
                                    checkColor: Colors.white,
                                    tileColor: Colors.black26,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    side: const BorderSide(color: Colors.white, width: 2),
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
