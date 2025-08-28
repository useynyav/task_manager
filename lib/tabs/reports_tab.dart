import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class ReportsTab extends StatelessWidget {
  final List<Map<String, dynamic>> tasks;
  const ReportsTab({super.key, required this.tasks});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          const Text(
            "Breakdown by Category",
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 300,
            child: tasks.isEmpty
                ? const Center(
                    child: Text(
                      "No tasks available for category report",
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  )
                : PieChart(
                    PieChartData(
                      sections: _buildCategorySections(),
                      centerSpaceRadius: 40,
                      sectionsSpace: 2,
                    ),
                  ),
          ),
          const SizedBox(height: 40),
          const Text(
            "Breakdown by Status",
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 300,
            child: tasks.isEmpty
                ? const Center(
                    child: Text(
                      "No tasks available for status report",
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  )
                : PieChart(
                    PieChartData(
                      sections: _buildStatusSections(),
                      centerSpaceRadius: 40,
                      sectionsSpace: 2,
                    ),
                  ),
          ),
          const SizedBox(height: 40),
          const Text(
            "Summary Statistics",
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
            const SizedBox(height: 16),
          Card(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  _statRow(
                    "Total Tasks:",
                    tasks.length.toString(),
                  ),
                  const Divider(),
                  _statRow(
                    "Completed Tasks:",
                    tasks.where((t) => t['status'] == 'Complete').length.toString(),
                    color: Colors.green,
                  ),
                  const Divider(),
                  _statRow(
                    "In Progress:",
                    tasks.where((t) => t['status'] == 'In Progress').length.toString(),
                    color: Colors.blue,
                  ),
                  const Divider(),
                  _statRow(
                    "Not Started:",
                    tasks.where((t) => t['status'] == 'Not Started').length.toString(),
                    color: Colors.grey,
                  ),
                  const Divider(),
                  _statRow(
                    "Completion Rate:",
                    tasks.isEmpty
                        ? "0%"
                        : "${((tasks.where((t) => t['status'] == 'Complete').length / tasks.length) * 100).toStringAsFixed(1)}%",
                    color: Colors.orange,
                    bold: true,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<PieChartSectionData> _buildCategorySections() {
    final Map<String, int> categoryCount = {};
    for (var task in tasks) {
      final cat = (task['category'] ?? 'Uncategorized').toString();
      categoryCount[cat] = (categoryCount[cat] ?? 0) + 1;
    }
    final colors = <Color>[
      Colors.blue,
      Colors.red,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.amber,
      Colors.indigo,
    ];
    int i = 0;
    return categoryCount.entries.map((e) {
      final color = colors[i % colors.length];
      i++;
      return PieChartSectionData(
        color: color,
        value: e.value.toDouble(),
        title: '${e.key}\n${e.value}',
        radius: 100,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();
  }

  List<PieChartSectionData> _buildStatusSections() {
    final Map<String, int> statusCount = {};
    for (var task in tasks) {
      final status = (task['status'] ?? 'Not Started').toString();
      statusCount[status] = (statusCount[status] ?? 0) + 1;
    }
    const statusColors = {
      'Not Started': Colors.grey,
      'In Progress': Colors.blue,
      'Complete': Colors.green,
    };
    return statusCount.entries.map((e) {
      final color = statusColors[e.key] ?? Colors.orange;
      return PieChartSectionData(
        color: color,
        value: e.value.toDouble(),
        title: '${e.key}\n${e.value}',
        radius: 100,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();
  }

  Widget _statRow(String label, String value, {Color? color, bool bold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            )),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: bold ? FontWeight.bold : FontWeight.normal,
            color: color,
          ),
        ),
      ],
    );
  }
}