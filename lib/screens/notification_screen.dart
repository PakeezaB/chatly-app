// ignore_for_file: avoid_print, use_build_context_synchronously, prefer_const_constructors, library_private_types_in_public_api

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  _NotificationScreenState createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final String _userId = FirebaseAuth.instance.currentUser!.uid;
  List<DocumentSnapshot> _requests = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    if (FirebaseAuth.instance.currentUser == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushReplacementNamed('/login');
      });
      return;
    }
    _fetchFriendRequests();
  }

  Future<void> _fetchFriendRequests() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('friendRequests')
          .where('to', isEqualTo: _userId)
          .where('status', isEqualTo: 'pending')
          .get();

      print('Fetched friend requests: ${snapshot.docs.length}'); // Debug output

      setState(() {
        _requests = snapshot.docs;
        _isLoading = false;
      });
    } catch (e, stackTrace) {
      setState(() {
        _isLoading = false;
      });
      // Print the detailed error and stack trace
      print('Error fetching friend requests: $e');
      print('Stack trace: $stackTrace');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching friend requests: $e')),
      );
    }
  }

  Future<void> _respondToFriendRequest(
      DocumentSnapshot request, String response) async {
    try {
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final requestRef = FirebaseFirestore.instance
            .collection('friendRequests')
            .doc(request.id);

        final requestSnapshot = await transaction.get(requestRef);
        if (!requestSnapshot.exists) {
          throw Exception('Friend request does not exist.');
        }

        // Update the friend request status
        transaction.update(requestRef, {'status': response});

        final fromUserId = request['from'];
        final toUserId = request['to'];

        if (response == 'accepted') {
          // Add each other to the friends list
          await FirebaseFirestore.instance
              .collection('users')
              .doc(fromUserId)
              .collection('friends')
              .doc(toUserId)
              .set({});
          await FirebaseFirestore.instance
              .collection('users')
              .doc(toUserId)
              .collection('friends')
              .doc(fromUserId)
              .set({});

          // Notify both users
          await FirebaseFirestore.instance.collection('notifications').add({
            'type': 'accepted',
            'from': fromUserId,
            'to': toUserId,
            'timestamp': FieldValue.serverTimestamp(),
          });
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Friend request $response!')),
      );
      _fetchFriendRequests(); // Refresh the list after updating
    } catch (e, stackTrace) {
      // Print the detailed error and stack trace
      print('Error responding to friend request: $e');
      print('Stack trace: $stackTrace');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error responding to friend request: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _requests.isEmpty
              ? const Center(child: Text('No friend requests'))
              : ListView.builder(
                  itemCount: _requests.length,
                  itemBuilder: (context, index) {
                    final request = _requests[index];
                    final fromUserId = request['from'];

                    return FutureBuilder<DocumentSnapshot>(
                      future: FirebaseFirestore.instance
                          .collection('users')
                          .doc(fromUserId)
                          .get(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                              child: CircularProgressIndicator());
                        }
                        if (snapshot.hasError) {
                          // Print detailed error and stack trace
                          final error = snapshot.error;
                          final stackTrace = snapshot.stackTrace;
                          print('Error fetching user data: $error');
                          print('Stack trace: $stackTrace');
                          return Center(child: Text('Error: $error'));
                        }
                        if (!snapshot.hasData) {
                          return const SizedBox.shrink();
                        }

                        final fromUserData =
                            snapshot.data!.data() as Map<String, dynamic>;
                        final fromUserName =
                            fromUserData['username'] ?? 'Unknown User';
                        final fromProfilePictureUrl =
                            fromUserData['profilePictureUrl'] ?? '';

                        return ListTile(
                          leading: CircleAvatar(
                            backgroundImage: fromProfilePictureUrl.isNotEmpty
                                ? NetworkImage(fromProfilePictureUrl)
                                : null,
                            child: fromProfilePictureUrl.isEmpty
                                ? const Icon(Icons.person)
                                : null,
                          ),
                          title: Text(fromUserName),
                          subtitle: Text('Friend request'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.check),
                                onPressed: () => _respondToFriendRequest(
                                    request, 'accepted'),
                              ),
                              IconButton(
                                icon: const Icon(Icons.close),
                                onPressed: () => _respondToFriendRequest(
                                    request, 'rejected'),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
    );
  }
}
