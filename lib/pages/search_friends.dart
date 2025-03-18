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
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // 🔹 Search Bar
            TextField(
              controller: _searchController,
              onChanged: (value) => searchUsers(value),
              decoration: InputDecoration(
                labelText: "Search for people...",
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // 🔹 Display Search Results with Selection
            Expanded(
              child: searchResults.isEmpty
                  ? const Center(child: Text("No users found"))
                  : ListView.builder(
                      itemCount: searchResults.length,
                      itemBuilder: (context, index) {
                        final user = searchResults[index];
                        return CheckboxListTile(
                          title: Text(user.name),
                          subtitle: Text(user.email),
                          value: selectedUsers.contains(user),
                          onChanged: (selected) {
                            toggleUserSelection(user);
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
