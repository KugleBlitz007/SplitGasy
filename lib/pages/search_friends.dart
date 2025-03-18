import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SearchPage extends StatefulWidget {
  final List<Map<String, dynamic>> existingFriends;

  const SearchPage({Key? key, required this.existingFriends}) : super(key: key);

  @override
  _SearchPageState createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> searchResults = [];
  List<Map<String, dynamic>> selectedUsers = [];

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

    List<Map<String, dynamic>> filteredUsers = snapshot.docs
      .where((doc) => doc['name'].toString().toLowerCase().contains(lowerQuery)) // Case-insensitive filtering
      .map((doc) => {
            "id": doc.id,
            "name": doc['name'],
            "email": doc['email'],
          })
      .toList();

  setState(() {
    searchResults = filteredUsers;
  });
}


  // 🔹 Toggle User Selection
  void toggleUserSelection(Map<String, dynamic> user) {
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
        iconTheme: IconThemeData(
          color: Colors.white70, //change your color here
        ),
        title: const Text("Search Users",
        style: TextStyle(
                            color: Colors.white70,
                          ),
        ),
        backgroundColor: Color(0xFF043E50),
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
                        var user = searchResults[index];
                        return CheckboxListTile(
                          title: Text(user['name']),
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
