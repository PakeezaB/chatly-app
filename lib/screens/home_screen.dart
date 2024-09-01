// ignore_for_file: avoid_print, library_private_types_in_public_api, unnecessary_to_list_in_spreads

import 'package:chatly_app/screens/notification_screen.dart';
import 'package:chatly_app/screens/profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'library_screen.dart'; // Import your LibraryScreen
import 'discover_screen.dart'; // Import your DiscoverScreen

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String profilePictureUrl = '';
  final TextEditingController _postController = TextEditingController();
  final TextEditingController _imageUrlController = TextEditingController();
  String? _imageUrl;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final userProfile = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (userProfile.exists) {
          setState(() {
            profilePictureUrl = userProfile.data()?['profilePictureUrl'] ?? '';
          });
        } else {
          setState(() {
            profilePictureUrl = ''; // Default or empty value
          });
        }
      }
    } catch (e) {
      print('Error loading user profile: $e');
    }
  }

  Future<void> _createPost() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final post = {
          'postId': FirebaseFirestore.instance.collection('posts').doc().id,
          'userId': user.uid,
          'username': user.displayName ?? 'Unknown User',
          'profilePictureUrl': profilePictureUrl,
          'content': _postController.text,
          'imageUrl': _imageUrl ?? '',
          'timestamp': Timestamp.now(),
          'likes': [],
          'comments': [],
        };

        await FirebaseFirestore.instance.collection('posts').add(post);
        _postController.clear();
        _imageUrlController.clear();
        setState(() {
          _imageUrl = null;
        });
      }
    } catch (e) {
      print('Error creating post: $e');
    }
  }

  Future<void> _deletePost(String postId) async {
    try {
      await FirebaseFirestore.instance.collection('posts').doc(postId).delete();
    } catch (e) {
      print('Error deleting post: $e');
    }
  }

  Future<void> _toggleLike(String postId, List likes) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final userId = user.uid;
        final hasLiked = likes.contains(userId);
        final updatedLikes = List<String>.from(likes);

        if (hasLiked) {
          updatedLikes.remove(userId);
        } else {
          updatedLikes.add(userId);
        }

        await FirebaseFirestore.instance
            .collection('posts')
            .doc(postId)
            .update({
          'likes': updatedLikes,
        });
      }
    } catch (e) {
      print('Error toggling like: $e');
    }
  }

  Future<void> _addComment(String postId, String comment) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final userId = user.uid;
        final newComment = {
          'userId': userId,
          'comment': comment,
          'timestamp': Timestamp.now(),
        };
        await FirebaseFirestore.instance
            .collection('posts')
            .doc(postId)
            .update({
          'comments': FieldValue.arrayUnion([newComment]),
        });
      }
    } catch (e) {
      print('Error adding comment: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chatly'),
        backgroundColor: Colors.teal,
      ),
      body: _currentIndex == 0
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _postController,
                            decoration: const InputDecoration(
                                hintText: 'What\'s on your mind?'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _imageUrlController,
                            decoration: const InputDecoration(
                                hintText: 'Image URL (optional)'),
                            onChanged: (value) {
                              setState(() {
                                _imageUrl = value;
                              });
                            },
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.send),
                          onPressed: _createPost,
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('posts')
                          .orderBy('timestamp', descending: true)
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.hasData) {
                          final posts = snapshot.data!.docs;
                          return ListView.builder(
                            itemCount: posts.length,
                            itemBuilder: (context, index) {
                              final post = posts[index];
                              final postId = post.id;
                              final content = post['content'];
                              final imageUrl = post['imageUrl'];
                              final likes = List<String>.from(post['likes']);
                              final comments = List<Map<String, dynamic>>.from(
                                  post['comments']);
                              final isLiked = likes.contains(
                                  FirebaseAuth.instance.currentUser?.uid);
                              final username = post['username'];
                              final profilePictureUrl =
                                  post['profilePictureUrl'];
                              final timestamp = post['timestamp'] as Timestamp;

                              return Card(
                                margin: const EdgeInsets.symmetric(
                                    horizontal: 16.0, vertical: 8.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    ListTile(
                                      leading: CircleAvatar(
                                        backgroundImage: profilePictureUrl !=
                                                    null &&
                                                profilePictureUrl.isNotEmpty
                                            ? NetworkImage(profilePictureUrl)
                                            : const AssetImage(
                                                    'assets/default_profile_picture.png')
                                                as ImageProvider,
                                      ),
                                      title: Text(username),
                                      subtitle: Text(timestamp
                                          .toDate()
                                          .toString()), // Showing timestamp
                                      trailing: PopupMenuButton<String>(
                                        onSelected: (value) {
                                          if (value == 'edit') {
                                            // Add logic to edit post
                                          } else if (value == 'delete') {
                                            _deletePost(postId);
                                          }
                                        },
                                        itemBuilder: (context) => [
                                          const PopupMenuItem(
                                            value: 'edit',
                                            child: Text('Edit'),
                                          ),
                                          const PopupMenuItem(
                                            value: 'delete',
                                            child: Text('Delete'),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 16.0),
                                      child: Text(content),
                                    ),
                                    if (imageUrl != null && imageUrl.isNotEmpty)
                                      Container(
                                        width:
                                            MediaQuery.of(context).size.width *
                                                0.8,
                                        height:
                                            MediaQuery.of(context).size.height *
                                                0.4,
                                        decoration: BoxDecoration(
                                          image: DecorationImage(
                                            image: NetworkImage(imageUrl),
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                      ),
                                    Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          IconButton(
                                            icon: Icon(
                                              isLiked
                                                  ? Icons.favorite
                                                  : Icons.favorite_border,
                                              color:
                                                  isLiked ? Colors.red : null,
                                            ),
                                            onPressed: () =>
                                                _toggleLike(postId, likes),
                                          ),
                                          Text('${likes.length} Likes'),
                                        ],
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: TextField(
                                              decoration: const InputDecoration(
                                                hintText: 'Add a comment...',
                                              ),
                                              onSubmitted: (value) {
                                                if (value.isNotEmpty) {
                                                  _addComment(postId, value);
                                                }
                                              },
                                            ),
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.send),
                                            onPressed: () {
                                              final value =
                                                  _postController.text;
                                              if (value.isNotEmpty) {
                                                _addComment(postId, value);
                                                _postController.clear();
                                              }
                                            },
                                          ),
                                        ],
                                      ),
                                    ),
                                    ...comments.map((comment) {
                                      return ListTile(
                                        title: Text(comment['comment']),
                                        subtitle: Text(
                                            'User ${comment['userId']} - ${comment['timestamp'].toDate()}'),
                                      );
                                    }).toList(),
                                  ],
                                ),
                              );
                            },
                          );
                        } else if (snapshot.hasError) {
                          return const Center(
                              child: Text('Error loading posts.'));
                        } else {
                          return const Center(
                              child: CircularProgressIndicator());
                        }
                      },
                    ),
                  ),
                ],
              ),
            )
          : _currentIndex == 1
              ? const DiscoverScreen() // Show DiscoverScreen for index 1
              : _currentIndex == 2
                  ? const NotificationScreen() // Show NotificationsScreen for index 2
                  : _currentIndex == 3
                      ? const LibraryScreen() // Show LibraryScreen for index 3
                      : const ProfileScreen(), // Show ProfileScreen for index 4
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.teal,
        selectedItemColor: Colors.teal,
        unselectedItemColor: Colors.tealAccent,
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.explore),
            label: 'Discover',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications),
            label: 'Notifications',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.photo_library),
            label: 'Library',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
