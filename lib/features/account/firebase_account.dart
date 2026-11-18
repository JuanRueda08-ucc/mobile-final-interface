import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:monitoring_engine/monitoring_engine.dart';

import '../experimental/experimental_monitoring_controller.dart';
import 'cloud_sessions.dart';

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

/// Texto para un fallo de Firebase Authentication en las acciones de la
/// cuenta (cambiar correo o contraseña, eliminar la cuenta).
String accountActionError(Object error) {
  if (error is FirebaseAuthException) {
    return switch (error.code) {
      'wrong-password' ||
      'invalid-credential' => 'La contraseña actual no es correcta.',
      'invalid-email' => 'Escribe un correo válido.',
      'email-already-in-use' => 'Ese correo ya está en uso.',
      'weak-password' || 'password-does-not-meet-requirements' =>
        'La contraseña nueva no cumple todos los requisitos.',
      'requires-recent-login' =>
        'Por seguridad, cierra sesión, vuelve a entrar y repite la acción.',
      'network-request-failed' => 'Comprueba tu conexión y vuelve a intentar.',
      'too-many-requests' => 'Espera unos minutos antes de volver a intentar.',
      _ => 'No se pudo completar la solicitud. Vuelve a intentar.',
    };
  }
  if (error is FirebaseException) {
    return 'No se pudo completar la solicitud. Comprueba tu conexión.';
  }
  return 'No se pudo completar la solicitud. Vuelve a intentar.';
}

Future<void> _reauthenticate(User user, String password) {
  final email = user.email;
  if (email == null) throw StateError('La cuenta no tiene correo.');
  return user.reauthenticateWithCredential(
    EmailAuthProvider.credential(email: email, password: password),
  );
}

/// Pide el cambio de correo: confirma la contraseña actual y envía un
/// enlace al correo nuevo. Firebase lo aplica cuando se abre el enlace.
Future<void> requestAccountEmailChange(
  User user, {
  required String password,
  required String newEmail,
}) async {
  await _reauthenticate(user, password);
  await user.verifyBeforeUpdateEmail(newEmail);
}

Future<void> changeAccountPassword(
  User user, {
  required String password,
  required String newPassword,
}) async {
  await _reauthenticate(user, password);
  await user.updatePassword(newPassword);
}

/// Elimina la cuenta: confirma la contraseña, retira los resúmenes de la
/// nube y borra el usuario. Los registros de este teléfono se conservan.
/// Devuelve un texto si el monitoreo lo impide.
Future<String?> deleteVigiaAccount(
  WidgetRef ref,
  FirebaseAuth auth, {
  required String password,
}) async {
  const blocked = 'Finaliza el monitoreo antes de eliminar la cuenta.';
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
  final user = auth.currentUser;
  if (user == null) return 'No hay una sesión abierta.';
  final erase = ref.read(cloudSessionsEraserProvider);
  await _reauthenticate(user, password);
  await erase(user.uid);
  await user.delete();
  return null;
}
