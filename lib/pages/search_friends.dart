import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({Key? key}) : super(key: key);

  @override
  _SearchPageState createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> searchResults = [];

  // Function to Search Users in Firestore
  Future<void> searchUsers(String query) async {
    if (query.isEmpty) {
      setState(() {
        searchResults = [];
      });
      return;
    }

    // Search Firestore for names that contain the query (case-insensitive)
    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('name', isGreaterThanOrEqualTo: query)
        .where('name', isLessThanOrEqualTo: query + '\uf8ff') // Matches closest names
        .get();

    setState(() {
      searchResults = snapshot.docs.map((doc) {
        return {
          "name": doc['name'],
          "email": doc['email'],
          "joined": doc['joined'],
        };
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Search Users"),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Search Bar
            TextField(
              controller: _searchController,
              onChanged: (value) => searchUsers(value), // Call search function
              decoration: InputDecoration(
                labelText: "Search for people...",
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Display Search Results
            Expanded(
              child: searchResults.isEmpty
                  ? const Center(child: Text("No users found"))
                  : ListView.builder(
                      itemCount: searchResults.length,
                      itemBuilder: (context, index) {
                        var user = searchResults[index];
                        return ListTile(
                          title: Text(user['name']),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Email: ${user['email']}"),
                              Text("Joined: ${user['joined']}"), // Display join date
                            ],
                          ),
                          leading: CircleAvatar(child: Text(user['name'][0])), // First letter as profile pic
                        );
                      },
                    ),
            )
          ],
        ),
      ),
    );
  }
}
