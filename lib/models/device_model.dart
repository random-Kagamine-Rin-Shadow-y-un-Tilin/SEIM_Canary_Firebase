import 'package:cloud_firestore/cloud_firestore.dart';

class DeviceModel {
  final String id;
  final String name;
  final String type;
  final bool status;
  final double? consumoMin;

  DeviceModel({
    required this.id,
    required this.name,
    required this.type,
    required this.status,
    this.consumoMin,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'type': type,
    'status': status,
    'consumoMin': consumoMin,
  };

  factory DeviceModel.fromDocumentSnapshot(DocumentSnapshot doc) {
    try {
      final data = doc.data() as Map<String, dynamic>? ?? {};
      print("Processing document: ${doc.id} with data: $data");

      String type = '';
      double? consumoMin;
      bool status = false;
      String name = '';

      // Handle status - check both root and nested locations
      status = _extractStatus(data);

      // Extract device type and consumption
      final extraction = _extractTypeAndConsumption(data);
      type = extraction['type'] ?? '';
      consumoMin = extraction['consumoMin'];
      name = extraction['name'] ?? '';

      // Final fallbacks
      if (type.isEmpty) type = 'Unknown';
      if (name.isEmpty) name = type;

      print("Created device: $name ($type), status: $status, consumo: $consumoMin");

      return DeviceModel(
        id: doc.id,
        name: name,
        type: type,
        status: status,
        consumoMin: consumoMin,
      );
    } catch (e) {
      print("Error parsing document ${doc.id}: $e");
      return DeviceModel(
        id: doc.id,
        name: 'Error',
        type: 'Error',
        status: false,
        consumoMin: null,
      );
    }
  }

  static bool _extractStatus(Map<String, dynamic> data) {
    // Check root level first
    if (data.containsKey('estado') && data['estado'] is bool) {
      return data['estado'] as bool;
    }
    
    // Check nested in ventiladores
    if (data.containsKey('ventiladores')) {
      final ventiladores = data['ventiladores'] as Map<String, dynamic>? ?? {};
      if (ventiladores.containsKey('estado') && ventiladores['estado'] is bool) {
        return ventiladores['estado'] as bool;
      }
    }
    
    return false;
  }

  static Map<String, dynamic> _extractTypeAndConsumption(Map<String, dynamic> data) {
    const categories = ['bombillas', 'tostadoras', 'cafeteras', 'ventiladores'];
    String type = '';
    double? consumoMin;
    String name = '';

    for (var category in categories) {
      if (data.containsKey(category)) {
        final categoryData = data[category] as Map<String, dynamic>? ?? {};
        
        // Handle ventiladores specially
        if (category == 'ventiladores') {
          for (var key in categoryData.keys) {
            if (key != 'estado' && categoryData[key] is Map) {
              final deviceData = categoryData[key] as Map<String, dynamic>;
              type = key;
              consumoMin = deviceData['consumoMin']?.toDouble();
              name = 'Ventilador ${_capitalize(key)}';
              break;
            }
          }
        } 
        // Handle other categories
        else if (categoryData.isNotEmpty) {
          type = categoryData.keys.first;
          final deviceData = categoryData[type] as Map<String, dynamic>? ?? {};
          consumoMin = deviceData['consumoMin']?.toDouble();
          name = '${_capitalize(category)} ${_capitalize(type)}';
        }
        break;
      }
    }

    // Get name from root if available
    name = data['nombre']?.toString() ?? name;

    return {
      'type': type,
      'consumoMin': consumoMin,
      'name': name,
    };
  }

  static String _capitalize(String s) => s.isNotEmpty 
      ? s[0].toUpperCase() + s.substring(1).toLowerCase() 
      : s;
}