import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> saveUserProfile({
    required String uid,
    required Map<String, dynamic> data,
  }) async {
    await _firestore.collection('users').doc(uid).set(
          data,
          SetOptions(merge: true),
        );
  }

  Future<void> incrementProfileViews(String uid) async {
    await _firestore.collection('users').doc(uid).update({
      'profileViews': FieldValue.increment(1),
    });
  }

  Future<void> incrementQrScans(String uid) async {
    await _firestore.collection('users').doc(uid).update({
      'qrScans': FieldValue.increment(1),
    });
  }

  Future<void> incrementContactsSaved(String uid) async {
    await _firestore.collection('users').doc(uid).update({
      'contactsSaved': FieldValue.increment(1),
    });
  }

  Future<DocumentSnapshot> getUserProfile(String uid) async {
    return await _firestore.collection('users').doc(uid).get();
  }

  Future<bool> saveContact({
    required String ownerUid,
    required String contactUid,
    required Map<String, dynamic> contactData,
  }) async {
    final contactRef = _firestore
        .collection('users')
        .doc(ownerUid)
        .collection('contacts')
        .doc(contactUid);

    final profileRef = _firestore.collection('users').doc(contactUid);

    return _firestore.runTransaction<bool>((transaction) async {
      final existing = await transaction.get(contactRef);

      if (existing.exists) {
        return false;
      }

      transaction.set(contactRef, contactData);
      transaction.update(profileRef, {
        'contactsSaved': FieldValue.increment(1),
      });

      return true;
    });
  }

  Future<void> removeContact({
    required String ownerUid,
    required String contactUid,
  }) async {
    await _firestore
        .collection('users')
        .doc(ownerUid)
        .collection('contacts')
        .doc(contactUid)
        .delete();

    try {
      await _firestore.collection('users').doc(contactUid).update({
        'contactsSaved': FieldValue.increment(-1),
      });
    } catch (_) {}
  }
}
