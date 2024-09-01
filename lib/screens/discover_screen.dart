// ignore_for_file: use_build_context_synchronously, avoid_print

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _DiscoverScreenState createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<DocumentSnapshot> _users = [];
  List<DocumentSnapshot> _filteredUsers = [];
  DocumentSnapshot? _selectedUser;
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchUsers();
    _searchController.addListener(_filterUsers);
  }

  Future<void> _fetchUsers() async {
    try {
      final userCollection = FirebaseFirestore.instance.collection('users');
      final snapshot = await userCollection.get();
      setState(() {
        _users = snapshot.docs;
        _filteredUsers = snapshot.docs;
        _isLoading = false;
        _errorMessage = '';
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error fetching users: $e';
      });
      print('Error fetching users: $e');
    }
  }

  void _filterUsers() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredUsers = _users.where((user) {
        final userData = user.data() as Map<String, dynamic>;
        final userName = userData['username'] ?? 'Unknown User';
        return userName.toLowerCase().contains(query);
      }).toList();
    });
  }

  void _selectUser(DocumentSnapshot user) {
    setState(() {
      _selectedUser = user;
    });
  }

  Future<void> _sendFriendRequest() async {
    if (_selectedUser == null) return;

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No user is currently signed in.')),
      );
      return;
    }

    try {
      final userData = _selectedUser!.data() as Map<String, dynamic>;
      final toEmail = userData['email'] as String?;

      if (toEmail == null) {
        throw Exception('Email is missing in the selected user data.');
      }

      // Fetch user ID by email
      final usersCollection = FirebaseFirestore.instance.collection('users');
      final userSnapshot = await usersCollection
          .where('email', isEqualTo: toEmail)
          .limit(1)
          .get();

      if (userSnapshot.docs.isEmpty) {
        throw Exception('No user found with the email: $toEmail');
      }

      final toUserId = userSnapshot.docs.first.id; // User ID of the recipient

      await FirebaseFirestore.instance.collection('friendRequests').doc().set({
        'from': currentUser.uid,
        'to': toUserId,
        'status': 'pending',
        'timestamp': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Friend request sent!')),
      );
    } catch (e, stackTrace) {
      print('Error sending friend request: $e');
      print('Stack trace: $stackTrace');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error sending friend request: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Discover Users'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                labelText: 'Search Users',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else if (_errorMessage.isNotEmpty)
            Center(child: Text(_errorMessage))
          else
            Expanded(
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: ListView.builder(
                      itemCount: _filteredUsers.length,
                      itemBuilder: (context, index) {
                        final user = _filteredUsers[index];
                        final userData = user.data() as Map<String, dynamic>;
                        final userName = userData['username'] ?? 'Unknown User';
                        final profilePictureUrl =
                            userData['profilePictureUrl'] ?? '';

                        return ListTile(
                          leading: CircleAvatar(
                            backgroundImage: profilePictureUrl.isNotEmpty
                                ? NetworkImage(profilePictureUrl)
                                : null,
                            child: profilePictureUrl.isEmpty
                                ? const Icon(Icons.person)
                                : null,
                          ),
                          title: Text(userName),
                          onTap: () {
                            _selectUser(user);
                          },
                        );
                      },
                    ),
                  ),
                  if (_selectedUser != null)
                    Expanded(
                      flex: 3,
                      child: Card(
                        margin: const EdgeInsets.all(20),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CircleAvatar(
                                radius: 50,
                                backgroundImage: (_selectedUser?.data() as Map<
                                            String,
                                            dynamic>)['profilePictureUrl']
                                        .isNotEmpty
                                    ? NetworkImage((_selectedUser?.data()
                                            as Map<String, dynamic>)[
                                        'profilePictureUrl'])
                                    : null,
                                child: (_selectedUser?.data() as Map<String,
                                            dynamic>)['profilePictureUrl']
                                        .isEmpty
                                    ? const Icon(Icons.person, size: 50)
                                    : null,
                              ),
                              const SizedBox(height: 20),
                              Text(
                                'Username: ${(_selectedUser?.data() as Map<String, dynamic>)['username']}',
                                style: const TextStyle(fontSize: 18),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                'Email: ${(_selectedUser?.data() as Map<String, dynamic>)['email']}',
                                style: const TextStyle(fontSize: 18),
                              ),
                              const SizedBox(height: 20),
                              ElevatedButton(
                                onPressed: _sendFriendRequest,
                                child: const Text('Send Friend Request'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
