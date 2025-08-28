import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class DraggableReportsTab extends StatefulWidget {
  final List<Map<String, dynamic>> tasks;
  const DraggableReportsTab({super.key, required this.tasks});

  @override
  State<DraggableReportsTab> createState() => _DraggableReportsTabState();
}

class _DraggableReportsTabState extends State<DraggableReportsTab> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Başlık
            const Text(
              'Task Reports',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 2),
            
            // Pie chart'ları tek satırda 4 sütun halinde
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 4, // 2'den 4'e çıkarıldı
              childAspectRatio: 0.8, // 1.0'dan 0.8'e düşürüldü (daha uzun)
              crossAxisSpacing: 12, // 16'dan 12'ye düşürüldü
              mainAxisSpacing: 16,
              children: [
                _buildChart('Category', 'category'),
                _buildChart('Status', 'status'),
                _buildChart('Priority', 'priority'),
                _buildChart('Completion', 'completion'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChart(String title, String dataType) {
    return Container(
      padding: const EdgeInsets.all(6), // 8'den 6'ya düşürüldü
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8), // 12'den 8'e düşürüldü
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 14, // 16'dan 14'e düşürüldü
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6), // 8'den 6'ya düşürüldü
          Expanded(
            child: widget.tasks.isEmpty
                ? const Center(
                    child: Text(
                      'No data',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  )
                : PieChart(
                    PieChartData(
                      sections: _getPieChartSections(dataType),
                      centerSpaceRadius: 20, // 30'dan 20'ye düşürüldü
                      sectionsSpace: 1, // 2'den 1'e düşürüldü
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  List<PieChartSectionData> _getPieChartSections(String dataType) {
    Map<String, int> dataCount = {};

    // Veri türüne göre sayım yap
    for (var task in widget.tasks) {
      String value = '';
      
      switch (dataType) {
        case 'category':
          value = task['category'] ?? 'No Category';
          break;
        case 'status':
          value = task['status'] ?? 'Not Started';
          break;
        case 'priority':
          value = task['priority'] ?? 'Medium';
          break;
        case 'completion':
          int completion = task['completionPercentage'] ?? 0;
          if (completion == 0) value = '0%';
          else if (completion <= 25) value = '1-25%';
          else if (completion <= 50) value = '26-50%';
          else if (completion <= 75) value = '51-75%';
          else if (completion < 100) value = '76-99%';
          else value = '100%';
          break;
        case 'effort':
          int effort = task['effort'] ?? 0;
          if (effort == 0) value = '0 hours';
          else if (effort <= 2) value = '1-2 hours';
          else if (effort <= 5) value = '3-5 hours';
          else if (effort <= 10) value = '6-10 hours';
          else value = '10+ hours';
          break;
        case 'deadline':
          DateTime deadline = DateTime.parse(task['deadline']);
          value = '${deadline.year}-${deadline.month.toString().padLeft(2, '0')}';
          break;
      }
      
      dataCount[value] = (dataCount[value] ?? 0) + 1;
    }

    // Eğer veri yoksa boş liste döndür
    if (dataCount.isEmpty) {
      return [];
    }

    // Renk haritaları
    Map<String, Color> getColors(String dataType) {
      switch (dataType) {
        case 'status':
          return {
            'Not Started': Colors.grey,
            'In Progress': Colors.blue,
            'Complete': Colors.green,
          };
        case 'priority':
          return {
            'High': Colors.red,
            'Medium': Colors.orange,
            'Low': Colors.green,
          };
        case 'completion':
          return {
            '0%': Colors.grey,
            '1-25%': Colors.red,
            '26-50%': Colors.orange,
            '51-75%': Colors.blue,
            '76-99%': Colors.lightBlue,
            '100%': Colors.green,
          };
        default:
          return {};
      }
    }

    final colorMap = getColors(dataType);
    const defaultColors = [
      Colors.blue, Colors.red, Colors.green, Colors.orange,
      Colors.purple, Colors.teal, Colors.amber, Colors.indigo,
    ];

    int colorIndex = 0;
    return dataCount.entries.map((entry) {
      Color color;
      if (colorMap.containsKey(entry.key)) {
        color = colorMap[entry.key]!;
      } else {
        color = defaultColors[colorIndex % defaultColors.length];
        colorIndex++;
      }

      return PieChartSectionData(
        color: color,
        value: entry.value.toDouble(),
        title: '${entry.key}\n${entry.value}',
        radius: 120, // 120'den 60'a düşürüldü
        titleStyle: const TextStyle(
          fontSize:15, // 10'dan 9'a düşürüldü
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();
  }
}