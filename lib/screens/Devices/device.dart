import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:seim_canary/models/enchufe_model.dart';
import 'package:seim_canary/screens/Devices/register_device_screen.dart';
import 'package:seim_canary/screens/Devices/settings_device_screen.dart';

class DeviceScreen extends StatefulWidget {
  const DeviceScreen({super.key});

  @override
  State<DeviceScreen> createState() => _DeviceScreenState();
}

class _DeviceScreenState extends State<DeviceScreen> {
  final DatabaseReference _dbRef =
      FirebaseDatabase.instance.ref().child('enchufes');
  final Map<String, Timer> _timers =
      {}; // Manejador de temporizadores por dispositivo
  final Map<String, int> _minuteCounters =
      {}; // Contadores de minutos por dispositivo

  @override
  void dispose() {
    // Cancelar todos los temporizadores al salir
    _timers.forEach((_, timer) => timer.cancel());
    super.dispose();
  }

  void _toggleDeviceState(EnchufeModel enchufe) {
    setState(() {
      enchufe.estado = !enchufe.estado;

      if (enchufe.estado) {
        // Encendido: Iniciar temporizador
        _startCountingMinutes(enchufe);
      } else {
        // Apagado: Detener temporizador y guardar datos
        _stopCountingMinutes(enchufe);
      }

      // Actualizar estado en Firebase
      _dbRef.child(enchufe.id).update({'estado': enchufe.estado});
    });
  }

  void _startCountingMinutes(EnchufeModel enchufe) {
    // Inicializar el contador si no existe
    if (!_minuteCounters.containsKey(enchufe.id)) {
      _minuteCounters[enchufe.id] = 0;
    }

    // Crear un temporizador que aumente el contador cada minuto
    _timers[enchufe.id]?.cancel(); // Cancelar temporizador anterior si existe
    _timers[enchufe.id] = Timer.periodic(const Duration(minutes: 1), (timer) {
      setState(() {
        _minuteCounters[enchufe.id] = (_minuteCounters[enchufe.id] ?? 0) + 1;
      });
    });
  }

  void _stopCountingMinutes(EnchufeModel enchufe) {
    // Detener el temporizador
    _timers[enchufe.id]?.cancel();
    _timers.remove(enchufe.id);

    // Guardar los datos en Firebase bajo "tiempo"
    final int minutosEncendido = _minuteCounters[enchufe.id] ?? 0;
    if (minutosEncendido > 0) {
      final fechaActual = DateTime.now()
          .toIso8601String()
          .split('T')[0]; // Fecha en formato YYYY-MM-DD
      final nuevoRegistro = {
        'fecha': fechaActual,
        'tiempo': minutosEncendido,
      };

      _dbRef.child('${enchufe.id}/tiempo/$fechaActual').set(nuevoRegistro);
      _minuteCounters[enchufe.id] = 0; // Reiniciar contador
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Enchufes Registrados'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Registrar nuevo dispositivo',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => RegisterDeviceScreen(
                    onDeviceAdded: (newDevice) async {
                      await _dbRef.child(newDevice.id).set(newDevice.toJson());
                      setState(() {});
                    },
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<DatabaseEvent>(
        stream: _dbRef.onValue.asBroadcastStream(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting ||
              !snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.data!.snapshot.value == null) {
            return const Center(child: Text('No hay enchufes registrados.'));
          }

          final data = snapshot.data!.snapshot.value;
          Map<String, dynamic> enchufesData;

          if (data is List) {
            enchufesData = {
              for (int i = 0; i < data.length; i++) i.toString(): data[i]
            };
          } else if (data is Map) {
            enchufesData = Map<String, dynamic>.from(data);
          } else {
            return const Center(child: Text('Formato de datos no compatible.'));
          }

          final enchufes = enchufesData.entries.map((entry) {
            final id = entry.key;
            final datos = Map<String, dynamic>.from(entry.value);

            return EnchufeModel(
              id: id,
              nombre: datos['nombre'] ?? 'Sin nombre',
              usuario: datos['usuario'] ?? '',
              estado: datos['estado'] ?? false,
              dispositivo:
                  datos['categoria']['dispositivo'] ?? 'Sin dispositivo',
              tipo: datos['categoria']['tipo'] ?? 'Sin tipo',
              tiempo: (datos['tiempo'] is Map
                  ? (datos['tiempo'] as Map<dynamic, dynamic>).map((key, value) {
                      final valueMap = Map<String, dynamic>.from(value as Map);
                      return MapEntry(
                          key.toString(), RegistroTiempo.fromJson(valueMap));
                    })
                  : <String, RegistroTiempo>{}),
              horario: Horario.fromJson(
                  Map<String, dynamic>.from(datos['horario'] ?? {})),
            );
          }).toList();

          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 0.9,
            ),
            itemCount: enchufes.length,
            itemBuilder: (context, index) {
              final enchufe = enchufes[index];
              return GestureDetector(
                onTap: () {
                  _toggleDeviceState(enchufe);
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 6,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      // Información centrada
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Icon(
                            enchufe.estado ? Icons.power : Icons.power_off,
                            size: 48,
                            color: enchufe.estado ? Colors.amber : Colors.grey,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            enchufe.nombre,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            'Dispositivo: ${enchufe.dispositivo}',
                            textAlign: TextAlign.center,
                          ),
                          Text(
                            'Tipo: ${enchufe.tipo}',
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                      // Icono de configuración alineado en la parte superior derecha
                      Align(
                        alignment: Alignment.topRight,
                        child: IconButton(
                          icon: const Icon(Icons.settings, color: Colors.grey),
                          tooltip: 'Configuración',
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => SettingsDeviceScreen(
                                  deviceId: enchufe.id,
                                  deviceData: {
                                    'nombre': enchufe.nombre,
                                    'tipo': enchufe.tipo,
                                    'horario': enchufe.horario.toJson(),
                                  },
                                  onSave: (updatedData) async {
                                    await _dbRef
                                        .child(enchufe.id)
                                        .update(updatedData);
                                    setState(() {});
                                  },
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
