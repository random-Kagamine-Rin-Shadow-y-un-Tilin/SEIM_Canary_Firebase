import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:seim_canary/models/enchufe_model.dart';
import 'package:seim_canary/screens/Devices/register_device_screen.dart';
import 'package:seim_canary/screens/Devices/settings_device_screen.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:seim_canary/services/current_user.dart';

class DeviceScreen extends StatefulWidget {
  const DeviceScreen({super.key});

  @override
  State<DeviceScreen> createState() => _DeviceScreenState();
}

class _DeviceScreenState extends State<DeviceScreen> {
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref().child('enchufes');
  final Map<String, Timer> _timers = {};
  final Map<String, int> _minuteCounters = {};

  @override
  void dispose() {
    _timers.forEach((_, timer) => timer.cancel());
    super.dispose();
  }

  // Función para solicitar permisos de Bluetooth y ubicación
  Future<void> requestBluetoothPermissions() async {
    await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.location,
    ].request();
  }

  Future<void> sendBLECommand(String deviceName, String command) async {
    BluetoothDevice? targetDevice;

    // Solicitar permisos antes de continuar
    await requestBluetoothPermissions();

    // Iniciar escaneo
    await FlutterBluePlus.startScan(timeout: const Duration(seconds: 5));

    // Escuchar una vez los resultados del escaneo
    List<ScanResult> scanResults = await FlutterBluePlus.scanResults.first;

    // Buscar el dispositivo por nombre
    for (ScanResult r in scanResults) {
      if (r.device.platformName == deviceName) {
        targetDevice = r.device;
        break;
      }
    }

    // Detener escaneo
    await FlutterBluePlus.stopScan();

    if (targetDevice != null) {
      // Conectar al dispositivo
      await targetDevice.connect();

      // Descubrir servicios
      List<BluetoothService> services = await targetDevice.discoverServices();

      final characteristicUUID = Guid("abcd1234-ab12-cd34-ef56-1234567890ab");

      for (BluetoothService service in services) {
        for (BluetoothCharacteristic characteristic in service.characteristics) {
          if (characteristic.uuid == characteristicUUID) {
            await characteristic.write(command.codeUnits);
            break;
          }
        }
      }

      await targetDevice.disconnect();
    } else {
      print("Dispositivo $deviceName no encontrado.");
    }
  }

  void _toggleDeviceState(EnchufeModel enchufe) async {
    setState(() {
      enchufe.estado = !enchufe.estado;

      if (enchufe.estado) {
        _startCountingMinutes(enchufe);
      } else {
        _stopCountingMinutes(enchufe);
      }

      _dbRef.child(enchufe.id).update({'estado': enchufe.estado});
    });

    final comando = enchufe.estado ? "ON" : "OFF";
    await sendBLECommand("ESP32_RELE", comando);
  }

  void _startCountingMinutes(EnchufeModel enchufe) {
    if (!_minuteCounters.containsKey(enchufe.id)) {
      _minuteCounters[enchufe.id] = 0;
    }

    _timers[enchufe.id]?.cancel();
    _timers[enchufe.id] = Timer.periodic(const Duration(minutes: 1), (timer) {
      setState(() {
        _minuteCounters[enchufe.id] = (_minuteCounters[enchufe.id] ?? 0) + 1;
      });
    });
  }

  void _stopCountingMinutes(EnchufeModel enchufe) {
    _timers[enchufe.id]?.cancel();
    _timers.remove(enchufe.id);

    final int minutosEncendido = _minuteCounters[enchufe.id] ?? 0;
    if (minutosEncendido > 0) {
      final fechaActual = DateTime.now().toIso8601String().split('T')[0];
      final nuevoRegistro = {
        'fecha': fechaActual,
        'tiempo': minutosEncendido,
      };

      _dbRef.child('${enchufe.id}/tiempo/$fechaActual').set(nuevoRegistro);
      _minuteCounters[enchufe.id] = 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = CurrentUser().user;

    if (currentUser == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Enchufes Registrados'),
        ),
        body: const Center(
          child: Text('No se encontró un usuario autenticado.'),
        ),
      );
    }

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
                      final deviceData = newDevice.toJson();
                      deviceData['usuario'] = currentUser.id;
                      await _dbRef.child(newDevice.id).set(deviceData);
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
        stream: _dbRef.orderByChild('usuario').equalTo(currentUser.id).onValue,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting || !snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.data!.snapshot.value == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'No tienes enchufes registrados.',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => RegisterDeviceScreen(
                            onDeviceAdded: (newDevice) async {
                              final currentUser = CurrentUser().user;
                              if (currentUser != null) {
                                final deviceData = newDevice.toJson();
                                deviceData['usuario'] = currentUser.id;
                                await _dbRef.child(newDevice.id).set(deviceData);
                                setState(() {});
                              }
                            },
                          ),
                        ),
                      );
                    },
                    child: const Text('Registrar un nuevo enchufe'),
                  ),
                ],
              ),
            );
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
              dispositivo: datos['categoria']['dispositivo'] ?? 'Sin dispositivo',
              tipo: datos['categoria']['tipo'] ?? 'Sin tipo',
              tiempo: (datos['tiempo'] is Map
                  ? (datos['tiempo'] as Map<dynamic, dynamic>).map((key, value) {
                      final valueMap = Map<String, dynamic>.from(value as Map);
                      return MapEntry(
                          key.toString(), RegistroTiempo.fromJson(valueMap));
                    })
                  : <String, RegistroTiempo>{}),
              horario: Horario.fromJson(Map<String, dynamic>.from(datos['horario'] ?? {})),
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
                          Text('Dispositivo: ${enchufe.dispositivo}', textAlign: TextAlign.center),
                          Text('Tipo: ${enchufe.tipo}', textAlign: TextAlign.center),
                        ],
                      ),
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
                                    await _dbRef.child(enchufe.id).update(updatedData);
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