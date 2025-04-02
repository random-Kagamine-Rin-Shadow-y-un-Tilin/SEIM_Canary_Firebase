import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class HistorialScreen extends StatefulWidget {
  @override
  _HistorialScreenState createState() => _HistorialScreenState();
}

class _HistorialScreenState extends State<HistorialScreen> {
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref("historial");
  Map<String, List<Map<String, dynamic>>> historial = {};

  @override
  void initState() {
    super.initState();
    obtenerHistorialDesdeFirebase();
  }

  void obtenerHistorialDesdeFirebase() {
    _dbRef.onValue.listen((event) {
      final data = event.snapshot.value as Map?;
      if (data != null) {
        setState(() {
          // Aseguramos que los datos sean del tipo adecuado
          historial = data.map((fecha, eventos) {
            // Convertimos cada lista de eventos en una lista de Map<String, dynamic>
            List<Map<String, dynamic>> listaEventos = [];
            if (eventos is List) {
              listaEventos = eventos.map((e) => Map<String, dynamic>.from(e)).toList();
            }
            return MapEntry(fecha, listaEventos);
          });
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Historial de Encendido")),
      body: historial.isEmpty
          ? Center(child: CircularProgressIndicator())
          : ListView(
              children: historial.entries.map((entry) {
                return Card(
                  margin: EdgeInsets.all(10),
                  child: ExpansionTile(
                    title: Text(entry.key, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    children: entry.value.map((evento) {
                      return ListTile(
                        leading: Icon(evento["estado"] ? Icons.power : Icons.power_off,
                            color: evento["estado"] ? Colors.green : Colors.red),
                        title: Text("Hora: ${evento['hora']}"),
                        subtitle: Text(evento["estado"] ? "Encendido" : "Apagado"),
                      );
                    }).toList(),
                  ),
                );
              }).toList(),
            ),
    );
  }
}
