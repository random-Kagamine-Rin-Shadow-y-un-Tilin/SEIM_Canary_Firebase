import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class HistorialScreen extends StatefulWidget {
  @override
  _HistorialScreenState createState() => _HistorialScreenState();
}

class _HistorialScreenState extends State<HistorialScreen> {
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();
  Map<String, List<Map<String, dynamic>>> historial = {}; // Agrupado por tipo de enchufe

  @override
  void initState() {
    super.initState();
    obtenerHistorialDesdeFirebase();
  }

  void obtenerHistorialDesdeFirebase() {
    _dbRef.onValue.listen((event) {
      try {
        final data = event.snapshot.value;
        print("Datos recibidos de Firebase: $data");  

        if (data is Map) {
          setState(() {
            historial.clear();
            data.forEach((tipoEnchufe, enchufeData) {
              if (enchufeData is Map && enchufeData.containsKey("tiempo")) {
                String nombreDispositivo = enchufeData["nombre"] ?? "Sin nombre";
                
                Map<String, dynamic> tiempoData = Map<String, dynamic>.from(enchufeData["tiempo"]);

                tiempoData.forEach((fecha, info) {
                  if (info is Map && info.containsKey("tiempo")) {
                    historial.putIfAbsent(tipoEnchufe, () => []).add({
                      "nombre": nombreDispositivo,
                      "fecha": fecha,
                      "tiempo": info["tiempo"] ?? 0,
                    });
                  }
                });
              }
            });
          });
        } else {
          print("Datos en un formato inesperado");
        }
      } catch (e) {
        print("Error al obtener datos de Firebase: $e");
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Historial por Tipo de Enchufe")),
      body: historial.isEmpty
          ? Center(child: CircularProgressIndicator())
          : ListView(
              children: historial.entries.map((entry) {
                return Card(
                  margin: EdgeInsets.all(10),
                  child: ExpansionTile(
                    title: Text(entry.key,  // Tipo de enchufe (enchufe, enchufe2, etc.)
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    children: entry.value.map((evento) {
                      return ListTile(
                        title: Text("${evento['nombre']} - ${evento['fecha']}"),
                        subtitle: Text("Tiempo encendido: ${evento['tiempo']} minutos"),
                      );
                    }).toList(),
                  ),
                );
              }).toList(),
            ),
    );
  }
}
