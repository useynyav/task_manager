import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import 'package:fl_chart/fl_chart.dart';

void main() {
  runApp(const TaskManagerApp()); // const eklendi
}

class TaskManagerApp extends StatelessWidget {
  const TaskManagerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Task Manager',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const TaskManagerScreen(), // const eklendi
    );
  }
}

class TaskManagerScreen extends StatefulWidget {
  const TaskManagerScreen({super.key});

  @override
  _TaskManagerScreenState createState() => _TaskManagerScreenState();
}

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
  int completionPercentage = 0;

  final List<String> statuses = ["Not Started", "In Progress", "Complete"];
  final List<String> priorities = ["High", "Medium", "Low"];
  String selectedPriority = "Medium";

  Map<String, List<Map<String, dynamic>>> categorizedTasks = {
    "Not Started": [],
     "In Progress": [],
    "Complete": []
  };

  DateTime? filterDate;
  List<Map<String, dynamic>> filteredTasks = [];

  bool isTableView = true; // false yerine true yaptık

  List<DataColumn> tableColumns = [
    DataColumn(label: Text('Task Name')),
    DataColumn(label: Text('Deadline')),
    DataColumn(label: Text('Category')),
    DataColumn(label: Text('Priority')),
    DataColumn(label: Text('Status')),
    DataColumn(label: Text('Effort (hour)')),
    DataColumn(label: Text('Completion')),
  ];

  String selectedFilterColumn = '';
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
    _tabController = TabController(length: 3, vsync: this);
    sortTasksByDeadline();
    filteredTasks = tasks;
  }

  @override
  void dispose() {
    _tabController.dispose();
    taskController.dispose();
    effortController.dispose();
    descriptionController.dispose();
    filterController.dispose();
    super.dispose();
  }

  String selectedStatus = "Not Started";

  // Pop-up'ta görev ekleme işlemi - düzeltilmiş hali
  void showAddTaskDialog() {
    // Dialog açılmadan önce değerleri sıfırla
    taskController.clear();
    effortController.clear();
    descriptionController.clear();
    categoryController.clear();
    selectedDeadline = null;
    selectedStatus = "Not Started";
    selectedPriority = "Medium";
    completionPercentage = 0;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        String errorMessage = ""; // Hata mesajı için değişken

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text("New Task"),
              content: SizedBox(
                width: double.maxFinite,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Hata mesajını göster
                      if (errorMessage.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.all(8.0),
                          margin: const EdgeInsets.only(bottom: 10),
                          decoration: BoxDecoration(
                            color: Colors.red.shade100,
                            border: Border.all(color: Colors.red),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.error, color: Colors.red, size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  errorMessage,
                                  style: TextStyle(color: Colors.red.shade700),
                                ),
                              ),
                            ],
                          ),
                        ),
                      TextField(
                        controller: taskController,
                        decoration: const InputDecoration(
                          labelText: "Task Name",
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 10),
                      DropdownButtonFormField<String>(
                        value: selectedStatus,
                        decoration: const InputDecoration(
                          labelText: "Status",
                          border: OutlineInputBorder(),
                        ),
                        items: statuses.map((String status) {
                          return DropdownMenuItem<String>(
                            value: status,
                            child: Text(status),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          setDialogState(() {
                            selectedStatus = newValue!;
                          });
                        },
                      ),
                      const SizedBox(height: 10),
                      DropdownButtonFormField<String>(
                        value: selectedPriority,
                        decoration: const InputDecoration(
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
                          setDialogState(() {
                            selectedPriority = newValue!;
                          });
                        },
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: effortController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: "Total Effort (hour)",
                          border: OutlineInputBorder(),
                        ),
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: descriptionController,
                        decoration: const InputDecoration(
                          labelText: "Description",
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 3,
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: categoryController,
                        decoration: const InputDecoration(
                          labelText: "Category",
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 10),
                      InkWell(
                        onTap: () async {
                          DateTime? pickedDate = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now(),
                            firstDate: DateTime.now(),
                            lastDate: DateTime(2100),
                          );
                          if (pickedDate != null) {
                            setDialogState(() {
                              selectedDeadline = pickedDate;
                            });
                          }
                        },
                        child: InputDecorator(
                          decoration: const InputDecoration(
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
                              const Icon(Icons.calendar_today),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      InputDecorator(
                        decoration: const InputDecoration(
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
                                      onPressed: () {
                                        setDialogState(() {
                                          if (completionPercentage > 0) {
                                            completionPercentage -= 25;
                                          }
                                        });
                                      },
                                      icon: const Icon(Icons.remove),
                                    ),
                                    IconButton(
                                      onPressed: () {
                                        setDialogState(() {
                                          if (completionPercentage < 100) {
                                            completionPercentage += 25;
                                          }
                                        });
                                      },
                                      icon: const Icon(Icons.add),
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
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text("Cancel"),
                ),
                ElevatedButton(
                  onPressed: () {
                    // Validasyon kontrolü
                    if (taskController.text.isEmpty ||
                        selectedDeadline == null ||
                        effortController.text.isEmpty ||
                        categoryController.text.isEmpty) {
                      
                      setDialogState(() {
                        errorMessage = "Please fill in all fields!";
                      });
                      return; // Dialog'u kapatmadan çık
                    }

                    // Validasyon başarılı ise görevi ekle ve dialog'u kapat
                    addTaskFromDialog();
                    Navigator.of(context).pop();
                  },
                  child: const Text("Add Task"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Dialog'dan görev ekleme işlemi için ayrı metod
  void addTaskFromDialog() {
    setState(() {
      Map<String, dynamic> newTask = {
        "title": taskController.text,
        "deadline": selectedDeadline!.toIso8601String(),
        "effort": int.tryParse(effortController.text) ?? 0,
        "description": descriptionController.text,
        "status": selectedStatus,
        "category": categoryController.text,
        "priority": selectedPriority,
        "completionPercentage": completionPercentage,
      };

      tasks.add(newTask);
      categorizedTasks[selectedStatus]!.add(newTask);
      sortTasksByDeadline(ascending: isAscending);
      filteredTasks = tasks;
    });
  }

  // Eski addTask metodunu güncelleyelim (artık sadece ScaffoldMessenger kullanacak)
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
        "priority": selectedPriority,
        "completionPercentage": completionPercentage,
      };

      tasks.add(newTask);
      categorizedTasks[selectedStatus]!.add(newTask);
      sortTasksByDeadline(ascending: isAscending);
      filteredTasks = tasks;
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
              onPressed: () => Navigator.of(context).pop(),
              child: Text("No"),
            ),
            TextButton(
              onPressed: () {
                deleteTask(task);
                Navigator.of(context).pop();
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

  Color getCompletionColor() {
    if (completionPercentage == 100) {
      return Colors.green;
    } else if (completionPercentage >= 50) {
      return Colors.blue;
    } else {
      return Colors.red;
    }
  }

  // LinearProgressIndicator için color düzeltmesi
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

  // Status bölümündeki LinearProgressIndicator düzeltmesi
  Widget buildStatusTab() {
    return Column(
      children: [
        const Padding(
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
                      margin: const EdgeInsets.all(8),
                      elevation: 3,
                      child: Column(
                        children: [
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            color: backgroundColor,
                            child: Text(
                              status,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                              textAlign: TextAlign.center,
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
                                      padding: const EdgeInsets.all(8),
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
                                          const SizedBox(height: 5),
                                          LinearProgressIndicator(
                                            value: completionPercentage / 100,
                                            backgroundColor: Colors.grey[300],
                                            valueColor: AlwaysStoppedAnimation<Color>(
                                              completionPercentage == 0 ? Colors.grey :
                                              completionPercentage <= 25 ? Colors.red :
                                              completionPercentage <= 50 ? Colors.orange :
                                              completionPercentage <= 75 ? Colors.blue :
                                              Colors.green
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
    );
  }

  // Filter section widget for filtering tasks by date or category
  Widget buildFilterSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      child: Row(
        children: [
          // Date filter
          Expanded(
            child: InkWell(
              onTap: () async {
                DateTime? pickedDate = await showDatePicker(
                  context: context,
                  initialDate: filterDate ?? DateTime.now(),
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2100),
                );
                if (pickedDate != null) {
                  filterTasksByDate(pickedDate);
                }
              },
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: "Filter by Deadline",
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.calendar_today, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      filterDate != null
                          ? DateFormat('dd/MM/yyyy').format(filterDate!)
                          : "Choose date",
                    ),
                    if (filterDate != null)
                      IconButton(
                        icon: Icon(Icons.clear, size: 18),
                        onPressed: clearFilter,
                        tooltip: "Clear date filter",
                      ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Category filter
          Expanded(
            child: TextField(
              controller: filterController,
              decoration: InputDecoration(
                labelText: "Filter by Category",
                border: OutlineInputBorder(),
                suffixIcon: filterController.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear),
                        onPressed: () {
                          filterController.clear();
                          filterTasksByCategory('');
                        },
                      )
                    : null,
              ),
              onChanged: (value) {
                filterTasksByCategory(value);
                setState(() {
                  selectedCategory = value;
                });
              },
            ),
          ),
          const SizedBox(width: 8),
          // Clear all filters button
          ElevatedButton(
            onPressed: clearFilter,
            child: const Text("Clear"),
          ),
        ],
      ),
    );
  }

  Widget buildDraggableDataTable() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        sortColumnIndex: sortColumnIndex,
        sortAscending: isAscending,
        columns: [
          DataColumn(
            label: const Text('Task Name'),
            onSort: (columnIndex, ascending) {
              setState(() {
                sortColumnIndex = columnIndex;
                isAscending = ascending;
                filteredTasks.sort((a, b) => ascending
                    ? a['title'].compareTo(b['title'])
                    : b['title'].compareTo(a['title']));
              });
            },
          ),
          DataColumn(
            label: const Text('Deadline'),
            onSort: (columnIndex, ascending) {
              setState(() {
                sortColumnIndex = columnIndex;
                isAscending = ascending;
                filteredTasks.sort((a, b) => ascending
                    ? DateTime.parse(a['deadline']).compareTo(DateTime.parse(b['deadline']))
                    : DateTime.parse(b['deadline']).compareTo(DateTime.parse(a['deadline'])));
              });
            },
          ),
          DataColumn(label: const Text('Category')),
          DataColumn(label: const Text('Priority')),
          DataColumn(label: const Text('Status')),
          DataColumn(label: const Text('Effort (hour)')),
          DataColumn(label: const Text('Completion')),
          DataColumn(label: const Text('Actions')),
        ],
        rows: filteredTasks.map((task) {
          int completionPercentage = task["completionPercentage"];
          return DataRow(
            cells: [
              DataCell(Text(task['title'])),
              DataCell(Text(DateFormat('dd/MM/yyyy').format(DateTime.parse(task['deadline'])))),
              DataCell(Text(task['category'] ?? '')),
              DataCell(Text(task['priority'] ?? '')),
              DataCell(Text(task['status'] ?? '')),
              DataCell(Text(task['effort'].toString())),
              DataCell(
                Row(
                  children: [
                    SizedBox(
                      width: 60,
                      child: LinearProgressIndicator(
                        value: completionPercentage / 100,
                        backgroundColor: Colors.grey[300],
                        valueColor: AlwaysStoppedAnimation<Color>(
                          completionPercentage == 0 ? Colors.grey :
                          completionPercentage <= 25 ? Colors.red :
                          completionPercentage <= 50 ? Colors.orange :
                          completionPercentage <= 75 ? Colors.blue :
                          Colors.green
                        ),
                        minHeight: 10,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text("$completionPercentage%"),
                  ],
                ),
              ),
              DataCell(
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () {
                    confirmDeleteTask(context, task);
                  },
                ),
              ),
            ],
            onSelectChanged: (_) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => TaskDetailScreen(task: task),
                ),
              ).then((updatedTask) {
                if (updatedTask != null) {
                  setState(() {
                    int taskIndex = tasks.indexWhere((t) => t["title"] == updatedTask["title"]);
                    if (taskIndex != -1) {
                      tasks[taskIndex] = updatedTask;
                    }
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
          );
        }).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Task Manager"),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            tooltip: "Save the datas",
            onPressed: saveTasksToDirectory,
          ),
          IconButton(
            icon: const Icon(Icons.folder_open),
            tooltip: "Load the datas",
            onPressed: loadTasksFromFile,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: "Task List"),
            Tab(text: "Status"),
            Tab(text: "Reports"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // 1. Tab: Görev Listesi (New Task butonu ile)
          LayoutBuilder(
            builder: (context, constraints) {
              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Task List",
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        ElevatedButton.icon(
                          onPressed: showAddTaskDialog,
                          icon: const Icon(Icons.add),
                          label: const Text("New Task"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  buildFilterSection(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () {
                          setState(() {
                            isTableView = false;
                          });
                        },
                        icon: const Icon(Icons.list),
                        label: const Text("List View"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: !isTableView ? Colors.blue : Colors.grey,
                        ),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton.icon(
                        onPressed: () {
                          setState(() {
                            isTableView = true;
                          });
                        },
                        icon: const Icon(Icons.grid_on),
                        label: const Text("Table View"),
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
                                margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
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
                                          if (taskIndex != -1) {
                                            tasks[taskIndex] = updatedTask;
                                          }
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
                                        Text("Priority: ${task["priority"]}"),
                                      const SizedBox(height: 5),
                                      Row(
                                        children: List.generate(4, (barIndex) {
                                          return Expanded(
                                            child: Container(
                                              height: 10,
                                              margin: const EdgeInsets.symmetric(horizontal: 2),
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
                                      const SizedBox(width: 8),
                                      Text("$completionPercentage%"),
                                    ],
                                  ),
                                  trailing: IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red),
                                    onPressed: () {
                                      confirmDeleteTask(context, task);
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
          // 2. Tab: Görev Statüleri - buildStatusTab() kullanarak
          buildStatusTab(),
          // 3. Tab: Yönetici Raporlama
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                const Text(
                  "Breakdown by Category",
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: tasks.isEmpty 
                    ? const Center(
                        child: Text(
                          "No tasks available for report",
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      )
                    : PieChart(
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
  late TextEditingController categoryController;
  late String selectedStatus;
  late int completionPercentage;
  DateTime? selectedDeadline;
  String selectedPriority = "Medium";

  final List<String> statuses = ["Not Started", "In Progress", "Complete"];

  @override
  void initState() {
    super.initState();
    titleController = TextEditingController(text: widget.task["title"]);
    effortController = TextEditingController(text: widget.task["effort"].toString());
    descriptionController = TextEditingController(text: widget.task["description"]);
    categoryController = TextEditingController(text: widget.task["category"]);
    selectedDeadline = DateTime.parse(widget.task["deadline"]);
    selectedPriority = widget.task["priority"] ?? "Medium";
    selectedStatus = widget.task["status"] ?? "Not Started";
    completionPercentage = widget.task["completionPercentage"] ?? 0;
  }

  @override
  void dispose() {
    titleController.dispose();
    effortController.dispose();
    descriptionController.dispose();
    categoryController.dispose();
    super.dispose();
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
    widget.task["category"] = categoryController.text;
    widget.task["priority"] = selectedPriority;
    widget.task["status"] = selectedStatus;
    widget.task["completionPercentage"] = completionPercentage;
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
