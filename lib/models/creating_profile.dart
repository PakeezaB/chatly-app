import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> createUserProfile(String userId, String username, String email,
    String profilePictureUrl) async {
  final usersCollection = FirebaseFirestore.instance.collection('users');

  await usersCollection.doc(userId).set({
    'userId': userId,
    'username': username,
    'email': email,
    'profilePictureUrl': profilePictureUrl,
  });
}
