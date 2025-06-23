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
  final List<Map<String, dynamic>> reminderMessages = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchContainerReminders();
  }

  Future<void> _fetchContainerReminders() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final ref = FirebaseDatabase.instance.ref('${user.uid}/containers');
    final snapshot = await ref.get();

    final List<Map<String, dynamic>> messages = [];

    if (snapshot.exists && snapshot.value != null) {
      final data = Map<String, dynamic>.from(snapshot.value as Map);

      data.forEach((key, value) {
        final container = Map<String, dynamic>.from(value);
        final name = container['name'] ?? 'Unnamed';
        final fullWeight = double.tryParse(container['full_weight'].toString()) ?? 0.0;
        final currentWeight = double.tryParse(container['current_weight'].toString()) ?? 0.0;
        final usedWeight = fullWeight - currentWeight;

        messages.add({
          'name': name,
          'remindWeight': usedWeight.toStringAsFixed(2),
        });
      });
    }

    setState(() {
      reminderMessages.clear();
      reminderMessages.addAll(messages);
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: const Color.fromARGB(255, 45, 124, 173),
        child: SafeArea(
          child: Scrollbar(
            thickness: 5,
            radius: const Radius.circular(10),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Header
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "Notifications",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Notification Cards
                  if (isLoading)
                    const Center(child: CircularProgressIndicator())
                  else if (reminderMessages.isEmpty)
                    const Text(
                      "No container data available.",
                      style: TextStyle(color: Colors.white),
                    )
                  else
                    Column(
                      children: reminderMessages.map((item) {
                        return Card(
                          elevation: 4,
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ListTile(
                            leading: const Icon(Icons.notifications_active, color: Colors.red),
                            title: Text(
                              'Container ${item['name']}',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text(
                              'Used weight: ${item['remindWeight']} kg',
                              style: const TextStyle(color: Colors.black87),
                            ),
                          ),
                        );
                      }).toList(),
                    ),

                  const SizedBox(height: 30),

                  // Usage History Chart
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Usage history",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 10),
                        if (reminderMessages.isEmpty)
                          const Text("No data available.")
                        else
                          SizedBox(
                            height: 250,
                            child: BarChart(
                              BarChartData(
                                alignment: BarChartAlignment.spaceAround,
                                maxY: reminderMessages
                                        .map((e) => double.parse(e['remindWeight']))
                                        .reduce((a, b) => a > b ? a : b) +
                                    5,
                                barTouchData: BarTouchData(enabled: true),
                                titlesData: FlTitlesData(
                                  bottomTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      getTitlesWidget: (double value, TitleMeta meta) {
                                        final index = value.toInt();
                                        if (index < 0 || index >= reminderMessages.length) {
                                          return const SizedBox();
                                        }
                                        return Padding(
                                          padding: const EdgeInsets.only(top: 8),
                                          child: Text(
                                            reminderMessages[index]['name'],
                                            style: const TextStyle(fontSize: 10),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                  leftTitles: AxisTitles(
                                    sideTitles: SideTitles(showTitles: true),
                                  ),
                                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                ),
                                borderData: FlBorderData(show: false),
                                barGroups: reminderMessages.asMap().entries.map((entry) {
                                  final index = entry.key;
                                  final data = entry.value;
                                  final usedWeight = double.tryParse(data['remindWeight']) ?? 0.0;
                                  return BarChartGroupData(
                                    x: index,
                                    barRods: [
                                      BarChartRodData(
                                        toY: usedWeight,
                                        color: Colors.blueAccent,
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
        ),
      ),
      bottomNavigationBar: const Navbar(currentIndex: 0),
    );
  }
}
