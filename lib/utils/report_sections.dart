import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

// Kategori Pie Chart
List<PieChartSectionData> buildCategorySections(List<Map<String, dynamic>> tasks) {
  final Map<String, int> categoryCount = {};
  for (final task in tasks) {
    final category = (task['category'] ?? 'Uncategorized').toString();
    categoryCount[category] = (categoryCount[category] ?? 0) + 1;
  }

  const palette = [
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
    final color = palette[i % palette.length];
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

// Status Pie Chart
List<PieChartSectionData> buildStatusSections(List<Map<String, dynamic>> tasks) {
  final Map<String, int> statusCount = {};
  for (final task in tasks) {
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