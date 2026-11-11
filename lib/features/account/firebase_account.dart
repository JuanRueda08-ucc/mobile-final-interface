import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const firebaseAccountsEnabled = bool.fromEnvironment('VIGIA_FIREBASE');

Future<void> initializeVigiaFirebase() async {
  const options = FirebaseOptions(
    apiKey: String.fromEnvironment('VIGIA_FIREBASE_API_KEY'),
    appId: String.fromEnvironment('VIGIA_FIREBASE_APP_ID'),
    messagingSenderId: String.fromEnvironment('VIGIA_FIREBASE_SENDER_ID'),
    projectId: String.fromEnvironment('VIGIA_FIREBASE_PROJECT_ID'),
  );
  if ([
    options.apiKey,
    options.appId,
    options.messagingSenderId,
    options.projectId,
  ].any((value) => value.isEmpty)) {
    throw StateError('Falta la configuración de Firebase para Vigía.');
  }
  await Firebase.initializeApp(options: options);
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: false,
  );
}

final firebaseAuthProvider = Provider<FirebaseAuth?>((ref) => null);

final firebaseUserProvider = StreamProvider<User?>((ref) {
  return ref.watch(firebaseAuthProvider)?.userChanges() ?? Stream.value(null);
});

final verifiedFirebaseUidProvider = Provider<String?>((ref) {
  final user = ref.watch(firebaseUserProvider).asData?.value;
  return user?.emailVerified == true ? user!.uid : null;
});
