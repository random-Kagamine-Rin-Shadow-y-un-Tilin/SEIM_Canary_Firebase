import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';

class ToggleDeviceScreen extends StatefulWidget {
  const ToggleDeviceScreen({super.key});

  @override
  State<ToggleDeviceScreen> createState() => _ToggleDeviceScreenState();
}

class _ToggleDeviceScreenState extends State<ToggleDeviceScreen> {
  final DatabaseReference _databaseRef = FirebaseDatabase.instance.ref('enchufe');
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startAutomaticCheck();
  }

  /// Verifica la hora y cambia el estado automáticamente
  void _startAutomaticCheck() {
    _timer = Timer.periodic(const Duration(minutes: 1), (timer) async {
      String horaActual = DateFormat('HH:mm').format(DateTime.now());

      DatabaseEvent horarioSnapshot = await _databaseRef.child("horario").once();
      DatabaseEvent estadoSnapshot = await _databaseRef.child("estado").once();

      final data = horarioSnapshot.snapshot.value;
      bool currentEstado = estadoSnapshot.snapshot.value as bool? ?? false;

      if (data is Map<dynamic, dynamic>) {
        String? encenderHora = data["encender"];
        String? apagarHora = data["apagar"];

        if (encenderHora != null && horaActual == encenderHora && !currentEstado) {
          await _updateState(true);
        } else if (apagarHora != null && horaActual == apagarHora && currentEstado) {
          await _updateState(false);
        }
      }
    });
  }

  /// Cambia el estado del enchufe en Firebase
  Future<void> _updateState(bool newValue) async {
    try {
      await _databaseRef.update({"estado": newValue});
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  /// Permite al usuario elegir una hora y guardarla en Firebase
  Future<void> _seleccionarHora(BuildContext context, bool esEncender) async {
    DatabaseEvent horarioSnapshot = await _databaseRef.child("horario").once();
    final data = horarioSnapshot.snapshot.value;

    String? horaActual;
    if (data is Map<dynamic, dynamic>) {
      horaActual = esEncender ? data["encender"] : data["apagar"];
    }

    // Si la hora es nula, usar la hora actual como referencia
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
      String horaFinal = "${nuevaHora.hour.toString().padLeft(2, '0')}:${nuevaHora.minute.toString().padLeft(2, '0')}";

      // Actualizar Firebase con la nueva hora
      await _databaseRef.child("horario").update(
        esEncender ? {"encender": horaFinal} : {"apagar": horaFinal},
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
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            /// **Tarjeta de configuración de horario en tiempo real**
            StreamBuilder<DatabaseEvent>(
              stream: _databaseRef.child("horario").onValue,
              builder: (context, snapshot) {
                final data = snapshot.data?.snapshot.value;
                String encenderHora = "--:--";
                String apagarHora = "--:--";

                if (data is Map<dynamic, dynamic>) {
                  encenderHora = data["encender"] ?? "--:--";
                  apagarHora = data["apagar"] ?? "--:--";
                }

                return Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        const Text("Configuración de Horario",
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 12),
                        ListTile(
                          title: Text("Hora de Encendido: $encenderHora"),
                          trailing: IconButton(
                            icon: const Icon(Icons.access_time),
                            onPressed: () => _seleccionarHora(context, true),
                          ),
                        ),
                        ListTile(
                          title: Text("Hora de Apagado: $apagarHora"),
                          trailing: IconButton(
                            icon: const Icon(Icons.access_time),
                            onPressed: () => _seleccionarHora(context, false),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 20),

            /// **Tarjeta de Control de Estado en tiempo real**
            StreamBuilder<DatabaseEvent>(
              stream: _databaseRef.child("estado").onValue,
              builder: (context, snapshot) {
                bool currentValue = snapshot.data?.snapshot.value as bool? ?? false;

                return Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        const Text("Estado del Enchufe",
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 12),
                        SwitchListTile(
                          title: Text(
                            currentValue ? "ENCENDIDO" : "APAGADO",
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                          ),
                          value: currentValue,
                          onChanged: (bool value) => _updateState(value),
                          activeColor: Colors.green,
                          inactiveThumbColor: Colors.red,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
