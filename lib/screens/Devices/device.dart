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
  DateTime? _encendidoTime;

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
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: StreamBuilder<DatabaseEvent>(
          stream: _databaseRef.onValue,
          builder: (context, snapshot) {
            final data = snapshot.data?.snapshot.value;
            bool currentValue = false;
            String encenderHora = "--:--";
            String apagarHora = "--:--";

            if (data is Map<dynamic, dynamic>) {
              currentValue = data["estado"] ?? false;
              encenderHora = data["horario"]?["encender"] ?? "--:--";
              apagarHora = data["horario"]?["apagar"] ?? "--:--";
            }

            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
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
                    onChanged: (bool value) async {
                      await _updateState(value);
                    },
                    activeColor: Colors.green,
                    inactiveThumbColor: Colors.red,
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}