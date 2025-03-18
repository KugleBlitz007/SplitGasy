import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'search_friends.dart';

class AddGroupPage extends StatefulWidget {
  const AddGroupPage({Key? key}) : super(key: key);

  @override
  State<AddGroupPage> createState() => _AddGroupPageState();
}

class _AddGroupPageState extends State<AddGroupPage> {
  final TextEditingController _groupNameController = TextEditingController();

  // Sample list of friends (replace with actual data from Firestore if needed).
  final List<Map<String, dynamic>> friends = [
    //{'id': '1', 'name': '...', 'selected': false},
  ];

  // 🔹 Navigate to SearchPage and Get Selected Users
  Future<void> openSearchPage() async {
    final List<Map<String, dynamic>>? selectedUsers = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => SearchPage(existingFriends: friends)),
    );

    if (selectedUsers != null && selectedUsers.isNotEmpty) {
      setState(() {
        for (var user in selectedUsers) {
          if (!friends.any((friend) => friend['id'] == user['id'])) {
            friends.add({'id': user['id'], 'name': user['name'], 'selected': false});
          }
        }
      });
    }
  }

  @override
  void dispose() {
    _groupNameController.dispose();
    super.dispose();
  }

  // Toggles selection of a friend from the list.
  void _toggleFriendSelection(int index) {
    setState(() {
      friends[index]['selected'] = !(friends[index]['selected'] as bool);
    });
  }

  // Saves the new group to Firestore.
  Future<void> _saveGroup() async {
    final groupName = _groupNameController.text.trim();

    if (groupName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Group name cannot be empty')),
      );
      return;
    }

    // Gather selected friend names into a single comma-separated string.
    final selectedFriends = friends
        .where((f) => f['selected'] == true)
        .map((f) => f['id'] as String)
        .toList();

    if (selectedFriends.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one friend')),
      );
      return;
    }

    final membersString = selectedFriends.join(', ');

    try {
      // Add a new document to the 'groups' collection in Firestore.
      await FirebaseFirestore.instance.collection('groups').add({
        'name': groupName,
        'members': membersString,
      });

      // Optionally show a success message.
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Group created successfully!')),
      );

      // Pop back to the HomePage.
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error creating group: $e')),
      );
    }
  }

  // Called when the "Add friends" icon is tapped (optional).
 void _addFriend() async {
  final List<Map<String, dynamic>>? selectedUsers = await Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => SearchPage(existingFriends: friends), // Pass existing friends
    ),
  );

  // 🔹 If users are selected, update the friends list
  if (selectedUsers != null && selectedUsers.isNotEmpty) {
    setState(() {
      for (var user in selectedUsers) {
        if (!friends.any((friend) => friend['id'] == user['id'])) {
          friends.add({'id': user['id'], 'name': user['name'], 'selected': false});
        }
      }
    });
  }
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE0E0E0),
      body: SafeArea(
        child: Column(
          children: [
            // TOP SECTION (Green header + back button + icon + texts).
            Container(
              padding: const EdgeInsets.only(left: 20, right: 20, top: 20, bottom: 30),
              decoration: const BoxDecoration(
                color: Color.fromARGB(255, 1, 87, 77),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Row with back arrow on the left and "Add friends" icon on the right.
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                      Column(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.group_add, color: Colors.white),
                            onPressed: _addFriend,
                          ),
                          Text(
                            "Add friends",
                            style: GoogleFonts.poppins(
                              color: Colors.white70,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // Larger title
                  Text(
                    "Create a group",
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Group Name TextField
                  TextField(
                    controller: _groupNameController,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: Colors.black,
                    ),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white,
                      labelText: 'Group Name',
                      labelStyle: GoogleFonts.poppins(
                        color: Colors.grey[600],
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Expanded section for the friend list + save button.
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Column(
                  children: [
                    // "Select Friends" label
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          "Select Friends",
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color.fromARGB(255, 1, 87, 77),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // White container for friend checkboxes
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 20),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: friends.asMap().entries.map((entry) {
                          final index = entry.key;
                          final friend = entry.value;
                          return CheckboxListTile(
                            value: friend['selected'],
                            activeColor: const Color.fromARGB(255, 1, 87, 77), // Green check color
                            onChanged: (bool? value) {
                              _toggleFriendSelection(index);
                            },
                            title: Text(
                              friend['name'],
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: Colors.black87,
                              ),
                            ),
                            controlAffinity: ListTileControlAffinity.trailing,
                          );
                        }).toList(),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // SAVE button
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _saveGroup,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color.fromARGB(255, 1, 87, 77),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(
                            "Save",
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
