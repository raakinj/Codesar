import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String _dateStr(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> saveUserProfile({
    required String uid,
    required Map<String, dynamic> data,
  }) async {
    await _firestore.collection('users').doc(uid).set(data, SetOptions(merge: true));
  }

  Future<DocumentSnapshot> getUserProfile(String uid) async {
    return await _firestore.collection('users').doc(uid).get();
  }

  Future<bool> isSlugTaken(String slug, String currentUid) async {
    final q = await _firestore
        .collection('users')
        .where('slug', isEqualTo: slug)
        .limit(1)
        .get();
    if (q.docs.isEmpty) return false;
    return q.docs.first.id != currentUid;
  }

  Future<Map<String, dynamic>?> getUserBySlug(String slug) async {
    final q = await _firestore
        .collection('users')
        .where('slug', isEqualTo: slug)
        .limit(1)
        .get();
    if (q.docs.isEmpty) return null;
    return q.docs.first.data();
  }

  Future<void> incrementProfileViews(String uid) async {
    final today = _dateStr(DateTime.now());
    await Future.wait([
      _firestore.collection('users').doc(uid).update({'profileViews': FieldValue.increment(1)}),
      _firestore
          .collection('users')
          .doc(uid)
          .collection('analytics_history')
          .doc(today)
          .set({'profileViews': FieldValue.increment(1)}, SetOptions(merge: true)),
    ]);
  }

  Future<void> incrementQrScans(String uid) async {
    final today = _dateStr(DateTime.now());
    await Future.wait([
      _firestore.collection('users').doc(uid).update({'qrScans': FieldValue.increment(1)}),
      _firestore
          .collection('users')
          .doc(uid)
          .collection('analytics_history')
          .doc(today)
          .set({'qrScans': FieldValue.increment(1)}, SetOptions(merge: true)),
    ]);
  }

  Future<void> incrementContactsSaved(String uid) async {
    final today = _dateStr(DateTime.now());
    await Future.wait([
      _firestore.collection('users').doc(uid).update({'contactsSaved': FieldValue.increment(1)}),
      _firestore
          .collection('users')
          .doc(uid)
          .collection('analytics_history')
          .doc(today)
          .set({'contactsSaved': FieldValue.increment(1)}, SetOptions(merge: true)),
    ]);
  }

  Future<List<Map<String, dynamic>>> getWeeklyAnalytics(String uid) async {
    final now = DateTime.now();
    final dates = List.generate(7, (i) => now.subtract(Duration(days: 6 - i)));
    final dayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

    final futures = dates
        .map((d) => _firestore
            .collection('users')
            .doc(uid)
            .collection('analytics_history')
            .doc(_dateStr(d))
            .get())
        .toList();

    final docs = await Future.wait(futures);

    return List.generate(7, (i) {
      final data = docs[i].data() ?? {};
      return {
        'day': dayLabels[dates[i].weekday - 1],
        'profileViews': ((data['profileViews'] ?? 0) as num).toDouble(),
        'qrScans': ((data['qrScans'] ?? 0) as num).toDouble(),
        'contactsSaved': ((data['contactsSaved'] ?? 0) as num).toDouble(),
      };
    });
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

    return _firestore.runTransaction<bool>((tx) async {
      final existing = await tx.get(contactRef);
      if (existing.exists) return false;
      tx.set(contactRef, {...contactData, 'tags': []});
      tx.update(profileRef, {'contactsSaved': FieldValue.increment(1)});
      return true;
    });
  }

  Future<void> updateContactTags({
    required String ownerUid,
    required String contactUid,
    required List<String> tags,
  }) async {
    await _firestore
        .collection('users')
        .doc(ownerUid)
        .collection('contacts')
        .doc(contactUid)
        .update({'tags': tags});
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
      await _firestore
          .collection('users')
          .doc(contactUid)
          .update({'contactsSaved': FieldValue.increment(-1)});
    } catch (_) {}
  }
}
