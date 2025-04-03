import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';
import 'package:seim_canary/screens/Devices/settings_device_screen.dart';

class DeviceScreen extends StatefulWidget {
  const DeviceScreen({super.key});

  @override
  State<DeviceScreen> createState() => _DeviceScreenState();
}

class _DeviceScreenState extends State<DeviceScreen> {
  final DatabaseReference _databaseRef =
      FirebaseDatabase.instance.ref('enchufe');
  Timer? _timer;
  DateTime? _encendidoTime;

  @override
  void initState() {
    super.initState();
    _startAutomaticCheck();
  }

  void _startAutomaticCheck() {
    _timer = Timer.periodic(const Duration(minutes: 1), (timer) async {
      String horaActual = DateFormat('HH:mm').format(DateTime.now());

      try {
        DatabaseEvent horarioSnapshot =
            await _databaseRef.child("horario").once();
        DatabaseEvent estadoSnapshot =
            await _databaseRef.child("estado").once();

        final horarioData = horarioSnapshot.snapshot.value;
        bool currentEstado = estadoSnapshot.snapshot.value as bool? ?? false;

        if (horarioData is Map<dynamic, dynamic>) {
          String? encenderHora = horarioData["encender"];
          String? apagarHora = horarioData["apagar"];

          if (encenderHora != null &&
              horaActual == encenderHora &&
              !currentEstado) {
            await _updateState(true);
          } else if (apagarHora != null &&
              horaActual == apagarHora &&
              currentEstado) {
            await _updateState(false);
          }
        }
      } catch (e) {
        debugPrint('Error in automatic check: $e');
      }
    });
  }

  Future<void> _updateState(bool newValue) async {
    try {
      String fechaActual = DateFormat('yyyy-MM-dd').format(DateTime.now());

      if (newValue) {
        _encendidoTime = DateTime.now();
      } else {
        if (_encendidoTime != null) {
          DateTime ahora = DateTime.now();
          Duration encendidoDuration = ahora.difference(_encendidoTime!);
          int minutosEncendido = encendidoDuration.inMinutes;

          DatabaseEvent tiempoSnapshot =
              await _databaseRef.child("tiempo/$fechaActual/tiempo").once();
          int minutosPrevios = (tiempoSnapshot.snapshot.value as int?) ?? 0;

          await _databaseRef.child("tiempo/$fechaActual").update({
            "fecha": fechaActual,
            "tiempo": minutosPrevios + minutosEncendido,
          });
        }
      }

      await _databaseRef.update({"estado": newValue});
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> _seleccionarHora(BuildContext context, bool esEncender) async {
    try {
      DatabaseEvent horarioSnapshot =
          await _databaseRef.child("horario").once();
      final data = horarioSnapshot.snapshot.value;

      String? horaActual;
      if (data is Map<dynamic, dynamic>) {
        horaActual = esEncender ? data["encender"] : data["apagar"];
      }

      TimeOfDay initialTime = horaActual != null
          ? TimeOfDay(
              hour: int.parse(horaActual.split(":")[0]),
              minute: int.parse(horaActual.split(":")[1]),
            )
          : TimeOfDay.now();

      TimeOfDay? nuevaHora = await showTimePicker(
        context: context,
        initialTime: initialTime,
      );

      if (nuevaHora != null) {
        String horaFinal =
            "${nuevaHora.hour.toString().padLeft(2, '0')}:${nuevaHora.minute.toString().padLeft(2, '0')}";

        await _databaseRef.child("horario").update(
              esEncender ? {"encender": horaFinal} : {"apagar": horaFinal},
            );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al seleccionar hora: $e')),
      );
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Controlar Enchufe'),
      ),
      body: StreamBuilder<DatabaseEvent>(
        stream: _databaseRef.onValue,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          }

          final data = snapshot.data?.snapshot.value;

          // Handle case where data is not a Map (might be a single value)
          if (data == null) {
            return const Center(
              child: Text('No se encontraron dispositivos'),
            );
          }

          // Convert data to list of devices
          List<Map<String, dynamic>> devices = [];

          if (data is Map<dynamic, dynamic>) {
            devices = data.entries.map((entry) {
              final deviceData = entry.value is Map
                  ? Map<String, dynamic>.from(
                      entry.value as Map<dynamic, dynamic>)
                  : <String, dynamic>{};
              return {
                'id': entry.key.toString(),
                ...deviceData,
              };
            }).toList();
          }

          if (devices.isEmpty) {
            return const Center(
              child: Text('No se encontraron dispositivos'),
            );
          }

          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 0.9,
            ),
            itemCount: devices.length,
            itemBuilder: (context, index) {
              final device = devices[index];
              final deviceId = device['id'];
              final deviceName = device['nombre'] ?? "Dispositivo sin nombre";
              final deviceState =
                  device['estado'] is bool ? device['estado'] as bool : false;
              final categoria = device['categoria'] is Map
                  ? device['categoria'] as Map<dynamic, dynamic>
                  : {};
              final deviceType =
                  categoria['dispositivo']?.toString() ?? 'unknown';
              final tipoDispositivo = categoria['tipo']?.toString() ?? '';

              IconData icon;
              Color iconColor;

              switch (deviceType) {
                case "ventilador":
                  icon = Icons.air;
                  iconColor = Colors.blue;
                  break;
                case "bombillas":
                  icon = Icons.lightbulb;
                  iconColor = Colors.amber;
                  break;
                case "tostadora":
                  icon = Icons.kitchen;
                  iconColor = Colors.brown;
                  break;
                default:
                  icon = Icons.device_unknown;
                  iconColor = Colors.grey;
              }

              return GestureDetector(
                onTap: () => _updateState(!deviceState),
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
                    border: deviceState
                        ? Border.all(color: Colors.amber, width: 2)
                        : null,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        decoration: deviceState
                            ? BoxDecoration(
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.amber.withOpacity(0.7),
                                    spreadRadius: 5,
                                    blurRadius: 10,
                                  ),
                                ],
                              )
                            : null,
                        child: Icon(
                          icon,
                          size: 48,
                          color: deviceState ? Colors.amber : iconColor,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        deviceName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (tipoDispositivo.isNotEmpty)
                        Text(
                          tipoDispositivo,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      const SizedBox(height: 8),
                      IconButton(
                        icon: const Icon(Icons.settings),
                        color: Colors.grey,
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => SettingsDeviceScreen(
                                deviceId: deviceId.toString(),
                                deviceData: device,
                              ),
                            ),
                          );
                        },
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
