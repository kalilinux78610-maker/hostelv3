import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'common_providers.g.dart';

@riverpod
FirebaseAuth firebaseAuth(Ref ref) {
  return FirebaseAuth.instance;
}

@riverpod
FirebaseFirestore firestore(Ref ref) {
  return FirebaseFirestore.instance;
}

@riverpod
User? authState(Ref ref) {
  return ref.watch(firebaseAuthProvider).currentUser;
}

@riverpod
Future<Map<String, dynamic>?> userData(Ref ref) async {
  final user = ref.watch(authStateProvider);
  if (user == null) return null;
  final firestoreInstance = ref.watch(firestoreProvider);
  final doc = await firestoreInstance.collection('users').doc(user.uid).get();
  return doc.data();
}
