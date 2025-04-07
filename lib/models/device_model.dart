import 'package:cloud_firestore/cloud_firestore.dart';

class DeviceModel {
  //-------------------- Variables --------------------
  final String id;
  final String nombre;
  final String dispositivo;
  final String tipo;
  final String horarioEncender;
  final String horarioApagar;
  final bool estado;

  //-------------------- Constructor --------------------
  DeviceModel({
    required this.id,
    required this.nombre,
    required this.dispositivo,
    required this.tipo,
    required this.horarioEncender,
    required this.horarioApagar,
    required this.estado,
  });

  //-------------------- Map --------------------
  Map<String, dynamic> toJson() {
    return {
      'nombre': nombre,
      'estado': estado,
      'categoria': {
        'dispositivo': dispositivo,
        'tipo': tipo,
      },
      'horario': {
        'encender': horarioEncender,
        'apagar': horarioApagar,
      },
    };
  }

  //-------------------- Factory --------------------
  factory DeviceModel.fromDocumentSnapshot(DocumentSnapshot doc) {
    var data = doc.data() as Map<String, dynamic>;
    return DeviceModel(
      id: doc.id,
      nombre: data['nombre'] ?? '',
      dispositivo: data['categoria']['dispositivo'] ?? '',
      tipo: data['categoria']['tipo'] ?? '',
      horarioEncender: data['horario']['encender'] ?? '--:--',
      horarioApagar: data['horario']['apagar'] ?? '--:--',
      estado: data['estado'] ?? false,
    );
  }
}
