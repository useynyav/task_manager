import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/draggablereport.dart';
import 'package:flutter_application_1/screens/task_detail_screen.dart';
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
  String filterDateType = ''; // 'today', 'week', 'month', 'custom' değerlerini tutacak
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

  // Kolon sıralaması için liste ekle
  List<String> columnOrder = [
    'title',
    'deadline', 
    'category',
    'priority',
    'status',
    'effort',
    'completionPercentage',
    'actions'
  ];

  // Kolon başlıkları mapping
  final Map<String, String> columnTitles = {
    'title': 'Task Name',
    'deadline': 'Deadline',
    'category': 'Category', 
    'priority': 'Priority',
    'status': 'Status',
    'effort': 'Effort (h)',
    'completionPercentage': 'Completion',
    'actions': 'Actions',
  };

  // Gizli kolonlar için liste ekle
  List<String> hiddenColumns = [];

  // Kolon genişlikleri için map ekle - flex tabanlı yapacağız
  Map<String, double> columnWidths = {
    'title': 3.0,        // En geniş kolon
    'deadline': 1.5,
    'category': 1.5,
    'priority': 1.0,
    'status': 1.5,
    'effort': 1.0,
    'completionPercentage': 2.0,
    'actions': 1.0,      // En dar kolon
  };

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

  // JSON dosyalarını listeleyen ve seçim yapabileceğiniz dialog
  Future<void> showLoadTasksDialog() async {
    String? selectedDirectory = await FilePicker.platform.getDirectoryPath(
      dialogTitle: "Choose folder containing JSON files",
    );
    
    if (selectedDirectory != null) {
      try {
        Directory directory = Directory(selectedDirectory);
        List<FileSystemEntity> files = directory.listSync();
        
        // JSON dosyalarını filtrele
        List<File> jsonFiles = files
            .where((file) => file is File && file.path.endsWith('.json'))
            .cast<File>()
            .toList();
        
        if (jsonFiles.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("No JSON files found in selected folder"),
              backgroundColor: Colors.orange,
            ),
          );
          return;
        }
        
        // JSON dosyalarını dialog ile göster
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Row(
                children: [
                  Icon(Icons.folder_open, color: Colors.blue),
                  SizedBox(width: 8),
                  Text("Select Task File"),
                ],
              ),
              content: Container(
                width: double.maxFinite,
                height: 400,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Found ${jsonFiles.length} JSON file(s):",
                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey[700]),
                    ),
                    SizedBox(height: 10),
                    Expanded(
                      child: ListView.builder(
                        itemCount: jsonFiles.length,
                        itemBuilder: (context, index) {
                          File file = jsonFiles[index];
                          String fileName = file.path.split('\\').last;
                          String filePath = file.path;
                          
                          // Dosya bilgilerini al
                          FileStat fileStat = file.statSync();
                          String fileSize = "${(fileStat.size / 1024).toStringAsFixed(1)} KB";
                          String lastModified = DateFormat('dd/MM/yyyy HH:mm').format(fileStat.modified);
                          
                          return Card(
                            elevation: 2,
                            margin: EdgeInsets.symmetric(vertical: 4),
                            child: ListTile(
                              leading: Icon(
                                Icons.description,
                                color: Colors.green,
                                size: 30,
                              ),
                              title: Text(
                                fileName,
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text("Size: $fileSize"),
                                  Text("Modified: $lastModified"),
                                  Text(
                                    "Path: $filePath",
                                    style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                              trailing: Icon(Icons.arrow_forward_ios, size: 16),
                              onTap: () async {
                                Navigator.of(context).pop(); // Dialog'u kapat
                                await loadSpecificTaskFile(file); // Dosyayı yükle
                              },
                              hoverColor: Colors.blue.withOpacity(0.1),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text("Cancel"),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop();
                    loadTasksFromFile(); // Eski file picker metodunu çağır
                  },
                  icon: Icon(Icons.file_open),
                  label: Text("Browse Files"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            );
          },
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error reading directory: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Belirli bir JSON dosyasını yükleyen metod
  Future<void> loadSpecificTaskFile(File file) async {
    try {
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
        filteredTasks = tasks;
      });
      
      String fileName = file.path.split('\\').last;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 8),
              Expanded(
                child: Text("Successfully loaded: $fileName\n${tasks.length} task(s) imported"),
              ),
            ],
          ),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error loading file: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Eski loadTasksFromFile metodunu koruyalım (Browse Files butonu için)
  Future<void> loadTasksFromFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );
    if (result != null && result.files.single.path != null) {
      File file = File(result.files.single.path!);
      await loadSpecificTaskFile(file);
    }
  }

  // Gelişmiş kaydetme metodunu da ekleyelim
  Future<void> saveTasksToDirectoryAdvanced() async {
    if (tasks.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("No tasks to save!"),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    String? selectedDirectory = await FilePicker.platform.getDirectoryPath(
      dialogTitle: "Choose save location",
    );
    
    if (selectedDirectory != null) {
      // Dosya adı için dialog göster
      String fileName = await showSaveFileNameDialog() ?? "tasks";
      String timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      String fullFileName = "${fileName}_$timestamp.json";
      
      String jsonString = jsonEncode(tasks);
      String fullPath = '$selectedDirectory/$fullFileName';
      
      try {
        File file = File(fullPath);
        await file.writeAsString(jsonString);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.save, color: Colors.white),
                SizedBox(width: 8),
                Expanded(
                  child: Text("Saved successfully!\n$fullPath\n${tasks.length} task(s) exported"),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 4),
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error saving file: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Dosya adı girme dialog'u
  Future<String?> showSaveFileNameDialog() async {
    TextEditingController fileNameController = TextEditingController(text: "tasks");
    
    return showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Enter File Name"),
          content: TextField(
            controller: fileNameController,
            decoration: InputDecoration(
              labelText: "File Name (without extension)",
              border: OutlineInputBorder(),
              hintText: "e.g., my_tasks, project_tasks",
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                String fileName = fileNameController.text.trim();
                if (fileName.isEmpty) fileName = "tasks";
                Navigator.of(context).pop(fileName);
              },
              child: Text("Save"),
            ),
          ],
        );
      },
    );
  }

  // AppBar'daki butonları güncelleyelim
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Task Manager"),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            tooltip: "Save tasks",
            onPressed: saveTasksToDirectoryAdvanced,
          ),
          IconButton(
            icon: const Icon(Icons.folder_open),
            tooltip: "Load tasks",
            onPressed: showLoadTasksDialog,
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
                        icon: const Icon(Icons.list, color: Colors.white),
                        label: const Text("List View"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: !isTableView ? Colors.blue.shade600 : Colors.grey.shade500,
                          foregroundColor: Colors.white,
                          elevation: !isTableView ? 3 : 1,
                        ),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton.icon(
                        onPressed: () {
                          setState(() {
                            isTableView = true;
                          });
                        },
                        icon: const Icon(Icons.grid_on, color: Colors.white),
                        label: const Text("Table View"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isTableView ? Colors.blue.shade600 : Colors.grey.shade500,
                          foregroundColor: Colors.white,
                          elevation: isTableView ? 3 : 1,
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
                                  title: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        task["title"],
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      if (task["description"] != null && task["description"].toString().isNotEmpty)
                                        Padding(
                                          padding: const EdgeInsets.only(top: 4),
                                          child: Text(
                                            task["description"],
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.grey.shade600,
                                              fontWeight: FontWeight.normal,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const SizedBox(height: 8),
                                      Text(
                                        "Deadline: ${DateFormat('dd/MM/yyyy').format(deadlineDate)} • Effort: ${task['effort']} hour",
                                      ),
                                      if (task["category"] != null && task["category"].toString().isNotEmpty)
                                        Text("Category: ${task["category"]}"),
                                      if (task["priority"] != null && task["priority"].toString().isNotEmpty)
                                        Text("Priority: ${task["priority"]}"),
                                      const SizedBox(height: 8),
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
                                      const SizedBox(height: 4),
                                      Text("$completionPercentage%"),
                                    ],
                                  ),
                                  trailing: IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red),
                                    onPressed: () {
                                      confirmDeleteTask(context, task);
                                    },
                                  ),
                              ));
                            },
                          ),
                  ),
                ],
              );
            },
          ),
          // 2. Tab: Görev Statüleri
          buildStatusTab(),
          // 3. Tab: Reports (YENİ)
          DraggableReportsTab(tasks: tasks),
        ],
      ),
    );
  }

  // Completion color metodu
  Color getCompletionColor() {
    if (completionPercentage == 100) {
      return Colors.green;
    } else if (completionPercentage >= 75) {
      return Colors.blue;
    } else if (completionPercentage >= 50) {
      return Colors.orange;
    } else if (completionPercentage >= 25) {
      return Colors.red;
    } else {
      return Colors.grey;
    }
  }

  // Filter section builder metodu - güncellenmiş (Filter by Date butonunu kaldırdık)
  Widget buildFilterSection() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: DropdownButtonFormField<String>(
              value: selectedFilterColumn.isEmpty ? null : selectedFilterColumn,
              decoration: const InputDecoration(
                labelText: "Filter by",
                border: OutlineInputBorder(),
              ),
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
                  filteredTasks = tasks;
                });
              },
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 3,
            child: TextField(
              controller: filterController,
              decoration: const InputDecoration(
                labelText: "Search value",
                border: OutlineInputBorder(),
                suffixIcon: Icon(Icons.search),
              ),
              onChanged: (value) {
                filterTasks(value);
              },
            ),
          ),
          const SizedBox(width: 10),
          ElevatedButton(
            onPressed: () {
              setState(() {
                selectedFilterColumn = '';
                filterController.clear();
                filteredTasks = tasks;
                filterDate = null;
                filterDateType = ''; // Date filter type'ı da temizle
                selectedCategory = '';
              });
            },
            child: const Text("Clear"),
          ),
        ],
      ),
    );
  }

  // Build draggable data table metodu - güncellenmiş date filter ile
  Widget buildDraggableDataTable() {
    List<String> visibleColumns = columnOrder.where((col) => !hiddenColumns.contains(col)).toList();
    
    return Column(
      children: [
        // Kontrol butonları
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Table View',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              Row(
                children: [
                  // Filter by Date butonu (küçük) - güncellenmiş
                  ElevatedButton.icon(
                    onPressed: _showDateFilterDialog,
                    icon: const Icon(Icons.calendar_today, size: 16),
                    label: Text(
                      _getDateFilterLabel(),
                      style: const TextStyle(fontSize: 12),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: filterDate != null || filterDateType.isNotEmpty
                        ? Colors.orange.shade100 
                        : Colors.grey.shade100,
                      foregroundColor: filterDate != null || filterDateType.isNotEmpty
                        ? Colors.orange.shade700 
                        : Colors.grey.shade700,
                      elevation: 1,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Column Order butonu
                  ElevatedButton.icon(
                    onPressed: _showColumnOrderDialog,
                    icon: const Icon(Icons.view_column, size: 16),
                    label: const Text('Columns', style: TextStyle(fontSize: 12)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade100,
                      foregroundColor: Colors.blue.shade700,
                      elevation: 1,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        
        // Custom Table Header
        Container(
          height: 56,
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              return _buildHeaderRow(visibleColumns, constraints.maxWidth);
            },
          ),
        ),
        
        // Table Body
        Expanded(
          child: SingleChildScrollView(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return Column(
                  children: filteredTasks.map((task) => 
                    _buildCustomDataRow(task, visibleColumns, constraints.maxWidth)
                  ).toList(),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  // Date filter label'ını döndüren metod
  String _getDateFilterLabel() {
    switch (filterDateType) {
      case 'today':
        return 'Today';
      case 'week':
        return 'This Week';
      case 'month':
        return 'This Month';
      case 'custom':
        return filterDate != null 
          ? DateFormat('dd/MM').format(filterDate!)
          : 'Custom';
      default:
        return 'Date';
    }
  }

  // Date filter dialog'u
  void _showDateFilterDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.calendar_today, color: Colors.orange),
              SizedBox(width: 8),
              Text('Filter by Date'),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Today
                _buildDateFilterOption(
                  icon: Icons.today,
                  title: 'Today',
                  subtitle: DateFormat('EEEE, dd MMMM yyyy').format(DateTime.now()),
                  color: Colors.green,
                  isSelected: filterDateType == 'today',
                  onTap: () {
                    Navigator.of(context).pop();
                    _applyDateFilter('today');
                  },
                ),
                const SizedBox(height: 8),
                
                // This Week
                _buildDateFilterOption(
                  icon: Icons.date_range,
                  title: 'This Week',
                  subtitle: _getWeekRange(),
                  color: Colors.blue,
                  isSelected: filterDateType == 'week',
                  onTap: () {
                    Navigator.of(context).pop();
                    _applyDateFilter('week');
                  },
                ),
                const SizedBox(height: 8),
                
                // This Month
                _buildDateFilterOption(
                  icon: Icons.calendar_month,
                  title: 'This Month',
                  subtitle: DateFormat('MMMM yyyy').format(DateTime.now()),
                  color: Colors.purple,
                  isSelected: filterDateType == 'month',
                  onTap: () {
                    Navigator.of(context).pop();
                    _applyDateFilter('month');
                  },
                ),
                const SizedBox(height: 8),
                
                // Custom Date
                _buildDateFilterOption(
                  icon: Icons.edit_calendar,
                  title: 'Custom Date',
                  subtitle: filterDateType == 'custom' && filterDate != null 
                    ? DateFormat('EEEE, dd MMMM yyyy').format(filterDate!)
                    : 'Choose a specific date',
                  color: Colors.orange,
                  isSelected: filterDateType == 'custom',
                  onTap: () async {
                    Navigator.of(context).pop();
                    DateTime? pickedDate = await showDatePicker(
                      context: context,
                      initialDate: filterDate ?? DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2100),
                    );
                    if (pickedDate != null) {
                      _applyDateFilter('custom', customDate: pickedDate);
                    }
                  },
                ),
                
                const SizedBox(height: 16),
                
                // Clear Filter
                if (filterDateType.isNotEmpty || filterDate != null)
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.red.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ListTile(
                      leading: Icon(Icons.clear, color: Colors.red.shade600),
                      title: Text(
                        'Clear Date Filter',
                        style: TextStyle(
                          color: Colors.red.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      subtitle: Text(
                        'Show all tasks',
                        style: TextStyle(color: Colors.red.shade500),
                      ),
                      onTap: () {
                        Navigator.of(context).pop();
                        _clearDateFilter();
                      },
                    ),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  // Date filter option builder
  Widget _buildDateFilterOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isSelected ? color : Colors.grey.shade300,
          width: isSelected ? 2 : 1,
        ),
        color: isSelected ? color.withOpacity(0.1) : Colors.white,
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: isSelected ? color : Colors.black87,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontSize: 12,
            color: isSelected ? color.withOpacity(0.8) : Colors.grey.shade600,
          ),
        ),
        trailing: isSelected 
          ? Icon(Icons.check_circle, color: color)
          : Icon(Icons.chevron_right, color: Colors.grey.shade400),
        onTap: onTap,
      ),
    );
  }

  // Bu haftanın tarih aralığını döndüren metod
  String _getWeekRange() {
    DateTime now = DateTime.now();
    DateTime startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    DateTime endOfWeek = startOfWeek.add(const Duration(days: 6));
    
    return '${DateFormat('dd MMM').format(startOfWeek)} - ${DateFormat('dd MMM').format(endOfWeek)}';
  }

  // Date filter uygulama metodu
  void _applyDateFilter(String type, {DateTime? customDate}) {
    setState(() {
      filterDateType = type;
      
      switch (type) {
        case 'today':
          filterDate = DateTime.now();
          _filterTasksByToday();
          break;
        case 'week':
          filterDate = null;
          _filterTasksByThisWeek();
          break;
        case 'month':
          filterDate = null;
          _filterTasksByThisMonth();
          break;
        case 'custom':
          if (customDate != null) {
            filterDate = customDate;
            _filterTasksByCustomDate(customDate);
          }
          break;
      }
    });
  }

  // Bugünkü görevleri filtreleme
  void _filterTasksByToday() {
    DateTime today = DateTime.now();
    setState(() {
      filteredTasks = tasks.where((task) {
        DateTime taskDate = DateTime.parse(task['deadline']);
        return taskDate.year == today.year &&
               taskDate.month == today.month &&
               taskDate.day == today.day;
      }).toList();
    });
  }

  // Bu haftaki görevleri filtreleme
  void _filterTasksByThisWeek() {
    DateTime now = DateTime.now();
    DateTime startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    DateTime endOfWeek = startOfWeek.add(const Duration(days: 6));
    
    setState(() {
      filteredTasks = tasks.where((task) {
        DateTime taskDate = DateTime.parse(task['deadline']);
        return taskDate.isAfter(startOfWeek.subtract(const Duration(days: 1))) &&
               taskDate.isBefore(endOfWeek.add(const Duration(days: 1)));
      }).toList();
    });
  }

  // Bu ayki görevleri filtreleme
  void _filterTasksByThisMonth() {
    DateTime now = DateTime.now();
    setState(() {
      filteredTasks = tasks.where((task) {
        DateTime taskDate = DateTime.parse(task['deadline']);
        return taskDate.year == now.year && taskDate.month == now.month;
      }).toList();
    });
  }

  // Özel tarihe göre filtreleme
  void _filterTasksByCustomDate(DateTime date) {
    setState(() {
      filteredTasks = tasks.where((task) {
        DateTime taskDate = DateTime.parse(task['deadline']);
        return taskDate.year == date.year &&
               taskDate.month == date.month &&
               taskDate.day == date.day;
      }).toList();
    });
  }

  // Date filter temizleme
  void _clearDateFilter() {
    setState(() {
      filterDateType = '';
      filterDate = null;
      filteredTasks = tasks;
    });
  }

  // Header row builder - sürüklenebilir kenarlar ile
  Widget _buildHeaderRow(List<String> visibleColumns, double availableWidth) {
    // Toplam flex değerini hesapla
    double totalFlex = visibleColumns.fold(0.0, (sum, col) => sum + columnWidths[col]!);
    
    return Row(
      children: visibleColumns.asMap().entries.map((entry) {
        int index = entry.key;
        String columnKey = entry.value;
        
        // Her kolon için genişlik hesapla
        double columnWidth = (columnWidths[columnKey]! / totalFlex) * availableWidth;
        bool isLast = index == visibleColumns.length - 1;
        
        return Row(
          children: [
            // Column header
            Container(
              width: columnWidth - (isLast ? 0 : 8), // Resize handle için yer ayır
              decoration: BoxDecoration(
                border: Border(
                  right: isLast ? BorderSide.none : BorderSide(color: Colors.grey.shade300),
                ),
              ),
              child: InkWell(
                onTap: () {
                  if (columnKey != 'actions') {
                    sortTasks(0, !isAscending, columnKey);
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          columnTitles[columnKey] ?? columnKey,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (columnKey != 'actions')
                        Icon(
                          isAscending ? Icons.arrow_upward : Icons.arrow_downward,
                          size: 16,
                          color: Colors.grey.shade600,
                        ),
                    ],
                  ),
                ),
              ),
            ),
            // Resize handle (son kolon hariç)
            if (!isLast)
              _buildResizeHandle(columnKey, index, visibleColumns),
          ],
        );
      }).toList(),
    );
  }

  // Resize handle builder - gelişmiş minimum genişlik kontrolü ile
  Widget _buildResizeHandle(String columnKey, int columnIndex, List<String> visibleColumns) {
    return MouseRegion(
      cursor: SystemMouseCursors.resizeColumn,
      child: GestureDetector(
        onPanStart: (details) {
          // Başlangıç pozisyonunu kaydet
        },
        onPanUpdate: (details) {
          setState(() {
            // Delta x değerini flex oranına çevir - daha hassas kontrol
            double deltaFlex = details.delta.dx * 0.005; // Daha yavaş değişim
            
            // Minimum genişlik sınırları (kolon tipine göre)
            double minWidth = _getMinimumColumnWidth(columnKey);
            double maxWidth = 8.0;
            
            // Mevcut kolon genişliğini güncelle
            double currentWidth = columnWidths[columnKey]!;
            double newWidth = currentWidth + deltaFlex;
            
            // Sınır kontrolü - daha katı
            if (newWidth >= minWidth && newWidth <= maxWidth) {
              // Eğer bir sonraki kolon varsa, onun da sınırlarını kontrol et
              if (columnIndex < visibleColumns.length - 1) {
                String nextColumnKey = visibleColumns[columnIndex + 1];
                double nextMinWidth = _getMinimumColumnWidth(nextColumnKey);
                double nextCurrentWidth = columnWidths[nextColumnKey]!;
                double nextNewWidth = nextCurrentWidth - deltaFlex;
                
                // Her iki kolon da sınırlar içinde kalacaksa güncelle
                if (nextNewWidth >= nextMinWidth && nextNewWidth <= maxWidth) {
                  columnWidths[columnKey] = newWidth;
                  columnWidths[nextColumnKey] = nextNewWidth;
                }
              } else {
                // Son kolon ise sadece kendi sınırını kontrol et
                columnWidths[columnKey] = newWidth;
              }
            }
          });
        },
        child: Container(
          width: 8,
          height: double.infinity,
          color: Colors.transparent,
          child: Center(
            child: Container(
              width: 3,
              height: 30,
              decoration: BoxDecoration(
                color: Colors.blue.shade300,
                borderRadius: BorderRadius.circular(2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.shade200,
                    blurRadius: 2,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Kolon tipine göre minimum genişlik belirleme
  double _getMinimumColumnWidth(String columnKey) {
    switch (columnKey) {
      case 'title':
        return 1.5; // Task name için daha geniş minimum
      case 'deadline':
        return 1.0; // Tarih için yeterli
      case 'category':
        return 1.0; // Kategori için yeterli
      case 'priority':
        return 0.8; // Priority için dar yeterli
      case 'status':
        return 1.0; // Status için yeterli
      case 'effort':
        return 0.7; // Effort için en dar
      case 'completionPercentage':
        return 1.2; // Progress bar için biraz geniş
      case 'actions':
        return 0.6; // Actions için en minimum
      default:
        return 0.8; // Varsayılan minimum
    }
  }

  // Column order dialog'u - güncellenmiş
  void _showColumnOrderDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        List<String> tempColumnOrder = List.from(columnOrder);
        List<String> tempHiddenColumns = List.from(hiddenColumns);
        Map<String, double> tempColumnWidths = Map.from(columnWidths);
        
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Row(
                children: [
                  Icon(Icons.view_column, color: Colors.blue),
                  SizedBox(width: 8),
                  Text('Column Settings'),
                ],
              ),
              content: SizedBox(
                width: double.maxFinite,
                height: 500,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Column Visibility, Order & Width Ratio:',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: Text(
                        'Width values represent flex ratios. Each column has different minimum widths to ensure readability.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue.shade700,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Kolon listesi - güncellenmiş minimum değerlerle
                    Expanded(
                      child: ListView.builder(
                        itemCount: tempColumnOrder.length,
                        itemBuilder: (context, index) {
                          String columnKey = tempColumnOrder[index];
                          bool isVisible = !tempHiddenColumns.contains(columnKey);
                          double minWidth = _getMinimumColumnWidth(columnKey);
                          
                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 2),
                            elevation: 1,
                            child: ExpansionTile(
                              leading: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 24,
                                    height: 24,
                                    decoration: BoxDecoration(
                                      color: isVisible ? Colors.blue.shade600 : Colors.grey.shade400,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Center(
                                      child: Text(
                                        '${index + 1}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  // Move Up/Down butonları
                                  IconButton(
                                    icon: const Icon(Icons.keyboard_arrow_up, size: 16),
                                    onPressed: index > 0 ? () {
                                      setDialogState(() {
                                        String item = tempColumnOrder.removeAt(index);
                                        tempColumnOrder.insert(index - 1, item);
                                      });
                                    } : null,
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.keyboard_arrow_down, size: 16),
                                    onPressed: index < tempColumnOrder.length - 1 ? () {
                                      setDialogState(() {
                                        String item = tempColumnOrder.removeAt(index);
                                        tempColumnOrder.insert(index + 1, item);
                                      });
                                    } : null,
                                  ),
                                ],
                              ),
                              title: Text(
                                columnTitles[columnKey] ?? columnKey,
                                style: TextStyle(
                                  fontWeight: FontWeight.w500,
                                  color: isVisible ? Colors.black87 : Colors.grey.shade500,
                                  decoration: isVisible ? null : TextDecoration.lineThrough,
                                ),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Checkbox(
                                    value: isVisible,
                                    onChanged: columnKey == 'actions' ? null : (bool? value) {
                                      setDialogState(() {
                                        if (value == true) {
                                          tempHiddenColumns.remove(columnKey);
                                        } else {
                                          tempHiddenColumns.add(columnKey);
                                        }
                                      });
                                    },
                                    activeColor: Colors.blue.shade600,
                                  ),
                                  Text(
                                    isVisible ? 'Show' : 'Hide',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isVisible ? Colors.green.shade600 : Colors.red.shade600,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            'Width Ratio: ${tempColumnWidths[columnKey]!.toStringAsFixed(1)}x',
                                            style: TextStyle(
                                              fontWeight: FontWeight.w600,
                                              color: Colors.grey.shade700,
                                              fontSize: 14,
                                            ),
                                          ),
                                          Text(
                                            'Min: ${minWidth.toStringAsFixed(1)}x',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.red.shade600,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      // Slider for width adjustment - güncellenmiş minimum değerlerle
                                      Slider(
                                        value: tempColumnWidths[columnKey]!,
                                        min: minWidth, // Dinamik minimum değer
                                        max: 5.0,
                                        divisions: ((5.0 - minWidth) * 4).round(), // Dinamik division
                                        label: '${tempColumnWidths[columnKey]!.toStringAsFixed(1)}x',
                                        activeColor: Colors.blue.shade600,
                                        inactiveColor: Colors.blue.shade200,
                                        onChanged: (double value) {
                                          setDialogState(() {
                                            tempColumnWidths[columnKey] = value;
                                          });
                                        },
                                      ),
                                      const SizedBox(height: 8),
                                      // Quick preset buttons - güncellenmiş değerlerle
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                        children: [
                                          _buildPresetButton(
                                            'Min',
                                            minWidth,
                                            Colors.red.shade600,
                                            columnKey,
                                            tempColumnWidths,
                                            setDialogState,
                                          ),
                                          _buildPresetButton(
                                            'Normal',
                                            (minWidth + 1.5) > 5.0 ? 5.0 : (minWidth + 1.5),
                                            Colors.orange.shade600,
                                            columnKey,
                                            tempColumnWidths,
                                            setDialogState,
                                          ),
                                          _buildPresetButton(
                                            'Wide',
                                            (minWidth + 2.5) > 5.0 ? 5.0 : (minWidth + 2.5),
                                            Colors.green.shade600,
                                            columnKey,
                                            tempColumnWidths,
                                            setDialogState,
                                          ),
                                          _buildPresetButton(
                                            'Max',
                                            5.0,
                                            Colors.blue.shade600,
                                            columnKey,
                                            tempColumnWidths,
                                            setDialogState,
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      // Width preview - güncellenmiş bilgi
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: Colors.grey.shade100,
                                          borderRadius: BorderRadius.circular(4),
                                          border: Border.all(color: Colors.grey.shade300),
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(Icons.info_outline, 
                                                 size: 14, 
                                                 color: Colors.grey.shade600),
                                            const SizedBox(width: 6),
                                            Expanded(
                                              child: Text(
                                                'Minimum width prevents content overflow. Drag column borders to resize.',
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  color: Colors.grey.shade600,
                                                  fontStyle: FontStyle.italic,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Bilgi metni - güncellenmiş
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.orange.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.warning_amber_outlined, 
                               size: 16, 
                               color: Colors.orange.shade600),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Each column has a minimum width to ensure readability. You cannot resize below these limits.',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.orange.shade700,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                // Show All butonu
                TextButton.icon(
                  onPressed: () {
                    setDialogState(() {
                      tempHiddenColumns.clear();
                    });
                  },
                  icon: const Icon(Icons.visibility, size: 18),
                  label: const Text('Show All'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.green.shade700,
                  ),
                ),
                // Reset butonu
                TextButton.icon(
                  onPressed: () {
                    setDialogState(() {
                      tempColumnOrder = [
                        'title',
                        'deadline', 
                        'category',
                        'priority',
                        'status',
                        'effort',
                        'completionPercentage',
                        'actions'
                      ];
                      tempHiddenColumns.clear();
                      tempColumnWidths = {
                        'title': 3.0,
                        'deadline': 1.5,
                        'category': 1.5,
                        'priority': 1.0,
                        'status': 1.5,
                        'effort': 1.0,
                        'completionPercentage': 2.0,
                        'actions': 1.0,
                      };
                    });
                  },
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('Reset'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.orange.shade700,
                  ),
                ),
                // Cancel butonu
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                // Apply butonu
                ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      columnOrder = List.from(tempColumnOrder);
                      hiddenColumns = List.from(tempHiddenColumns);
                      columnWidths = Map.from(tempColumnWidths);
                    });
                    Navigator.of(context).pop();
                  },
                  icon: const Icon(Icons.check, size: 18),
                  label: const Text('Apply'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Preset button builder helper metodu
  Widget _buildPresetButton(
    String label,
    double value,
    Color color,
    String columnKey,
    Map<String, double> tempColumnWidths,
    StateSetter setDialogState,
  ) {
    bool isSelected = (tempColumnWidths[columnKey]! - value).abs() < 0.1;
    
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        border: isSelected ? Border.all(color: color, width: 2) : null,
      ),
      child: TextButton(
        onPressed: () {
          setDialogState(() {
            tempColumnWidths[columnKey] = value;
          });
        },
        style: TextButton.styleFrom(
          foregroundColor: color,
          backgroundColor: isSelected ? color.withOpacity(0.1) : Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          minimumSize: const Size(60, 32),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  // Sort tasks metodu
  void sortTasks(int columnIndex, bool ascending, String field) {
    setState(() {
      sortColumnIndex = columnIndex;
      isAscending = ascending;
      
      filteredTasks.sort((a, b) {
        dynamic aValue = a[field];
        dynamic bValue = b[field];
        
        if (field == 'deadline') {
          aValue = DateTime.parse(aValue);
          bValue = DateTime.parse(bValue);
        }
        
        if (ascending) {
          return Comparable.compare(aValue, bValue);
        } else {
          return Comparable.compare(bValue, aValue);
        }
      });
    });
  }

  // Build status tab metodu
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

  // Filter tasks metodu
  void filterTasks(String value) {
    if (selectedFilterColumn.isEmpty || value.isEmpty) {
      setState(() {
        filteredTasks = tasks;
      });
      return;
    }

    setState(() {
      filteredTasks = tasks.where((task) {
        String? taskValue;
        
        switch (selectedFilterColumn) {
          case 'Task Name':
            taskValue = task['title']?.toString().toLowerCase();
            break;
          case 'Category':
            taskValue = task['category']?.toString().toLowerCase();
            break;
          case 'Priority':
            taskValue = task['priority']?.toString().toLowerCase();
            break;
          case 'Status':
            taskValue = task['status']?.toString().toLowerCase();
            break;
          case 'Effort':
            taskValue = task['effort']?.toString();
            break;
          default:
            return false;
        }
        
        return taskValue?.contains(value.toLowerCase()) ?? false;
      }).toList();
    });
  }

  // Filter by date metodu
  void filterTasksByDate(DateTime date) {
    setState(() {
      filterDate = date;
      filteredTasks = tasks.where((task) {
        DateTime taskDate = DateTime.parse(task['deadline']);
        return taskDate.year == date.year &&
               taskDate.month == date.month &&
               taskDate.day == date.day;
      }).toList();
    });
  }

  // Filter by category metodu
  void filterTasksByCategory(String category) {
    setState(() {
      selectedCategory = category;
      if (category.isEmpty) {
        filteredTasks = tasks;
      } else {
        filteredTasks = tasks.where((task) {
          return task['category']?.toString().toLowerCase() == category.toLowerCase();
        }).toList();
      }
    });
  }

  // Custom data row builder - güncellenmiş resize handle ile uyumlu
  Widget _buildCustomDataRow(Map<String, dynamic> task, List<String> visibleColumns, double availableWidth) {
    final deadline = DateTime.parse(task['deadline']);
    final cp = task['completionPercentage'] ?? 0;
    
    // Toplam flex değerini hesapla
    double totalFlex = visibleColumns.fold(0.0, (sum, col) => sum + columnWidths[col]!);
    
    return Container(
      height: 60,
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      child: Row(
        children: visibleColumns.asMap().entries.map((entry) {
          int index = entry.key;
          String columnKey = entry.value;
          
          // Her kolon için genişlik hesapla
          double columnWidth = (columnWidths[columnKey]! / totalFlex) * availableWidth;
          bool isLast = index == visibleColumns.length - 1;
          
          return Row(
            children: [
              // Cell content
              Container(
                width: columnWidth - (isLast ? 0 : 8), // Resize handle için yer ayır
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                decoration: BoxDecoration(
                  border: Border(
                    right: isLast ? BorderSide.none : BorderSide(color: Colors.grey.shade200),
                  ),
                ),
                child: _buildCellContent(columnKey, task, deadline, cp),
              ),
              // Boş alan (resize handle hizalaması için)
              if (!isLast)
                Container(
                  width: 8,
                  height: double.infinity,
                  decoration: BoxDecoration(
                    border: Border(
                      right: BorderSide(color: Colors.grey.shade200),
                    ),
                  ),
                ),
            ],
          );
        }).toList(),
      ),
    );
  }

  // Cell content builder
  Widget _buildCellContent(String columnKey, Map<String, dynamic> task, DateTime deadline, int cp) {
    switch (columnKey) {
      case 'title':
        return InkWell(
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
          child: Tooltip(
            message: task['title'],
            child: Text(
              task['title'],
              style: const TextStyle(
                color: Colors.blue,
                decoration: TextDecoration.underline,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
          ),
        );
      case 'deadline':
        return Text(
          DateFormat('dd/MM/yyyy').format(deadline),
          overflow: TextOverflow.ellipsis,
        );
      case 'category':
        return Tooltip(
          message: task['category'] ?? '',
          child: Text(
            task['category'] ?? '',
            overflow: TextOverflow.ellipsis,
          ),
        );
      case 'priority':
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: task['priority'] == 'High' ? Colors.red.shade100 :
                   task['priority'] == 'Medium' ? Colors.orange.shade100 :
                   Colors.green.shade100,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            task['priority'] ?? '',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: task['priority'] == 'High' ? Colors.red.shade700 :
                     task['priority'] == 'Medium' ? Colors.orange.shade700 :
                     Colors.green.shade700,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        );
      case 'status':
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: task['status'] == 'Complete' ? Colors.green.shade100 :
                   task['status'] == 'In Progress' ? Colors.blue.shade100 :
                   Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            task['status'] ?? '',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: task['status'] == 'Complete' ? Colors.green.shade700 :
                     task['status'] == 'In Progress' ? Colors.blue.shade700 :
                     Colors.grey.shade700,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        );
      case 'effort':
        return Text(
          '${task['effort']}h',
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
        );
      case 'completionPercentage':
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            LinearProgressIndicator(
              value: cp / 100,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(
                cp == 0 ? Colors.grey :
                cp <= 25 ? Colors.red :
                cp <= 50 ? Colors.orange :
                cp <= 75 ? Colors.blue : Colors.green,
              ),
              minHeight: 6,
            ),
            const SizedBox(height: 4),
            Text(
              "$cp%",
              style: const TextStyle(fontSize: 12),
            ),
          ],
        );
      case 'actions':
        return Center(
          child: IconButton(
            icon: const Icon(Icons.delete, color: Colors.red, size: 20),
            onPressed: () {
              confirmDeleteTask(context, task);
            },
          ),
        );
      default:
        return Text(
          task[columnKey]?.toString() ?? '',
          overflow: TextOverflow.ellipsis,
        );
    }
  }
}

