import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Get user profile
  Future<UserModel?> getUserProfile(String uid) async {
    try {
      DocumentSnapshot doc = await _db.collection('users').doc(uid).get();
      if (doc.exists) {
        return UserModel.fromMap(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      print('Error getting user profile: $e');
      return null;
    }
  }

  // Stream user profile
  Stream<UserModel?> getUserProfileStream(String uid) {
    return _db.collection('users').doc(uid).snapshots().map((doc) {
      if (doc.exists) {
        return UserModel.fromMap(doc.data() as Map<String, dynamic>);
      }
      return null;
    });
  }


  // Create or update user profile
  Future<void> saveUserProfile(UserModel user) async {
    try {
      await _db.collection('users').doc(user.uid).set(user.toMap(), SetOptions(merge: true));
    } catch (e) {
      print('Error saving user profile: $e');
    }
  }

  // Update specific fields (like gold or provisions)
  Future<void> updateUserField(String uid, String field, dynamic value) async {
    try {
      await _db.collection('users').doc(uid).update({field: value});
    } catch (e) {
      print('Error updating user field: $e');
    }
  }
  
  // Get all users (Admin only ideally, should be protected by security rules)
  Stream<List<UserModel>> getAllUsers() {
    return _db.collection('users').snapshots().map((snapshot) => 
      snapshot.docs.map((doc) => UserModel.fromMap(doc.data())).toList()
    );
  }
}
