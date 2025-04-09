import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:seim_canary/services/current_user.dart';

class HistorialScreen extends StatefulWidget {
  const HistorialScreen({super.key});

  @override
  _HistorialScreenState createState() => _HistorialScreenState();
}

class _HistorialScreenState extends State<HistorialScreen> {
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref().child('enchufes');
  Map<String, List<Map<String, dynamic>>> historial = {};

  @override
  void initState() {
    super.initState();
    obtenerHistorialDesdeFirebase();
  }

  void obtenerHistorialDesdeFirebase() {
    final currentUser = CurrentUser().user;

    if (currentUser == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se encontró un usuario autenticado')),
        );
      }
      return;
    }

    _dbRef.orderByChild('usuario').equalTo(currentUser.id).onValue.listen((event) {
      if (!mounted) return;

      try {
        final data = event.snapshot.value;
        if (data == null) {
          setState(() => historial = {});
          return;
        }

        // Process data as either List or Map
        Map<String, dynamic> enchufesData;
        if (data is List) {
          enchufesData = {
            for (int i = 0; i < data.length; i++)
              if (data[i] != null) i.toString(): data[i]
          };
        } else if (data is Map) {
          enchufesData = Map<String, dynamic>.from(data);
        } else {
          throw Exception('Formato de datos no compatible');
        }

        // Process history data
        Map<String, List<Map<String, dynamic>>> tempHistorial = {};

        enchufesData.forEach((deviceId, enchufeData) {
          if (enchufeData is Map) {
            // Verify this device belongs to the current user
            if (enchufeData['usuario'] != currentUser.id) return;

            final nombre = enchufeData['nombre'] ?? 'Sin nombre';
            final rawTiempo = enchufeData['tiempo'];

            // Convert time data to a uniform Map
            Map<String, dynamic> tiempoData = {};
            if (rawTiempo is Map) {
              tiempoData = Map<String, dynamic>.from(rawTiempo);
            } else if (rawTiempo is List) {
              for (int i = 0; i < rawTiempo.length; i++) {
                final item = rawTiempo[i];
                if (item != null) {
                  tiempoData[i.toString()] = item;
                }
              }
            }

            tiempoData.forEach((fecha, tiempo) {
              if (tiempo is Map && tiempo.containsKey('tiempo')) {
                final tiempoEnMinutos = tiempo['tiempo'] is num
                    ? (tiempo['tiempo'] as num).toDouble()
                    : double.tryParse('${tiempo['tiempo']}') ?? 0.0;

                tempHistorial.putIfAbsent(nombre, () => []).add({
                  'fecha': fecha.toString(),
                  'tiempo': tiempoEnMinutos,
                  'deviceId': deviceId,
                });
              }
            });
          }
        });

        if (mounted) {
          setState(() => historial = tempHistorial);
        }
      } catch (e) {
        print('Error al procesar datos: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al cargar datos: $e')),
          );
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Historial de Enchufes")),
      body: historial.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    "No hay datos de historial disponibles.",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            )
          : SingleChildScrollView(
              child: Column(
                children: historial.entries.map((entry) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    child: Card(
                      elevation: 5,
                      child: ExpansionTile(
                        title: Text(
                          entry.key,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        children: [
                          Container(
                            height: 250,
                            padding: const EdgeInsets.all(10),
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

  const BarChartWidget(this.datos, {super.key});

  @override
  Widget build(BuildContext context) {
    // Sort data by date
    datos.sort((a, b) => (a['fecha'] ?? '').compareTo(b['fecha'] ?? ''));

    List<BarChartGroupData> barras = [];
    List<String> fechas = [];
    double maxTiempo = 0;

    for (int i = 0; i < datos.length; i++) {
      final fecha = datos[i]['fecha'] ?? 'Sin Fecha';
      final tiempo = datos[i]['tiempo'] is num
          ? (datos[i]['tiempo'] as num).toDouble()
          : 0.0;

      fechas.add(fecha.toString());
      maxTiempo = tiempo > maxTiempo ? tiempo : maxTiempo;

      barras.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: tiempo,
              width: 15,
              borderRadius: BorderRadius.circular(5),
              gradient: LinearGradient(
                colors: [Colors.blue.shade400, Colors.blue.shade900],
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: maxTiempo + 10,
          titlesData: FlTitlesData(
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 50,
                getTitlesWidget: (value, meta) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: Text(
                      "${value.toInt()} min",
                      textAlign: TextAlign.right,
                      style: const TextStyle(fontSize: 12),
                    ),
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index >= 0 && index < fechas.length) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Text(
                        fechas[index],
                        style: const TextStyle(fontSize: 10),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
          ),
          barTouchData: BarTouchData(
            enabled: true,
            touchTooltipData: BarTouchTooltipData(
              tooltipBgColor: Colors.blueGrey,
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                if (group.x >= 0 && group.x < fechas.length) {
                  return BarTooltipItem(
                    '${fechas[group.x]}: ${rod.toY.toInt()} min',
                    const TextStyle(color: Colors.white),
                  );
                }
                return null;
              },
            ),
          ),
          gridData: FlGridData(
            show: true,
            drawHorizontalLine: true,
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