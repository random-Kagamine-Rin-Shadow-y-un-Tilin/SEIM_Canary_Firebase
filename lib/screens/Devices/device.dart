import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';

class DeviceScreen extends StatefulWidget {
  const DeviceScreen({super.key});

  @override
  State<DeviceScreen> createState() => _DeviceScreenState();
}

class _DeviceScreenState extends State<DeviceScreen> {
  final DatabaseReference _databaseRef =
      FirebaseDatabase.instance.ref('enchufe');
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startAutomaticCheck();
  }

  void _startAutomaticCheck() {
    _timer = Timer.periodic(const Duration(minutes: 1), (timer) async {
      String horaActual = DateFormat('HH:mm').format(DateTime.now());
      DatabaseEvent horarioSnapshot =
          await _databaseRef.child("horario").once();
      DatabaseEvent estadoSnapshot = await _databaseRef.child("estado").once();

      final data = horarioSnapshot.snapshot.value;
      bool currentEstado = estadoSnapshot.snapshot.value as bool? ?? false;

      if (data is Map<dynamic, dynamic>) {
        String? encenderHora = data["encender"];
        String? apagarHora = data["apagar"];

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
    });
  }

  Future<void> _updateState(bool newValue) async {
    try {
      await _databaseRef.update({"estado": newValue});
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> _updateDeviceName(String newName) async {
    try {
      await _databaseRef.update({"nombre": newName});
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> _seleccionarHora(BuildContext context, bool esEncender) async {
    DatabaseEvent horarioSnapshot = await _databaseRef.child("horario").once();
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
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              // Acción para agregar un nuevo dispositivo
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: StreamBuilder<DatabaseEvent>(
          stream: _databaseRef.onValue,
          builder: (context, snapshot) {
            final data = snapshot.data?.snapshot.value;
            String encenderHora = "--:--";
            String apagarHora = "--:--";
            bool currentValue = false;
            String deviceName = "Enchufe";

            if (data is Map<dynamic, dynamic>) {
              encenderHora = data["horario"]?["encender"] ?? "--:--";
              apagarHora = data["horario"]?["apagar"] ?? "--:--";
              currentValue = data["estado"] ?? false;
              deviceName = data["nombre"] ?? "Enchufe";
            }

            return Center(
              child: Card(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            deviceName,
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: () async {
                              TextEditingController controller =
                                  TextEditingController(text: deviceName);
                              String? newName = await showDialog<String>(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text("Editar Nombre"),
                                  content: TextField(
                                    controller: controller,
                                    decoration: const InputDecoration(
                                        hintText: "Nuevo nombre"),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: const Text("Cancelar"),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        Navigator.pop(
                                            context, controller.text);
                                      },
                                      child: const Text("Guardar"),
                                    ),
                                  ],
                                ),
                              );
                              if (newName != null && newName.isNotEmpty) {
                                _updateDeviceName(newName);
                              }
                            },
                          ),
                        ],
                      ),
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
                      SwitchListTile(
                        title: Text(
                          currentValue ? "ENCENDIDO" : "APAGADO",
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w500),
                        ),
                        value: currentValue,
                        onChanged: (bool value) => _updateState(value),
                        activeColor: Colors.green,
                        inactiveThumbColor: Colors.red,
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
