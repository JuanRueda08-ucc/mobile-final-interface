import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:monitoring_engine/monitoring_engine.dart';

import '../experimental/experimental_monitoring_controller.dart';

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

Future<String?> signOutOfVigia(WidgetRef ref, FirebaseAuth auth) async {
  const blocked = 'Finaliza el monitoreo antes de cerrar sesión.';
  final state = ref.read(experimentalMonitoringProvider);
  if (state.sessionVigente || state.pending != null) return blocked;
  final snapshot = await ref
      .read(experimentalMonitoringProvider.notifier)
      .queryCurrentSnapshot();
  if (!ref.context.mounted) return null;
  if (snapshot.lifecycle == EngineSessionLifecycle.active ||
      snapshot.lifecycle == EngineSessionLifecycle.paused ||
      ref.read(experimentalMonitoringProvider).pending != null) {
    return blocked;
  }
  await auth.signOut();
  return null;
}
