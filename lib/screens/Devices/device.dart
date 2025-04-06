import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:seim_canary/screens/Devices/settings_device_screen.dart';

class DeviceScreen extends StatefulWidget {
  const DeviceScreen({super.key});

  @override
  State<DeviceScreen> createState() => _DeviceScreenState();
}

class _DeviceScreenState extends State<DeviceScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isToggling = false;

  // Función mejorada para obtener el tipo
  String _getDisplayType(Map<String, dynamic> data) {
    return data['tipo']?.toString() ?? 'No configurado';
  }

  // Función para obtener la categoría basada en el tipo
  String? _getDisplayCategory(Map<String, dynamic> data) {
    final type = data['tipo']?.toString();
    if (type == null) return null;
    
    final categories = {
      'Tostadoras': ['800w', '1200w', '1500w', '1800w'],
      'Bombillas': ['Fluorescente', 'Halogena', 'LED', 'Incandescente'],
      'Cafeteras': ['Italiana', 'ExpresoManual', 'Goteo'],
      'Ventiladores': ['Mesa', 'Pared', 'Torre', 'Pie'],
    };

    for (final category in categories.keys) {
      if (categories[category]!.any((t) => t.toLowerCase() == type.toLowerCase())) {
        return category;
      }
    }
    
    return null;
  }

  Future<void> _toggleDeviceState(String deviceId, bool currentStatus) async {
    setState(() => _isToggling = true);
    try {
      await _firestore.collection('devices').doc(deviceId).update({
        'estado': !currentStatus,
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cambiar estado: $e')),
      );
    } finally {
      setState(() => _isToggling = false);
    }
  }

  Future<void> _handleSaveSettings(String deviceId, Map<String, dynamic> newData) async {
    try {
      await _firestore.collection('devices').doc(deviceId).update(newData);
      // Actualizar el estado local después de guardar
      setState(() {});
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al guardar configuración: $e')),
      );
      throw Exception('Error al guardar configuración');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dispositivos'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore.collection('devices').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 0.9,
            ),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final doc = snapshot.data!.docs[index];
              final data = doc.data() as Map<String, dynamic>;
              final deviceState = data['estado'] ?? false;
              final displayType = _getDisplayType(data);
              final displayCategory = _getDisplayCategory(data);

              IconData icon;
              Color iconColor;

              // Asignación de iconos según tipo
              switch (displayType.toLowerCase()) {
                case 'fluorescente':
                  icon = Icons.lightbulb;
                  iconColor = Colors.grey;
                  break;
                case 'halogena':
                  icon = Icons.lightbulb;
                  iconColor = Colors.grey;
                  break;
                case 'incandescente':
                  icon = Icons.lightbulb;
                  iconColor = Colors.grey;
                  break;
                case 'led':
                  icon = Icons.lightbulb;
                  iconColor = Colors.grey;
                  break;
                case '800w':
                case '1200w':
                case '1500w':
                case '1800w':
                  icon = Icons.kitchen;
                  iconColor = Colors.grey;
                  break;
                case 'mesa':
                case 'pared':
                case 'torre':
                case 'pie':
                  icon = Icons.air_outlined;
                  iconColor = Colors.blueGrey;
                  break;
                case 'italiana':
                case 'expresomanual':
                case 'goteo':
                  icon = Icons.coffee;
                  iconColor = Colors.grey;
                  break;
                default:
                  icon = Icons.device_unknown;
                  iconColor = Colors.grey;
              }

              return GestureDetector(
                onTap: _isToggling 
                    ? null 
                    : () => _toggleDeviceState(doc.id, deviceState),
                child: Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(16),
                    border: deviceState
                        ? Border.all(color: Colors.amber, width: 2)
                        : null,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 6,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        icon,
                        size: 48,
                        color: deviceState ? Colors.amber : iconColor,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        displayCategory ?? 'Sin categoría',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      Text(
                        'Tipo: $displayType',
                        style: TextStyle(
                          color: displayType == 'No configurado'
                              ? Colors.orange
                              : Colors.grey[600],
                        ),
                      ),
                      // Mostrar horario si existe
                      if (data['horario'] != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Encender: ${data['horario']['encender'] ?? '--:--'}',
                          style: const TextStyle(fontSize: 12),
                        ),
                        Text(
                          'Apagar: ${data['horario']['apagar'] ?? '--:--'}',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                      IconButton(
                        icon: const Icon(Icons.settings),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => SettingsDeviceScreen(
                                deviceId: doc.id,
                                deviceData: data,
                                onSave: (newData) => _handleSaveSettings(doc.id, newData),
                              ),
                            ),
                          ).then((_) {
                            if (mounted) setState(() {});
                          });
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