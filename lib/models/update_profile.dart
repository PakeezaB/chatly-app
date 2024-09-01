import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> updateUserProfile(String userId, String username, String email,
    String profilePictureUrl) async {
  final usersCollection = FirebaseFirestore.instance.collection('users');

  await usersCollection.doc(userId).update({
    'username': username,
    'email': email,
    'profilePictureUrl': profilePictureUrl,
  });
}
