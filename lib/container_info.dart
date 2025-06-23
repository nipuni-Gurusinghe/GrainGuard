import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:fl_chart/fl_chart.dart';
import 'navbar.dart';

class ContainerInfoPage extends StatefulWidget {
  final String containerId;
  final String containerName;

  const ContainerInfoPage({
    super.key,
    required this.containerId,
    required this.containerName,
  });

  @override
  State<ContainerInfoPage> createState() => _ContainerInfoPageState();
}

class _ContainerInfoPageState extends State<ContainerInfoPage> {
  String currentWeight = "Loading...";
  String fullWeight = "Loading...";
  String fillDay = "Loading...";
  final ScrollController _scrollController = ScrollController();
  Map<String, double> usageData = {};

  @override
  void initState() {
    super.initState();
    _loadContainerData();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadContainerData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final ref = FirebaseDatabase.instance
        .ref('${user.uid}/containers/${widget.containerId}');
    final snapshot = await ref.get();

    if (snapshot.exists && snapshot.value != null) {
      final data = Map<String, dynamic>.from(snapshot.value as Map);
      final history = Map<String, dynamic>.from(data['usage_history'] ?? {});

      setState(() {
        currentWeight = "${data['current_weight'] ?? 'N/A'} kg";
        fullWeight = "${data['full_weight'] ?? 'N/A'} kg";
        fillDay = data['fill_day'] ?? 'N/A';
        usageData = {
          for (var entry in history.entries)
            entry.key: double.tryParse(entry.value.toString()) ?? 0.0
        };
      });
    } else {
      setState(() {
        currentWeight = "N/A";
        fullWeight = "N/A";
        fillDay = "N/A";
        usageData = {};
      });
    }
  }

  Future<void> _clearWeightData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final ref = FirebaseDatabase.instance
        .ref('${user.uid}/containers/${widget.containerId}');
    await ref.update({
      'current_weight': 0,
      'fill_day': 'N/A',
    });

    setState(() {
      currentWeight = "0 kg";
      fillDay = "N/A";
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2D7CAD),
      body: SafeArea(
        child: Scrollbar(
          controller: _scrollController,
          thumbVisibility: true,
          thickness: 6,
          radius: const Radius.circular(10),
          interactive: true,
          child: SingleChildScrollView(
            controller: _scrollController,
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Container Details",
                  style: TextStyle(
                    fontSize: 22,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                _infoTile("Container ID", widget.containerId),
                _infoTile("Container Name", widget.containerName),
                _infoTile("Fill Day", fillDay),
                _infoTile("Current Weight", currentWeight),
                _infoTile("Full Weight", fullWeight),
                const SizedBox(height: 20),
                Center(
                  child: ElevatedButton.icon(
                    onPressed: _clearWeightData,
                    icon: const Icon(Icons.refresh),
                    label: const Text("Reset Container"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.red,
                      padding:
                          const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                const Text(
                  "Usage Chart ",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                _buildLineChart(),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: const Navbar(currentIndex: 1),
    );
  }

  Widget _infoTile(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(color: Colors.white70, fontSize: 14)),
          const SizedBox(height: 5),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.9),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(value, style: const TextStyle(fontSize: 16)),
          ),
        ],
      ),
    );
  }

  Widget _buildLineChart() {
    if (usageData.isEmpty) {
      return Container(
        height: 200,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Text(
          "No usage history found.",
          style: TextStyle(color: Colors.black54),
        ),
      );
    }

    final sortedDates = usageData.keys.toList()..sort();
    final spots = List.generate(
      sortedDates.length,
      (index) => FlSpot(index.toDouble(), usageData[sortedDates[index]]!),
    );

    return Container(
      height: 200,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: LineChart(
        LineChartData(
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                getTitlesWidget: (value, _) {
                  int idx = value.toInt();
                  if (idx < 0 || idx >= sortedDates.length) return const SizedBox();
                  return Text(sortedDates[idx].substring(5), // MM-DD
                      style: const TextStyle(fontSize: 10));
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, _) => Text(
                  '${value.toInt()}kg',
                  style: const TextStyle(fontSize: 10),
                ),
              ),
            ),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: Colors.blueAccent,
              barWidth: 3,
              dotData: FlDotData(show: true),
              belowBarData: BarAreaData(
                show: true,
                color: Colors.blue.withOpacity(0.3),
              ),
            ),
          ],
          gridData: FlGridData(show: true),
          borderData: FlBorderData(show: true),
        ),
      ),
    );
  }
}
