import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:splitgasy/Models/app_user.dart';

class SearchPage extends StatefulWidget {
  final List<AppUser> existingFriends;

  const SearchPage({Key? key, required this.existingFriends}) : super(key: key);

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
      appBar: AppBar(
        iconTheme: const IconThemeData(
          color: Colors.white70, //change your color here
        ),
        title: const Text("Search Users",
        style: TextStyle(
                            color: Colors.white70,
                          ),
        ),
        backgroundColor: const Color(0xFF043E50),
        actions: [
          if (selectedUsers.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.check,
              color: Colors.white70,
              ), // Confirm Selection Button
              onPressed: confirmSelection,
            ),
        ],
      ),
      backgroundColor: const Color(0xFF043E50),
      body: Container(
        color: const Color(0xFF043E50),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // 🔹 Search Bar
              TextField(
                controller: _searchController,
                onChanged: (value) => searchUsers(value),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
                decoration: InputDecoration(
                  labelText: "Search for people...",
                  labelStyle: TextStyle(
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

              // 🔹 Display Search Results with Selection
              Expanded(
                child: searchResults.isEmpty
                    ? Center(
                        child: Text(
                          "No users found",
                          style: TextStyle(
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
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            subtitle: Text(
                              user.email,
                              style: TextStyle(
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
    );
  }
}
