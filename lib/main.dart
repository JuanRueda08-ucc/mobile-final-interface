import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:monitoring_engine/monitoring_engine.dart';

/// Base técnica de Vigía (VIG-003).
///
/// Solo identifica la base y comprueba que el plugin nativo local está
/// registrado. No captura cámara, no ejecuta IA, no crea sesiones ni emite
/// alertas: esas funciones llegan en tareas posteriores (Área 08, H01+).
void main() {
  runApp(VigiaApp(engine: MonitoringEngine()));
}

class VigiaApp extends StatelessWidget {
  const VigiaApp({super.key, required this.engine});

  final MonitoringEngine engine;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Vigía',
      theme: ThemeData(useMaterial3: true),
      darkTheme: ThemeData(useMaterial3: true, brightness: Brightness.dark),
      home: BootstrapScreen(engine: engine),
    );
  }
}

/// Pantalla inicial provisional que identifica la base técnica.
class BootstrapScreen extends StatefulWidget {
  const BootstrapScreen({super.key, required this.engine});

  final MonitoringEngine engine;

  @override
  State<BootstrapScreen> createState() => _BootstrapScreenState();
}

class _BootstrapScreenState extends State<BootstrapScreen> {
  late final Future<String> _nativeStatus = _queryNativeStatus();

  Future<String> _queryNativeStatus() async {
    try {
      final platform = await widget.engine.getPlatformVersion();
      return 'Registrado (${platform ?? 'sin datos de plataforma'})';
    } on MissingPluginException {
      return 'No registrado';
    } on PlatformException catch (e) {
      return 'Error del plugin: ${e.code}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Vigía')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text('Base técnica', style: textTheme.headlineSmall),
            const SizedBox(height: 8),
            const Text(
              'Compilación de desarrollo VIG-003: app Flutter Android con el '
              'plugin local monitoring_engine.',
            ),
            const SizedBox(height: 16),
            Text('Plugin nativo', style: textTheme.titleMedium),
            const SizedBox(height: 4),
            FutureBuilder<String>(
              future: _nativeStatus,
              builder: (context, snapshot) => Text(
                snapshot.data ?? 'Comprobando…',
                key: const Key('native-status'),
              ),
            ),
            const SizedBox(height: 16),
            Text('Alcance', style: textTheme.titleMedium),
            const SizedBox(height: 4),
            const Text(
              'Esta base no usa la cámara, no ejecuta IA, no crea sesiones ni '
              'emite alertas. No sirve para monitorear la conducción.',
            ),
          ],
        ),
      ),
    );
  }
}
