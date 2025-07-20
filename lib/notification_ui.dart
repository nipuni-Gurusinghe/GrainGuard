import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:fl_chart/fl_chart.dart';
import 'navbar.dart';

class NotificationUI extends StatefulWidget {
  const NotificationUI({super.key});

  @override
  State<NotificationUI> createState() => _NotificationUIState();
}

class _NotificationUIState extends State<NotificationUI> {
  final List<Map<String, dynamic>> containerData = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchContainerData();
  }

  Future<void> _fetchContainerData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => isLoading = true);

    try {
      // Get user's container references
      final userContainersRef = FirebaseDatabase.instance.ref('users/${user.uid}/myContainers');
      final userContainersSnapshot = await userContainersRef.get();

      if (!userContainersSnapshot.exists) {
        setState(() {
          containerData.clear();
          isLoading = false;
        });
        return;
      }

      final userContainerIds = (userContainersSnapshot.value as Map).keys.cast<String>();
      final List<Map<String, dynamic>> containers = [];

      // Fetch container details
      for (final containerId in userContainerIds) {
        final containerRef = FirebaseDatabase.instance.ref('containers/$containerId');
        final containerSnapshot = await containerRef.get();

        if (containerSnapshot.exists) {
          final container = Map<String, dynamic>.from(containerSnapshot.value as Map);
          final name = container['name'] ?? 'Unnamed';
          final fullWeight = double.tryParse(container['full_weight'].toString()) ?? 0.0;
          final currentWeight = double.tryParse(container['current_weight'].toString()) ?? 0.0;
          final remainingWeight = fullWeight - currentWeight;

          containers.add({
            'id': containerId,
            'name': name,
            'fullWeight': fullWeight.toStringAsFixed(2),
            'currentWeight': currentWeight.toStringAsFixed(2),
            'remainingWeight': remainingWeight.toStringAsFixed(2),
          });
        }
      }

      setState(() {
        containerData.clear();
        containerData.addAll(containers);
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading data: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1B2A),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Container Status",
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              if (isLoading)
                const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                )
              else if (containerData.isEmpty)
                const Text(
                  "No container data available.",
                  style: TextStyle(color: Colors.white70),
                )
              else
                Column(
                  children: containerData.map((container) {
                    return Container(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E293B),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 6,
                            offset: const Offset(4, 4),
                          ),
                        ],
                      ),
                      child: ListTile(
                        leading: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: _getContainerColor(double.parse(container['remainingWeight']), 
                                                    double.parse(container['fullWeight'])),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.inventory,
                            color: Colors.white.withOpacity(0.9),
                            size: 20,
                          ),
                        ),
                        title: Text(
                          container['name'],
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        subtitle: Text(
                          'Remaining: ${container['remainingWeight']} kg / ${container['fullWeight']} kg',
                          style: const TextStyle(color: Colors.white70),
                        ),
                        trailing: Text(
                          '${((double.parse(container['remainingWeight']) / double.parse(container['fullWeight'])) * 100).toStringAsFixed(1)}%',
                          style: TextStyle(
                            color: _getContainerColor(double.parse(container['remainingWeight']), 
                                                    double.parse(container['fullWeight'])),
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),

              const SizedBox(height: 30),

              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 6,
                      offset: const Offset(4, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Remaining Weight",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (containerData.isEmpty)
                      const Text("No data available.", style: TextStyle(color: Colors.white70))
                    else
                      SizedBox(
                        height: 250,
                        child: BarChart(
                          BarChartData(
                            alignment: BarChartAlignment.spaceAround,
                            maxY: containerData
                                    .map((e) => double.parse(e['fullWeight']))
                                    .reduce((a, b) => a > b ? a : b) +
                                5,
                            barTouchData: BarTouchData(enabled: true),
                            titlesData: FlTitlesData(
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  getTitlesWidget: (double value, TitleMeta meta) {
                                    final index = value.toInt();
                                    if (index < 0 || index >= containerData.length) {
                                      return const SizedBox();
                                    }
                                    return Padding(
                                      padding: const EdgeInsets.only(top: 8),
                                      child: Text(
                                        containerData[index]['name'],
                                        style: const TextStyle(
                                          fontSize: 10,
                                          color: Colors.white70,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                              leftTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  getTitlesWidget: (value, meta) => Text(
                                    value.toInt().toString(),
                                    style: const TextStyle(color: Colors.white70, fontSize: 10),
                                  ),
                                ),
                              ),
                              topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            ),
                            borderData: FlBorderData(show: false),
                            barGroups: containerData.asMap().entries.map((entry) {
                              final index = entry.key;
                              final data = entry.value;
                              final remainingWeight = double.parse(data['remainingWeight']);
                              final fullWeight = double.parse(data['fullWeight']);
                              
                              return BarChartGroupData(
                                x: index,
                                barRods: [
                                  BarChartRodData(
                                    toY: remainingWeight,
                                    color: _getContainerColor(remainingWeight, fullWeight),
                                    width: 18,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                ],
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const Navbar(currentIndex: 0),
    );
  }

  Color _getContainerColor(double remainingWeight, double fullWeight) {
    final percentage = remainingWeight / fullWeight;
    if (percentage < 0.2) return Colors.redAccent;
    if (percentage < 0.5) return Colors.orangeAccent;
    return Colors.greenAccent;
  }
}