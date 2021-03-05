import 'package:cloud_firestore/cloud_firestore.dart';

class SwipeCounter {
  String authorID = '';
  int count = 0;
  Timestamp createdAt = Timestamp.now();

  SwipeCounter({this.authorID, this.count, this.createdAt});

  factory SwipeCounter.fromJson(Map<String, dynamic> parsedJson) {
    return new SwipeCounter(
        authorID: parsedJson['authorID'] ?? '',
        count: parsedJson['count'] ?? 0,
        createdAt: parsedJson['createdAt'] ?? Timestamp.now());
  }

  Map<String, dynamic> toJson() {
    return {
      'authorID': this.authorID,
      "count": this.count,
      "createdAt": this.createdAt
    };
  }
}
