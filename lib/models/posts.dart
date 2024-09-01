import 'package:cloud_firestore/cloud_firestore.dart';

class Post {
  String postId;
  String userId;
  String content;
  String imageUrl;
  Timestamp timestamp;
  List<String> likes;
  List<String> comments;

  Post({
    required this.postId,
    required this.userId,
    required this.content,
    required this.imageUrl,
    required this.timestamp,
    required this.likes,
    required this.comments,
  });

  factory Post.fromDocument(DocumentSnapshot doc) {
    return Post(
      postId: doc.id,
      userId: doc['userId'],
      content: doc['content'],
      imageUrl: doc['imageUrl'],
      timestamp: doc['timestamp'],
      likes: List<String>.from(doc['likes']),
      comments: List<String>.from(doc['comments']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'postId': postId,
      'userId': userId,
      'content': content,
      'imageUrl': imageUrl,
      'timestamp': timestamp,
      'likes': likes,
      'comments': comments,
    };
  }
}
