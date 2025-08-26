import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import 'package:fl_chart/fl_chart.dart';

void main() {
  runApp(TaskManagerApp());
}

class TaskManagerApp extends StatelessWidget {
  const TaskManagerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Task Manager',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.blue),
      home: TaskManagerScreen(),
    );
  }
}

class TaskManagerScreen extends StatefulWidget {
  const TaskManagerScreen({super.key});

  @override
  _TaskManagerScreenState createState() => _TaskManagerScreenState();
}

// Sıralama durumunu tutmak için yeni değişkenler ekleyelim
class _TaskManagerScreenState extends State<TaskManagerScreen> with SingleTickerProviderStateMixin {
  int? sortColumnIndex;
  bool isAscending = true;
  Map<int, bool> columnSortDirections = {};
  late TabController _tabController;
  List<Map<String, dynamic>> tasks = [];

  TextEditingController taskController = TextEditingController();
  TextEditingController effortController = TextEditingController();
  TextEditingController descriptionController = TextEditingController();
  TextEditingController categoryController = TextEditingController();
  String selectedCategory = "";
  DateTime? selectedDeadline;
  int completionPercentage = 0; // Completion percentage

  final List<String> statuses = ["Not Started", "In Progress", "Complete"];
  final List<String> priorities = ["High", "Medium", "Low"]; // Priority values
  String selectedPriority = "Medium"; // Default priority

  Map<String, List<Map<String, dynamic>>> categorizedTasks = {
    "Not Started": [],
     "In Progress": [],
    "Complete": []
  };

  DateTime? filterDate;
  List<Map<String, dynamic>> filteredTasks = [];

  bool isTableView = false; // Varsayılan olarak liste görünümü

  List<DataColumn> tableColumns = [
    DataColumn(label: Text('Task Name')),
    DataColumn(label: Text('Deadline')),
    DataColumn(label: Text('Category')),
    DataColumn(label: Text('Priority')),
    DataColumn(label: Text('Status')), // Yeni sütun
    DataColumn(label: Text('Effort (hour)')),
    DataColumn(label: Text('Completion')),
  ];

  String selectedFilterColumn = ''; // Seçilen sütun
  final List<String> filterColumns = [
    'Task Name',
    'Category',
    'Priority',
    'Status',
    'Effort'
  ];
  TextEditingController filterController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this); // TabController length updated to 4
    sortTasksByDeadline(); // Varsayılan olarak artan sıralama
    filteredTasks = tasks; // Tüm görevlerin başlangıçta görünmesini sağla
  }

  @override
  void dispose() {
    _tabController.dispose();
    taskController.dispose();
    effortController.dispose();
    descriptionController.dispose();
    filterController.dispose(); // Yeni controller'ı ekleyelim
    super.dispose();
  }

  String selectedStatus = "Not Started"; // Varsayılan durum

  void addTask() {
    if (taskController.text.isEmpty ||
        selectedDeadline == null ||
        effortController.text.isEmpty ||
        categoryController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Please fill in all fields!"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      Map<String, dynamic> newTask = {
        "title": taskController.text,
        "deadline": selectedDeadline!.toIso8601String(),
        "effort": int.tryParse(effortController.text) ?? 0,
        "description": descriptionController.text,
        "status": selectedStatus,
        "category": categoryController.text,
        "priority": selectedPriority, // Add priority to the task
        "completionPercentage": completionPercentage, // Add completion percentage to the task
      };

      tasks.add(newTask);
      categorizedTasks[selectedStatus]!.add(newTask);
      sortTasksByDeadline(ascending: isAscending);

      // Update filteredTasks after adding a new task
      filteredTasks = tasks;

      taskController.clear();
      effortController.clear();
      descriptionController.clear();
      categoryController.clear();
      selectedDeadline = null;
      selectedStatus = "Not Started";
      selectedPriority = "Medium"; // Reset priority to default
      completionPercentage = 0; // Reset completion percentage to 0
    });
  }

  // Görevleri deadline'a göre sıralama
  void sortTasksByDeadline({bool ascending = true}) {
    tasks.sort((a, b) {
      DateTime dateA = DateTime.parse(a['deadline']);
      DateTime dateB = DateTime.parse(b['deadline']);
      return ascending ? dateA.compareTo(dateB) : dateB.compareTo(dateA);
    });
  }

  // Görevi sürükleyerek statü değiştirme
  void moveTask(String fromStatus, String toStatus, Map<String, dynamic> task) {
    setState(() {
      categorizedTasks[fromStatus]!.remove(task);
      categorizedTasks[toStatus]!.add(task);
      task["status"] = toStatus;
    });
  }

  // Tarih seçme işlemi
  Future<void> pickDeadline() async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (pickedDate != null) {
      setState(() {
        selectedDeadline = pickedDate;
      });
    }
  }

  // Görevi tamamen silme
  void deleteTask(Map<String, dynamic> task) {
    setState(() {
      tasks.remove(task);
      categorizedTasks[task["status"]]!.remove(task);
    });
  }

  void confirmDeleteTask(BuildContext context, Map<String, dynamic> task) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Delete task"),
          content: Text("Are you sure want to delete task?"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Dialogu kapat
              },
              child: Text("No"),
            ),
            TextButton(
              onPressed: () {
                deleteTask(task);
                Navigator.of(context).pop(); // Dialogu kapat
              },
              child: Text("Yes"),
            ),
          ],
        );
      },
    );
  }

  // Verileri seçilen dizine kaydeden fonksiyon (.hus dosyası olarak)
  Future<void> saveTasksToDirectory() async {
    String jsonString = jsonEncode(tasks);
    String? selectedDirectory = await FilePicker.platform.getDirectoryPath(
      dialogTitle: "Choose location",
    );
    if (selectedDirectory != null) {
      String fullPath = '$selectedDirectory/tasks.json';
      File file = File(fullPath);
      await file.writeAsString(jsonString);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Data saved in the  $fullPath .")),
      );
    }
  }

  // .hus dosyasından verileri yükleyen fonksiyon
  Future<void> loadTasksFromFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );
    if (result != null && result.files.single.path != null) {
      File file = File(result.files.single.path!);
      String contents = await file.readAsString();
      List<dynamic> jsonData = jsonDecode(contents);
      setState(() {
        tasks = jsonData.map((task) => Map<String, dynamic>.from(task)).toList();
        categorizedTasks = {
          "Not Started": [],
          "In Progress": [],
          "Complete": [],
        };
        for (var task in tasks) {
          String status = task["status"];
          categorizedTasks[status]?.add(task);
        }
        sortTasksByDeadline(ascending: isAscending);
        filteredTasks = tasks; // Update filteredTasks after loading tasks
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Datas was successfully saved.")));
    }
  }

  void filterTasksByDate(DateTime date) {
    setState(() {
      filterDate = date;
      filteredTasks = tasks.where((task) {
        DateTime taskDate = DateTime.parse(task['deadline']);
        return taskDate.year == date.year && taskDate.month == date.month && taskDate.day == date.day;
      }).toList();
    });
  }

  void clearFilter() {
    setState(() {
      filterDate = null;
      selectedCategory = "";
      filteredTasks = tasks; // Tüm görevlerin görünmesini sağla
    });
  }

  void filterTasksByCategory(String category) {
    setState(() {
      if (category.isEmpty) {
        filteredTasks = tasks;
      } else {
        filteredTasks = tasks.where((task) {
          return task['category'].toLowerCase().contains(category.toLowerCase());
        }).toList();
      }
    });
  }

  List<PieChartSectionData> getCategoryPieChartSections() {
    Map<String, int> categoryCounts = {};

    for (var task in tasks) {
      String category = task['category'];
      if (categoryCounts.containsKey(category)) {
        categoryCounts[category] = categoryCounts[category]! + 1;
      } else {
        categoryCounts[category] = 1;
      }
    }

    int totalCount = tasks.length;

    return categoryCounts.entries.map((entry) {
      Color color;
      if (entry.key == "Not Started") {
        color = Colors.grey;
      } else if (entry.key == "Complete") {
        color = Colors.green;
      } else {
        color = Colors.primaries[categoryCounts.keys.toList().indexOf(entry.key) % Colors.primaries.length].withOpacity(0.5);
      }

      return PieChartSectionData(
        color: color,
        value: entry.value.toDouble(),
        title: '${entry.key}: ${((entry.value / totalCount) * 100).toStringAsFixed(1)}%',
        radius: 50,
      );
    }).toList();
  }

  void incrementCompletion() {
    setState(() {
      if (completionPercentage < 100) {
        completionPercentage += 25;
      }
    });
  }

  void decrementCompletion() {
    setState(() {
      if (completionPercentage > 0) {
        completionPercentage -= 25;
      }
    });
  }

  Color getCompletionColor() {
    if (completionPercentage == 100) {
      return Colors.green;
    } else if (completionPercentage >= 50) {
      return Colors.blue;
    } else {
      return Colors.red;
    }
  }

  // Method to get the color of the completion bar based on the index
  Color getCompletionBarColor(int index) {
    switch (index) {
      case 0:
        return Colors.grey;
      case 1:
        return Colors.red;
      case 2:
        return Colors.blue;
      case 3:
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  // Sütun düzenini değiştirmek için yeni bir method
  void reorderColumns(int oldIndex, int newIndex) {
    setState(() {
      if (oldIndex < newIndex) {
        newIndex -= 1;
      }
      final DataColumn item = tableColumns.removeAt(oldIndex);
      tableColumns.insert(newIndex, item);
    });
  }

  // buildDraggableDataTable metodunu güncelleyelim
  Widget buildDraggableDataTable() {
    return SingleChildScrollView(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: List.generate(tableColumns.length, (index) {
            String columnText = '';
            if (tableColumns[index].label is Text) {
              columnText = (tableColumns[index].label as Text).data ?? '';
            }

            return DataColumn(
              label: Row(
                children: [
                  Text(
                    columnText,
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(width: 4),
                  InkWell(
                    onTap: () => onSort(index, true),
                    child: Icon(
                      Icons.arrow_upward,
                      size: 16,
                      color: columnSortDirections[index] == true ? Colors.blue : Colors.grey,
                    ),
                  ),
                  InkWell(
                    onTap: () => onSort(index, false),
                    child: Icon(
                      Icons.arrow_downward,
                      size: 16,
                      color: columnSortDirections[index] == false ? Colors.blue : Colors.grey,
                    ),
                  ),
                ],
              ),
            );
          }),
          rows: filteredTasks.map((task) {
            return DataRow(
              cells: List.generate(tableColumns.length, (columnIndex) {
                return _buildDataCell(task, columnIndex);
              }),
            );
          }).toList(),
        ),
      ),
    );
  }

  // Sıralama işlemi için yeni bir metod ekleyelim
  void onSort(int columnIndex, bool ascending) {
    setState(() {
      columnSortDirections[columnIndex] = ascending;

      filteredTasks.sort((a, b) {
        var aValue = getColumnValue(a, columnIndex);
        var bValue = getColumnValue(b, columnIndex);

        if (aValue == null || bValue == null) {
          return 0;
        }

        int comparison;
        if (aValue is num && bValue is num) {
          comparison = aValue.compareTo(bValue);
        } else if (aValue is DateTime && bValue is DateTime) {
          comparison = aValue.compareTo(bValue);
        } else {
          comparison = aValue.toString().compareTo(bValue.toString());
        }

        return ascending ? comparison : -comparison;
      });
    });
  }

  // Sütun değerini almak için yardımcı metod
  dynamic getColumnValue(Map<String, dynamic> task, int columnIndex) {
    switch (columnIndex) {
      case 0:
        return task['title'];
      case 1:
        return DateTime.parse(task['deadline']);
      case 2:
        return task['category'];
      case 3:
        return task['priority'];
      case 4:
        return task['status'];
      case 5:
        return task['effort'];
      case 6:
        return task['completionPercentage'];
      default:
        return null;
    }
  }

  // Her bir hücreyi oluşturan yardımcı method
  DataCell _buildDataCell(Map<String, dynamic> task, int columnIndex) {
    switch (columnIndex) {
      case 0:
        return DataCell(
          Text(task["title"]),
          onTap: () => _onTaskTap(task),
        );
      case 1:
        return DataCell(Text(DateFormat('dd/MM/yyyy').format(DateTime.parse(task['deadline']))));
      case 2:
        return DataCell(Text(task['category'] ?? ''));
      case 3:
        return DataCell(Text(task['priority'] ?? ''));
      case 4:
        return DataCell(Text(task['status'] ?? '')); // Yeni hücre
      case 5:
        return DataCell(Text('${task['effort']}'));
      case 6:
        return DataCell(
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                children: List.generate(4, (barIndex) {
                  return Expanded(
                    child: Container(
                      height: 10,
                      margin: EdgeInsets.symmetric(horizontal: 2),
                      color: barIndex < (task['completionPercentage'] / 25)
                          ? (task['completionPercentage'] == 25 ? Colors.grey
                            : task['completionPercentage'] == 50 ? Colors.red
                            : task['completionPercentage'] == 75 ? Colors.blue
                            : task['completionPercentage'] == 100 ? Colors.green
                            : Colors.grey[300])
                          : Colors.grey[300],
                    ),
                  );
                }),
              ),
              Text('${task['completionPercentage']}%'),
            ],
          ),
        );
      default:
        return DataCell(Text(''));
    }
  }

  void _onTaskTap(Map<String, dynamic> task) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TaskDetailScreen(task: task),
      ),
    ).then((updatedTask) {
      if (updatedTask != null) {
        setState(() {
          int taskIndex = tasks.indexWhere((t) => t["title"] == updatedTask["title"]);
          tasks[taskIndex] = updatedTask;
          if (filterDate != null) {
            filterTasksByDate(filterDate!);
          }
          if (selectedCategory.isNotEmpty) {
            filterTasksByCategory(selectedCategory);
          }
        });
      }
    });
  }

  // Yeni filtreleme metodu
  void filterTasks(String column, String value) {
    setState(() {
      if (value.isEmpty) {
        filteredTasks = tasks;
      } else {
        filteredTasks = tasks.where((task) {
          switch (column) {
            case 'Task Name':
              return task['title'].toString().toLowerCase().contains(value.toLowerCase());
            case 'Category':
              return task['category'].toString().toLowerCase().contains(value.toLowerCase());
            case 'Priority':
              return task['priority'].toString().toLowerCase().contains(value.toLowerCase());
            case 'Status':
              return task['status'].toString().toLowerCase().contains(value.toLowerCase());
            case 'Effort':
              return task['effort'].toString().contains(value);
            default:
              return false;
          }
        }).toList();
      }
    });
  }

  // Görev Listesi tab'ındaki filtreleme alanını güncelleyelim
  Widget buildFilterSection() {
    return Container(
      padding: EdgeInsets.all(8),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: selectedFilterColumn.isEmpty ? null : selectedFilterColumn,
                  decoration: InputDecoration(
                    labelText: "Filter",
                    border: OutlineInputBorder(),
                  ),
                  hint: Text('Choose column'),
                  items: filterColumns.map((String column) {
                    return DropdownMenuItem<String>(
                      value: column,
                      child: Text(column),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      selectedFilterColumn = newValue ?? '';
                      filterController.clear();
                      filteredTasks = tasks; // Reset filtreleme
                    });
                  },
                ),
              ),
              SizedBox(width: 8),
              IconButton(
                icon: Icon(Icons.clear),
                onPressed: () {
                  setState(() {
                    selectedFilterColumn = '';
                    filterController.clear();
                    filteredTasks = tasks;
                  });
                },
                tooltip: 'Clear filter',
              ),
            ],
          ),
          if (selectedFilterColumn.isNotEmpty) ...[
            SizedBox(height: 8),
            TextField(
              controller: filterController,
              decoration: InputDecoration(
                labelText: "Filter for $selectedFilterColumn  ",
                border: OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(Icons.clear),
                  onPressed: () {
                    filterController.clear();
                    filterTasks(selectedFilterColumn, '');
                  },
                ),
              ),
              onChanged: (value) => filterTasks(selectedFilterColumn, value),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Task Manager"),
        actions: [
          IconButton(
            icon: Icon(Icons.save),
            tooltip: "Save the datas",
            onPressed: saveTasksToDirectory,
          ),
          IconButton(
            icon: Icon(Icons.folder_open),
            tooltip: "Load the datas",
            onPressed: loadTasksFromFile,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: "Creating New Task"),
            Tab(text: "Task List"),
            Tab(text: "Status"),
            Tab(text: "Reports"), // Yeni Tab
          ],
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return TabBarView(
            controller: _tabController,
            children: [
              // 1. Tab: Görev Ekle - Düzenlenmiş hali
              SingleChildScrollView(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Sol taraf - Form alanları
                    SizedBox(
                      width: MediaQuery.of(context).size.width * 0.5, // Ekranın sol yarısı
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            TextField(
                              controller: taskController,
                              decoration: InputDecoration(
                                labelText: "Task Name",
                                border: OutlineInputBorder(),
                              ),
                            ),
                            SizedBox(height: 10),
                            DropdownButtonFormField<String>(
                              value: selectedStatus,
                              decoration: InputDecoration(
                                labelText: "Status ",
                                border: OutlineInputBorder(),
                              ),
                              items: statuses.map((String status) {
                                return DropdownMenuItem<String>(
                                  value: status,
                                  child: Text(status),
                                );
                              }).toList(),
                              onChanged: (String? newValue) {
                                setState(() {
                                  selectedStatus = newValue!;
                                });
                              },
                            ),
                            SizedBox(height: 10),
                            DropdownButtonFormField<String>(
                              value: selectedPriority, // Varsayılan değer: "Medium"
                              decoration: InputDecoration(
                                labelText: "Priority",
                                border: OutlineInputBorder(),
                              ),
                              items: priorities.map((String priority) {
                                return DropdownMenuItem<String>(
                                  value: priority,
                                  child: Text(priority),
                                );
                              }).toList(),
                              onChanged: (String? newValue) {
                                setState(() {
                                  selectedPriority = newValue!;
                                });
                              },
                            ),
                            SizedBox(height: 10),
                            TextField(
                              controller: effortController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: "Total Effort (hour)",
                                border: OutlineInputBorder(),
                              ),
                              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                            ),
                            SizedBox(height: 10),
                            TextField(
                              controller: descriptionController,
                              decoration: InputDecoration(
                                labelText: "Description",
                                border: OutlineInputBorder(),
                              ),
                              maxLines: 3,
                            ),
                            SizedBox(height: 10),
                            TextField(
                              controller: categoryController,
                              decoration: InputDecoration(
                                labelText: "Category",
                                border: OutlineInputBorder(),
                              ),
                            ),
                            SizedBox(height: 10),
                            InkWell(
                              onTap: pickDeadline,
                              child: InputDecorator(
                                decoration: InputDecoration(
                                  labelText: "Deadline",
                                  border: OutlineInputBorder(),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      selectedDeadline != null
                                          ? DateFormat('dd/MM/yyyy').format(selectedDeadline!)
                                          : "Choose date",
                                    ),
                                    Icon(Icons.calendar_today),
                                  ],
                                ),
                              ),
                            ),
                            SizedBox(height: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                InputDecorator(
                                  decoration: InputDecoration(
                                    labelText: "Percentage of Completion",
                                    border: OutlineInputBorder(),
                                  ),
                                  child: Column(
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text("$completionPercentage%"),
                                          Row(
                                            children: [
                                              IconButton(
                                                onPressed: decrementCompletion,
                                                icon: Icon(Icons.remove),
                                              ),
                                              IconButton(
                                                onPressed: incrementCompletion,
                                                icon: Icon(Icons.add),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                      LinearProgressIndicator(
                                        value: completionPercentage / 100,
                                        backgroundColor: Colors.grey[300],
                                        color: getCompletionColor(),
                                        minHeight: 10,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: addTask,
                              child: Text("Add"),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Sağ taraf - Boş veya ileride eklenecek içerik için
                    Expanded(
                      child: Container(),
                    ),
                  ],
                ),
              ),
              // 2. Tab: Görev Listesi
              LayoutBuilder(
                builder: (context, constraints) {
                  bool isMobile = constraints.maxWidth < 600;
                  return Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.start, // changed from spaceBetween
                          children: [
                            Text(
                              "List",
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                      buildFilterSection(), // Yeni filtreleme alanını ekleyelim
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ElevatedButton.icon(
                            onPressed: () {
                              setState(() {
                                isTableView = false;
                              });
                            },
                            icon: Icon(Icons.list),
                            label: Text("List View"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: !isTableView ? Colors.blue : Colors.grey,
                            ),
                          ),
                          SizedBox(width: 10),
                          ElevatedButton.icon(
                            onPressed: () {
                              setState(() {
                                isTableView = true;
                              });
                            },
                            icon: Icon(Icons.grid_on),
                            label: Text("Table View"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isTableView ? Colors.blue : Colors.grey,
                            ),
                          ),
                        ],
                      ),
                      Expanded(
                        child: isTableView
                            ? buildDraggableDataTable()
                            : ListView.builder(
                                itemCount: filteredTasks.length,
                                itemBuilder: (context, index) {
                                  var task = filteredTasks[index];
                                  DateTime deadlineDate = DateTime.parse(task['deadline']);
                                  int completionPercentage = task["completionPercentage"];
                                  return Card(
                                    elevation: 2,
                                    margin: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                    child: ListTile(
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => TaskDetailScreen(task: task),
                                          ),
                                        ).then((updatedTask) {
                                          if (updatedTask != null) {
                                            setState(() {
                                              int taskIndex = tasks.indexWhere((t) => t["title"] == updatedTask["title"]);
                                              tasks[taskIndex] = updatedTask;
                                              if (filterDate != null) {
                                                filterTasksByDate(filterDate!);
                                              }
                                              if (selectedCategory.isNotEmpty) {
                                                filterTasksByCategory(selectedCategory);
                                              }
                                            });
                                          }
                                        });
                                      },
                                      title: Text(task["title"]),
                                      subtitle: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            "Deadline: ${DateFormat('dd/MM/yyyy').format(deadlineDate)}\nEffort: ${task['effort']} hour",
                                          ),
                                          if (task["description"] != null && task["description"].toString().isNotEmpty)
                                            Text("Description: ${task["description"]}"),
                                          if (task["category"] != null && task["category"].toString().isNotEmpty)
                                            Text("Category: ${task["category"]}"),
                                          if (task["priority"] != null && task["priority"].toString().isNotEmpty)
                                            Text("priority: ${task["priority"]}"),
                                          SizedBox(height: 5),
                                          Row(
                                            children: [
                                              SizedBox(
                                                width: MediaQuery.of(context).size.width / 4, // Ekran genişliğinin 4'te 1'i
                                                child: Row(
                                                  children: List.generate(4, (barIndex) {
                                                    return Expanded(
                                                      child: Container(
                                                        height: 10,
                                                        margin: EdgeInsets.symmetric(horizontal: 2),
                                                        color: barIndex < (completionPercentage / 25)
                                                            ? (completionPercentage == 25 ? Colors.grey
                                                              : completionPercentage == 50 ? Colors.red
                                                              : completionPercentage == 75 ? Colors.blue
                                                              : completionPercentage == 100 ? Colors.green
                                                              : Colors.grey[300])
                                                            : Colors.grey[300],
                                                      ),
                                                    );
                                                  }),
                                                ),
                                              ),
                                              SizedBox(width: 8), // Bar ile yüzde arasında boşluk
                                              Text("$completionPercentage%"), // Yüzde değeri
                                            ],
                                          ),
                                        ],
                                      ),
                                      trailing: IconButton(
                                        icon: Icon(Icons.delete, color: Colors.red),
                                        onPressed: () {
                                          confirmDeleteTask(context, task);
                                          if (filterDate != null) {
                                            filterTasksByDate(filterDate!);
                                          }
                                          if (selectedCategory.isNotEmpty) {
                                            filterTasksByCategory(selectedCategory);
                                          }
                                        },
                                      ),
                                    ),
                                  );
                                },
                              ),
                      ),
                    ],
                  );
                },
              ),
              // 3. Tab: Görev Statüleri
              Column(
                children: [
                  Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text(
                      "Status",
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                  ),
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: statuses.map((status) {
                        Color backgroundColor;
                        if (status == "Not Started") {
                          backgroundColor = Colors.grey;
                        } else if (status == "Complete") {
                          backgroundColor = Colors.green;
                        } else {
                          backgroundColor = Colors.blueAccent;
                        }

                        return Expanded(
                          child: DragTarget<Map<String, dynamic>>(
                            onAcceptWithDetails: (details) {
                              var task = details.data;
                              moveTask(task["status"], status, task);
                            },
                            builder: (context, candidateData, rejectedData) {
                              return Card(
                                margin: EdgeInsets.all(8),
                                elevation: 3,
                                child: Column(
                                  children: [
                                    Container(
                                      width: double.infinity, // Makes container fill the card width
                                      padding: EdgeInsets.symmetric(vertical: 12), // Increased padding
                                      color: backgroundColor,
                                      child: Text(
                                        status,
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16, // Increased font size
                                        ),
                                        textAlign: TextAlign.center, // Center the text
                                      ),
                                    ),
                                    Expanded(
                                      child: ListView.builder(
                                        itemCount: categorizedTasks[status]!.length,
                                        itemBuilder: (context, index) {
                                          var task = categorizedTasks[status]![index];
                                          int completionPercentage = task["completionPercentage"];
                                          return Draggable<Map<String, dynamic>>(
                                            data: task,
                                            feedback: Material(
                                              child: Container(
                                                padding: EdgeInsets.all(8),
                                                color: Colors.grey[300],
                                                child: Text(task["title"]),
                                              ),
                                            ),
                                            childWhenDragging: Container(),
                                            child: Card(
                                              child: ListTile(
                                                title: Text(task["title"]),
                                                subtitle: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      "Deadline: ${DateFormat('dd/MM/yyyy').format(DateTime.parse(task['deadline']))}",
                                                    ),
                                                    Text("Category: ${task['category'] ?? ''}"),
                                                    Text("Priority: ${task['priority'] ?? ''}"),
                                                    SizedBox(height: 5),
                                                    // Tamamlanma yüzdesi göstergesi
                                                    LinearProgressIndicator(
                                                      value: completionPercentage / 100,
                                                      backgroundColor: Colors.grey[300],
                                                      valueColor: AlwaysStoppedAnimation<Color>(
                                                        getCompletionBarColor((completionPercentage / 25).floor() - 1)
                                                      ),
                                                      minHeight: 10,
                                                    ),
                                                    Padding(
                                                      padding: const EdgeInsets.only(top: 4),
                                                      child: Text("Completion: $completionPercentage%"),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
              // 4. Tab: Yönetici Raporlama
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Text(
                      "Breakdown by Category",
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 16),
                    Expanded(
                      child: PieChart(
                        PieChartData(
                          sections: getCategoryPieChartSections(),
                          centerSpaceRadius: 40,
                          sectionsSpace: 2,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// Görev detaylarını düzenleyebileceğiniz ekran (Detay sayfası)
class TaskDetailScreen extends StatefulWidget {
  final Map<String, dynamic> task;
  const TaskDetailScreen({super.key, required this.task});

  @override
  _TaskDetailScreenState createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  late TextEditingController titleController;
  late TextEditingController effortController;
  late TextEditingController descriptionController;
  late TextEditingController categoryController; // Yeni
  late String selectedStatus; // Yeni
  late int completionPercentage; // Yeni
  DateTime? selectedDeadline;
  String selectedPriority = "Medium";

  final List<String> statuses = ["Not Started", "In Progress", "Complete"]; // Yeni

  @override
  void initState() {
    super.initState();
    titleController = TextEditingController(text: widget.task["title"]);
    effortController = TextEditingController(text: widget.task["effort"].toString());
    descriptionController = TextEditingController(text: widget.task["description"]);
    categoryController = TextEditingController(text: widget.task["category"]); // Yeni
    selectedDeadline = DateTime.parse(widget.task["deadline"]);
    selectedPriority = widget.task["priority"] ?? "Medium";
    selectedStatus = widget.task["status"] ?? "Not Started"; // Yeni
    completionPercentage = widget.task["completionPercentage"] ?? 0; // Yeni
  }

  @override
  void dispose() {
    titleController.dispose();
    effortController.dispose();
    descriptionController.dispose();
    categoryController.dispose(); // Yeni
    super.dispose();
  }

  // Tamamlanma yüzdesini artırma
  void incrementCompletion() {
    setState(() {
      if (completionPercentage < 100) {
        completionPercentage += 25;
      }
    });
  }

  // Tamamlanma yüzdesini azaltma
  void decrementCompletion() {
    setState(() {
      if (completionPercentage > 0) {
        completionPercentage -= 25;
      }
    });
  }

  // İlerleme çubuğu rengi
  Color getCompletionColor() {
    if (completionPercentage == 100) {
      return Colors.green;
    } else if (completionPercentage >= 50) {
      return Colors.blue;
    } else {
      return Colors.red;
    }
  }

  // Method to get the color of the completion bar based on the index
  Color getCompletionBarColor(int index) {
    switch (index) {
      case 0:
        return Colors.grey;
      case 1:
        return Colors.red;
      case 2:
        return Colors.blue;
      case 3:
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  Future<void> pickDeadline() async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: selectedDeadline ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (pickedDate != null) {
      setState(() {
        selectedDeadline = pickedDate;
      });
    }
  }

  // Güncellenmiş task nesnesini döndürüyoruz.
  void saveChanges() {
    widget.task["title"] = titleController.text;
    widget.task["effort"] = int.parse(effortController.text);
    widget.task["description"] = descriptionController.text;
    widget.task["category"] = categoryController.text; // Yeni
    widget.task["priority"] = selectedPriority;
    widget.task["status"] = selectedStatus; // Yeni
    widget.task["completionPercentage"] = completionPercentage; // Yeni
    if (selectedDeadline != null) {
      widget.task["deadline"] = selectedDeadline!.toIso8601String();
    }
    Navigator.pop(context, widget.task);
  }

  // İptal: Hiçbir değişiklik yapmadan geri dönüyoruz.
  void cancelChanges() {
    Navigator.pop(context, null);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Details")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Title",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              TextFormField(
                controller: titleController,
                decoration: InputDecoration(hintText: "Task Title"),
              ),
              SizedBox(height: 16),
              Text(
                "Effort (hour)",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              TextFormField(
                controller: effortController,
                decoration: InputDecoration(hintText: "Effort"),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),
              SizedBox(height: 16),
              Text(
                "Description",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              TextFormField(
                controller: descriptionController,
                decoration: InputDecoration(hintText: "Description"),
                maxLines: 3,
              ),
              SizedBox(height: 16),
              Text(
                "Priority",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              DropdownButtonFormField<String>(
                value: selectedPriority,
                decoration: InputDecoration(
                  labelText: "Priority",
                  border: OutlineInputBorder(),
                ),
                items: ["High", "Medium", "Low"].map((String priority) {
                  return DropdownMenuItem<String>(
                    value: priority,
                    child: Text(priority),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    selectedPriority = newValue!;
                  });
                },
              ),
              SizedBox(height: 16),
              Text(
                "Deadline",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              Row(
                children: [
                  Text(
                    selectedDeadline != null ? DateFormat('dd/MM/yyyy').format(selectedDeadline!) : "Date not selected",
                  ),
                  SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: pickDeadline,
                    child: Text("Select date"),
                  ),
                ],
              ),
              SizedBox(height: 24),
              Text("Category", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              TextFormField(
                controller: categoryController,
                decoration: InputDecoration(
                  hintText: "Category",
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 16),

              Text("Status", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              DropdownButtonFormField<String>(
                value: selectedStatus,
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                ),
                items: statuses.map((String status) {
                  return DropdownMenuItem<String>(
                    value: status,
                    child: Text(status),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    selectedStatus = newValue!;
                  });
                },
              ),
              SizedBox(height: 16),

              Text("Percentage of Completion", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              InputDecorator(
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("$completionPercentage%"),
                        Row(
                          children: [
                            IconButton(
                              onPressed: decrementCompletion,
                              icon: Icon(Icons.remove),
                            ),
                            IconButton(
                              onPressed: incrementCompletion,
                              icon: Icon(Icons.add),
                            ),
                          ],
                        ),
                      ],
                    ),
                    LinearProgressIndicator(
                      value: completionPercentage / 100,
                      backgroundColor: Colors.grey[300],
                      valueColor: AlwaysStoppedAnimation<Color>(
                        getCompletionBarColor((completionPercentage / 25).floor() - 1)
                      ),
                      minHeight: 10,
                    ),
                  ],
                ),
              ),
              SizedBox(height: 24),

              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ElevatedButton(
                    onPressed: cancelChanges,
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                    child: Text("Cancel"),
                  ),
                  SizedBox(width: 16),
                  ElevatedButton(onPressed: saveChanges, child: Text("Save")),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
