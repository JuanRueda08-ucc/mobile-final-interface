import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Identidad local estable durante toda una sesión de monitoreo.
final monitoringAccountIdProvider = Provider<String?>((ref) => null);
final monitoringAccountRequiredProvider = Provider<bool>((ref) => false);
