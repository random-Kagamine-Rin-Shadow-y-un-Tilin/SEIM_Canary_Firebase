import 'package:cloud_firestore/cloud_firestore.dart';

class EnchufeModel {
  //-------------------- Variables --------------------
  final String id;
  final String nombre;
  final String usuario;
  bool estado; // Cambiado de final a mutable para permitir modificaciones dinámicas
  final String dispositivo;
  final String tipo;
  final Map<String, RegistroTiempo> tiempo;
  final Horario horario;

  //-------------------- Constructor --------------------
  EnchufeModel({
    required this.id,
    required this.nombre,
    required this.usuario,
    required this.estado,
    required this.dispositivo,
    required this.tipo,
    required this.tiempo,
    required this.horario,
  });

  //-------------------- Map --------------------
  Map<String, dynamic> toJson() {
    return {
      'nombre': nombre,
      'usuario': usuario,
      'estado': estado,
      'categoria': {
        'dispositivo': dispositivo,
        'tipo': tipo,
      },
      'tiempo': tiempo.map((key, value) => MapEntry(key, value.toJson())),
      'horario': horario.toJson(),
    };
  }

  //-------------------- Factory --------------------
  factory EnchufeModel.fromDocumentSnapshot(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return EnchufeModel(
      id: doc.id,
      nombre: data['nombre'] ?? 'Sin nombre',
      usuario: data['usuario'] ?? '',
      estado: data['estado'] ?? false,
      dispositivo: data['categoria']['dispositivo'] ?? 'Sin dispositivo',
      tipo: data['categoria']['tipo'] ?? 'Sin tipo',
      tiempo: (data['tiempo'] as Map<Object?, Object?>? ?? {}).map((key, value) {
        // Conversión segura de Object? a Map<String, dynamic>
        final valueMap = Map<String, dynamic>.from(value as Map<Object?, Object?>);
        return MapEntry(key.toString(), RegistroTiempo.fromJson(valueMap));
      }),
      horario: Horario.fromJson(Map<String, dynamic>.from(data['horario'] ?? {})),
    );
  }
}

class RegistroTiempo {
  //-------------------- Variables --------------------
  final String fecha;
  final int tiempo;

  //-------------------- Constructor --------------------
  RegistroTiempo({
    required this.fecha,
    required this.tiempo,
  });

  //-------------------- Map --------------------
  Map<String, dynamic> toJson() {
    return {
      'fecha': fecha,
      'tiempo': tiempo,
    };
  }

  //-------------------- Factory --------------------
  factory RegistroTiempo.fromJson(Map<String, dynamic> json) {
    return RegistroTiempo(
      fecha: json['fecha'] ?? 'Sin fecha',
      tiempo: json['tiempo'] ?? 0,
    );
  }
}

class Horario {
  //-------------------- Variables --------------------
  final String encender;
  final String apagar;

  //-------------------- Constructor --------------------
  Horario({
    required this.encender,
    required this.apagar,
  });

  //-------------------- Map --------------------
  Map<String, dynamic> toJson() {
    return {
      'encender': encender,
      'apagar': apagar,
    };
  }

  //-------------------- Factory --------------------
  factory Horario.fromJson(Map<String, dynamic> json) {
    return Horario(
      encender: json['encender'] ?? '--:--',
      apagar: json['apagar'] ?? '--:--',
    );
  }
}
