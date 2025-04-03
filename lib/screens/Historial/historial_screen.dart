import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:fl_chart/fl_chart.dart';

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
      if (!mounted) return; // Evita actualizar si el widget ya no está en pantalla
      try {
        final data = event.snapshot.value;
        if (data is Map) {
          Map<String, List<Map<String, dynamic>>> tempHistorial = {};
          data.forEach((claveEnchufe, enchufeData) {
            if (enchufeData is Map) {
              // Accede correctamente a los valores de dispositivo y tipo dentro de categoria
              String tipoEnchufe = enchufeData["categoria"]?["tipo"] ?? "Desconocido";
              String dispositivo = enchufeData["categoria"]?["dispositivo"] ?? "Sin nombre";

              Map<String, dynamic>? tiempoData;
              if (enchufeData["tiempo"] is Map) {
                tiempoData = Map<String, dynamic>.from(enchufeData["tiempo"]);
              } else if (enchufeData["horario"] is Map &&
                  enchufeData["horario"]?["tiempo"] is Map) {
                tiempoData = Map<String, dynamic>.from(enchufeData["horario"]["tiempo"]);
              }

              if (tiempoData != null) {
                tiempoData.forEach((fecha, info) {
                  if (info is Map && info.containsKey("tiempo")) {
                    double tiempoEnMinutos = (info["tiempo"] is num)
                        ? (info["tiempo"] as num).toDouble()
                        : double.tryParse(info["tiempo"].toString()) ?? 0;

                    tempHistorial.putIfAbsent(tipoEnchufe, () => []).add({
                      "dispositivo": dispositivo,
                      "fecha": fecha,
                      "tiempo": tiempoEnMinutos,
                    });
                  }
                });
              }
            }
          });

          setState(() {
            historial = tempHistorial;
          });
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
          : SingleChildScrollView(
              child: Column(
                children: historial.entries.map((entry) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    child: Card(
                      elevation: 5,
                      child: ExpansionTile(
                        title: Text(
                          "${entry.value.first["dispositivo"]} - ${entry.key}", // Nombre del dispositivo y tipo de enchufe
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        children: [
                          Container(
                            height: 250, // Altura de la gráfica
                            padding: EdgeInsets.all(10),
                            child: BarChartWidget(entry.value),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
    );
  }
}

class BarChartWidget extends StatelessWidget {
  final List<Map<String, dynamic>> datos;

  BarChartWidget(this.datos);

  @override
  Widget build(BuildContext context) {
    List<BarChartGroupData> barras = [];
    List<String> fechas = [];
    double maxTiempo = 0;

    for (int i = 0; i < datos.length; i++) {
      fechas.add(datos[i]["fecha"]);
      double tiempo = datos[i]["tiempo"];
      maxTiempo = tiempo > maxTiempo ? tiempo : maxTiempo; // Determinar el máximo

      barras.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: tiempo,
              color: Colors.blue,
              width: 15,
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.all(8.0),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: maxTiempo + 10, // Ajusta automáticamente la altura del gráfico
          titlesData: FlTitlesData(
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 50, // Más espacio para que los números no se corten
                getTitlesWidget: (value, meta) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: Text(
                      "${value.toInt()} min",
                      textAlign: TextAlign.right,
                      style: TextStyle(fontSize: 12),
                    ),
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  int index = value.toInt();
                  if (index >= 0 && index < fechas.length) {
                    return Text(
                      fechas[index],
                      style: TextStyle(fontSize: 10),
                    );
                  }
                  return SizedBox.shrink(); // Evita errores en los índices fuera de rango
                },
              ),
            ),
          ),
          barTouchData: BarTouchData(enabled: true), // Permite interacción con las barras
          gridData: FlGridData(
            show: true,
            checkToShowHorizontalLine: (value) => value % 10 == 0,
            getDrawingHorizontalLine: (value) => FlLine(
              color: Colors.grey.withOpacity(0.3),
              strokeWidth: 1,
            ),
          ),
          barGroups: barras,
        ),
      ),
    );
  }
}
