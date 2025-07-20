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

    // Get data from global containers reference
    final containerRef = FirebaseDatabase.instance.ref('containers/${widget.containerId}');
    final snapshot = await containerRef.get();

    if (snapshot.exists && snapshot.value != null) {
      final data = Map<String, dynamic>.from(snapshot.value as Map);
      
      // Verify the current user owns this container
      if (data['ownerId'] != user.uid) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("You don't have access to this container")),
          );
          Navigator.pop(context);
        }
        return;
      }

      final history = Map<String, dynamic>.from(data['usage_history'] ?? {});

      setState(() {
        currentWeight = "${data['current_weight'] ?? 'N/A'}g ";
        fullWeight = "${data['full_weight'] ?? 'N/A'} g";
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

    // Update both global container and user's reference
    final containerRef = FirebaseDatabase.instance.ref('containers/${widget.containerId}');
    await containerRef.update({
      'current_weight': 0,
      'fill_day': 'N/A',
    });

    setState(() {
      currentWeight = "0 g";
      fillDay = "N/A";
    });
  }

  
  @override
Widget build(BuildContext context) {
  return Scaffold(
    backgroundColor: const Color(0xFF0D1B2A), // Dark blue background
    body: SafeArea(
      child: Scrollbar(
        controller: _scrollController,
        thumbVisibility: true,
        thickness: 6,
        radius: const Radius.circular(10),
        interactive: true,
        child: SingleChildScrollView(
          controller: _scrollController,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with back button
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    "Container Details",
                    style: TextStyle(
                      fontSize: 24,
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Container Info Cards
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B), // Darker card background
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    _infoTile("Container ID", widget.containerId),
                    const Divider(color: Colors.white24, height: 20),
                    _infoTile("Container Name", widget.containerName),
                    const Divider(color: Colors.white24, height: 20),
                    _infoTile("Fill Day", fillDay),
                    const Divider(color: Colors.white24, height: 20),
                    _infoTile("Current Weight", currentWeight),
                    const Divider(color: Colors.white24, height: 20),
                    _infoTile("Full Weight", fullWeight),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Reset Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _clearWeightData,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00ACC1), // Teal accent
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 3,
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.refresh),
                      SizedBox(width: 8),
                      Text(
                        "Reset Container",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 30),

              // Usage Chart Section
              const Text(
                "Usage History",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              _buildLineChart(),
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
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: 16,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
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
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        "No usage history found.",
        style: TextStyle(color: Colors.white.withOpacity(0.7)),
      ),
    );
  }

  final sortedDates = usageData.keys.toList()..sort();
  final spots = List.generate(
    sortedDates.length,
    (index) => FlSpot(index.toDouble(), usageData[sortedDates[index]]!),
  );

  return Container(
    height: 250,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: const Color(0xFF1E293B),
      borderRadius: BorderRadius.circular(12),
    ),
    child: LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: true,
          horizontalInterval: 5,
          verticalInterval: 1,
          getDrawingHorizontalLine: (value) => FlLine(
            color: Colors.white.withOpacity(0.1),
            strokeWidth: 1,
          ),
          getDrawingVerticalLine: (value) => FlLine(
            color: Colors.white.withOpacity(0.1),
            strokeWidth: 1,
          ),
        ),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              getTitlesWidget: (value, _) {
                int idx = value.toInt();
                if (idx < 0 || idx >= sortedDates.length) return const SizedBox();
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    sortedDates[idx].substring(5), // MM-DD
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 10,
                    ),
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, _) => Text(
                '${value.toInt()}g',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 10,
                ),
              ),
            ),
          ),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(
            color: Colors.white.withOpacity(0.2),
            width: 1,
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: const Color(0xFF00ACC1), // Teal accent
            barWidth: 3,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                radius: 4,
                color: const Color(0xFF00ACC1),
                strokeWidth: 2,
                strokeColor: Colors.white,
              ),
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF00ACC1).withOpacity(0.3),
                  const Color(0xFF00ACC1).withOpacity(0.1),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
        minX: 0,
        maxX: spots.length > 0 ? spots.last.x : 0,
        minY: 0,
        maxY: spots.length > 0 
          ? spots.map((s) => s.y).reduce((a, b) => a > b ? a : b) * 1.1 
          : 0,
      ),
    ),
  );
}
}