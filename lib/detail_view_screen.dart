import 'package:flutter/material.dart';
import 'package:flutter_application_1/screens/task_detail_screen.dart';
import 'package:intl/intl.dart';

class DetailViewScreen extends StatefulWidget {
  final List<Map<String, dynamic>> tasks;
  
  const DetailViewScreen({
    super.key,
    required this.tasks,
  });

  @override
  State<DetailViewScreen> createState() => _DetailViewScreenState();
}

class _DetailViewScreenState extends State<DetailViewScreen> {
  Map<String, dynamic>? selectedTask;
  String searchQuery = '';
  String selectedCategory = '';
  String selectedStatus = '';
  String selectedPriority = '';
  
  List<Map<String, dynamic>> get filteredTasks {
    List<Map<String, dynamic>> filtered = widget.tasks;
    
    // Search filter
    if (searchQuery.isNotEmpty) {
      filtered = filtered.where((task) =>
        task['title'].toString().toLowerCase().contains(searchQuery.toLowerCase()) ||
        (task['description'] ?? '').toString().toLowerCase().contains(searchQuery.toLowerCase())
      ).toList();
    }
    
    // Category filter
    if (selectedCategory.isNotEmpty) {
      filtered = filtered.where((task) =>
        task['category'] == selectedCategory
      ).toList();
    }
    
    // Status filter
    if (selectedStatus.isNotEmpty) {
      filtered = filtered.where((task) =>
        task['status'] == selectedStatus
      ).toList();
    }
    
    // Priority filter
    if (selectedPriority.isNotEmpty) {
      filtered = filtered.where((task) =>
        task['priority'] == selectedPriority
      ).toList();
    }
    
    return filtered;
  }
  
  List<String> get categories {
    return widget.tasks.map((task) => task['category'].toString()).toSet().toList();
  }
  
  List<String> get statuses {
    return ['Not Started', 'In Progress', 'Complete'];
  }
  
  List<String> get priorities {
    return ['High', 'Medium', 'Low'];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Task Detail View'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        centerTitle: true,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          // Responsive design - ekran boyutuna göre düzenle
          bool isWideScreen = constraints.maxWidth > 800;
          
          if (isWideScreen) {
            // Geniş ekran - yan yana layout
            return Row(
              children: [
                // Left Panel - Task List (sabit genişlik)
                SizedBox(
                  width: 350,
                  child: _buildTaskListPanel(),
                ),
                // Right Panel - Task Detail (esnek genişlik)
                Expanded(
                  child: selectedTask == null
                      ? _buildEmptyState()
                      : _buildTaskDetail(selectedTask!),
                ),
              ],
            );
          } else {
            // Dar ekran - üst üste layout
            return Column(
              children: [
                // Top Panel - Task List (scroll edilebilir)
                SizedBox(
                  height: constraints.maxHeight * 0.4,
                  child: _buildTaskListPanel(),
                ),
                // Bottom Panel - Task Detail
                Expanded(
                  child: selectedTask == null
                      ? _buildEmptyState()
                      : _buildTaskDetail(selectedTask!),
                ),
              ],
            );
          }
        },
      ),
    );
  }
  
  Widget _buildTaskListPanel() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          right: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      child: Column(
        children: [
          // Search and Filters - Flexible container
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              border: Border(
                bottom: BorderSide(color: Colors.grey.shade200),
              ),
            ),
            child: Column(
              children: [
                // Search Box - tek satır, ellipsis kullan
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Search tasks...',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    isDense: true,
                  ),
                  onChanged: (value) {
                    setState(() {
                      searchQuery = value;
                    });
                  },
                ),
                
                const SizedBox(height: 12),
                
                // Filter Row - Flex kullanarak responsive yap
                IntrinsicHeight(
                  child: Row(
                    children: [
                      // Category Filter
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: selectedCategory.isEmpty ? null : selectedCategory,
                          decoration: InputDecoration(
                            labelText: 'Category',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            isDense: true,
                          ),
                          isExpanded: true, // Overflow önleyici
                          items: [
                            const DropdownMenuItem<String>(
                              value: null,
                              child: Text('All', overflow: TextOverflow.ellipsis),
                            ),
                            ...categories.map((category) =>
                              DropdownMenuItem<String>(
                                value: category,
                                child: Text(
                                  category,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                          ],
                          onChanged: (value) {
                            setState(() {
                              selectedCategory = value ?? '';
                            });
                          },
                        ),
                      ),
                      
                      const SizedBox(width: 8),
                      
                      // Status Filter
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: selectedStatus.isEmpty ? null : selectedStatus,
                          decoration: InputDecoration(
                            labelText: 'Status',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            isDense: true,
                          ),
                          isExpanded: true, // Overflow önleyici
                          items: [
                            const DropdownMenuItem<String>(
                              value: null,
                              child: Text('All', overflow: TextOverflow.ellipsis),
                            ),
                            ...statuses.map((status) =>
                              DropdownMenuItem<String>(
                                value: status,
                                child: Text(
                                  status,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                          ],
                          onChanged: (value) {
                            setState(() {
                              selectedStatus = value ?? '';
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Task List Header - Flexible
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              border: Border(
                bottom: BorderSide(color: Colors.grey.shade200),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.list_alt, size: 18, color: Colors.blue.shade700),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Tasks (${filteredTasks.length})',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.blue.shade700,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (searchQuery.isNotEmpty || selectedCategory.isNotEmpty || selectedStatus.isNotEmpty)
                  IconButton(
                    icon: Icon(Icons.clear, size: 16, color: Colors.red.shade600),
                    onPressed: () {
                      setState(() {
                        searchQuery = '';
                        selectedCategory = '';
                        selectedStatus = '';
                        selectedPriority = '';
                      });
                    },
                    tooltip: 'Clear filters',
                  ),
              ],
            ),
          ),
          
          // Task List - Expanded ve constrained
          Expanded(
            child: filteredTasks.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off,
                          size: 48,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No tasks found',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: filteredTasks.length,
                    itemBuilder: (context, index) {
                      final task = filteredTasks[index];
                      final isSelected = selectedTask == task;
                      final deadline = DateTime.parse(task['deadline']);
                      final completion = task['completionPercentage'] ?? 0;
                      
                      return Container(
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.blue.shade50 : Colors.white,
                          border: Border(
                            bottom: BorderSide(color: Colors.grey.shade100),
                            left: isSelected 
                              ? BorderSide(color: Colors.blue.shade400, width: 3)
                              : BorderSide.none,
                          ),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          title: Text(
                            task['title'],
                            style: TextStyle(
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                              color: isSelected ? Colors.blue.shade800 : Colors.black87,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              // Date ve Status Row - Flexible
                              Row(
                                children: [
                                  Icon(Icons.calendar_today, size: 12, color: Colors.grey.shade600),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    flex: 2,
                                    child: Text(
                                      DateFormat('dd/MM/yyyy').format(deadline),
                                      style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    flex: 3,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: _getStatusColor(task['status']),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        task['status'],
                                        style: const TextStyle(
                                          fontSize: 10,
                                          color: Colors.white,
                                          fontWeight: FontWeight.w500,
                                        ),
                                        textAlign: TextAlign.center,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              // Progress Row - Constrained
                              Row(
                                children: [
                                  Expanded(
                                    child: LinearProgressIndicator(
                                      value: completion / 100,
                                      backgroundColor: Colors.grey.shade300,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        _getCompletionColor(completion),
                                      ),
                                      minHeight: 4,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  SizedBox(
                                    width: 35,
                                    child: Text(
                                      '$completion%',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.grey.shade700,
                                      ),
                                      textAlign: TextAlign.end,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          onTap: () {
                            setState(() {
                              selectedTask = task;
                            });
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.assignment,
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'Select a task to view details',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'Choose any task from the left panel to see detailed information',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade500,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildTaskDetail(Map<String, dynamic> task) {
    final deadline = DateTime.parse(task['deadline']);
    final completion = task['completionPercentage'] ?? 0;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 800), // Max genişlik sınırı
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header - Responsive
            LayoutBuilder(
              builder: (context, constraints) {
                bool isWide = constraints.maxWidth > 600;
                
                if (isWide) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              task['title'],
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 8),
                            if (task['description'] != null && task['description'].toString().isNotEmpty)
                              Text(
                                task['description'],
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey.shade700,
                                  height: 1.4,
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: _getPriorityColor(task['priority']),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          task['priority'] ?? 'Medium',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  );
                } else {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              task['title'],
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: _getPriorityColor(task['priority']),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              task['priority'] ?? 'Medium',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (task['description'] != null && task['description'].toString().isNotEmpty)
                        Text(
                          task['description'],
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade700,
                            height: 1.4,
                          ),
                        ),
                    ],
                  );
                }
              },
            ),
            
            const SizedBox(height: 32),
            
            // Progress Section
            _buildDetailCard(
              'Progress Overview',
              Icons.timeline,
              Colors.blue,
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          'Completion Status',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade800,
                          ),
                        ),
                      ),
                      Text(
                        '$completion%',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: _getCompletionColor(completion),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  LinearProgressIndicator(
                    value: completion / 100,
                    backgroundColor: Colors.grey.shade300,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _getCompletionColor(completion),
                    ),
                    minHeight: 8,
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _getStatusColor(task['status']).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _getStatusColor(task['status']).withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _getStatusIcon(task['status']),
                          color: _getStatusColor(task['status']),
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Status: ${task['status']}',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: _getStatusColor(task['status']),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Task Details Section
            _buildDetailCard(
              'Task Information',
              Icons.info_outline,
              Colors.green,
              child: Column(
                children: [
                  _buildDetailRow('Category', task['category'] ?? 'N/A', Icons.category),
                  const SizedBox(height: 16),
                  _buildDetailRow(
                    'Deadline', 
                    DateFormat('EEEE, dd MMMM yyyy').format(deadline), 
                    Icons.calendar_today
                  ),
                  const SizedBox(height: 16),
                  _buildDetailRow('Effort Required', '${task['effort'] ?? 0} hours', Icons.access_time),
                  const SizedBox(height: 16),
                  _buildDetailRow('Priority Level', task['priority'] ?? 'Medium', Icons.flag),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Actions Section - Responsive
            _buildDetailCard(
              'Quick Actions',
              Icons.bolt,
              Colors.purple,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  bool isWide = constraints.maxWidth > 400;
                  
                  if (isWide) {
                    return Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              // TaskDetailScreen'i aç
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => TaskDetailScreen(task: task),
                                ),
                              ).then((result) {
                                if (result != null && result is Map<String, dynamic>) {
                                  String action = result['action'];
                                  Map<String, dynamic> taskData = result['task'];
                                  
                                  setState(() {
                                    if (action == 'update') {
                                      // Local task listesini güncelle
                                      int taskIndex = widget.tasks.indexOf(task);
                                      if (taskIndex != -1) {
                                        widget.tasks[taskIndex] = taskData;
                                        selectedTask = taskData; // Seçili task'ı da güncelle
                                      }
                                    } else if (action == 'create') {
                                      // Yeni task ekle
                                      widget.tasks.add(taskData);
                                    }
                                  });
                                  
                                  // Ana sayfaya sonucu bildir
                                  Navigator.pop(context, result);
                                }
                              });
                            },
                            icon: const Icon(Icons.edit),
                            label: const Text('Edit Task'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              // Delete confirmation dialog
                              _showDeleteConfirmationDialog(task);
                            },
                            icon: const Icon(Icons.delete),
                            label: const Text('Delete Task'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      ],
                    );
                  } else {
                    return Column(
                      children: [
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              // TaskDetailScreen'i aç
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => TaskDetailScreen(task: task),
                                ),
                              ).then((result) {
                                if (result != null && result is Map<String, dynamic>) {
                                  String action = result['action'];
                                  Map<String, dynamic> taskData = result['task'];
                                  
                                  setState(() {
                                    if (action == 'update') {
                                      // Local task listesini güncelle
                                      int taskIndex = widget.tasks.indexOf(task);
                                      if (taskIndex != -1) {
                                        widget.tasks[taskIndex] = taskData;
                                        selectedTask = taskData; // Seçili task'ı da güncelle
                                      }
                                    } else if (action == 'create') {
                                      // Yeni task ekle
                                      widget.tasks.add(taskData);
                                    }
                                  });
                                  
                                  // Ana sayfaya sonucu bildir
                                  Navigator.pop(context, result);
                                }
                              });
                            },
                            icon: const Icon(Icons.edit),
                            label: const Text('Edit Task'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              // Delete confirmation dialog
                              _showDeleteConfirmationDialog(task);
                            },
                            icon: const Icon(Icons.delete),
                            label: const Text('Delete Task'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      ],
                    );
                  }
                },
              ),
            ),
            
            const SizedBox(height: 20), // Son boşluk
          ],
        ),
      ),
    );
  }
  
  Widget _buildDetailCard(String title, IconData icon, Color color, {required Widget child}) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }
  
  Widget _buildDetailRow(String label, String value, IconData icon) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: Colors.grey.shade600),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
        ),
        Expanded(
          flex: 3,
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black87,
            ),
          ),
        ),
      ],
    );
  }
  
  Color _getStatusColor(String? status) {
    switch (status) {
      case 'Complete':
        return Colors.green;
      case 'In Progress':
        return Colors.blue;
      case 'Not Started':
      default:
        return Colors.grey;
    }
  }
  
  Color _getPriorityColor(String? priority) {
    switch (priority) {
      case 'High':
        return Colors.red;
      case 'Medium':
        return Colors.orange;
      case 'Low':
      default:
        return Colors.green;
    }
  }
  
  Color _getCompletionColor(int completion) {
    if (completion >= 100) return Colors.green;
    if (completion >= 75) return Colors.blue;
    if (completion >= 50) return Colors.orange;
    if (completion >= 25) return Colors.red;
    return Colors.grey;
  }
  
  IconData _getStatusIcon(String? status) {
    switch (status) {
      case 'Complete':
        return Icons.check_circle;
      case 'In Progress':
        return Icons.hourglass_empty;
      case 'Not Started':
      default:
        return Icons.radio_button_unchecked;
    }
  }
  
  void _showDeleteConfirmationDialog(Map<String, dynamic> task) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.warning, color: Colors.red),
              SizedBox(width: 8),
              Text('Delete Task'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Are you sure you want to delete this task?'),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task['title'],
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Category: ${task['category'] ?? 'N/A'}',
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'This action cannot be undone.',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context); // Dialog'u kapat
                
                // Local task listesinden sil
                setState(() {
                  widget.tasks.remove(task);
                  selectedTask = null;
                });
                
                // Ana sayfaya sonucu bildir
                Navigator.pop(context, {
                  'action': 'delete',
                  'task': task,
                });
              },
              icon: const Icon(Icons.delete),
              label: const Text('Delete'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        );
      },
    );
  }
}