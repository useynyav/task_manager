import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/draggablereport.dart';
import 'package:flutter_application_1/screens/task_detail_screen.dart';
import 'package:flutter_application_1/detail_view_screen.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const TaskManagerApp());
}

class TaskManagerApp extends StatelessWidget {
  const TaskManagerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Task Manager',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const TaskManagerScreen(),
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
  String selectedStatus = "Not Started"; // Eksik olan değişken

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

  // Eksik olan değişkenler
  String? lastLoadedFilePath;
  bool isLoadingLastFile = false;
  bool isDetailView = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadSampleData(); // Sample data yükle
    categorizeTasksByStatus(); // Kategorize et
    sortTasksByDeadline(ascending: isAscending); // Sort et
    _loadLastFileOnStartup(); // Son dosyayı yükle
  }

  @override
  void dispose() {
    _tabController.dispose();
    taskController.dispose();
    effortController.dispose();
    descriptionController.dispose();
    categoryController.dispose();
    filterController.dispose();
    super.dispose();
  }

  // Sample data yükleme
  void _loadSampleData() {
    setState(() {
      tasks = [
        {
          "title": "Complete Flutter UI",
          "deadline": "2024-01-15",
          "category": "Development",
          "priority": "High",
          "status": "In Progress",
          "effort": 8,
          "completionPercentage": 75,
          "description": "Complete the user interface design"
        },
        {
          "title": "Review Code",
          "deadline": "2024-01-10",
          "category": "Quality Assurance",
          "priority": "Medium",
          "status": "Not Started",
          "effort": 3,
          "completionPercentage": 0,
          "description": "Review the codebase for bugs"
        },
        {
          "title": "Write Documentation",
          "deadline": "2024-01-20",
          "category": "Documentation",
          "priority": "Low",
          "status": "Complete",
          "effort": 5,
          "completionPercentage": 100,
          "description": "Write comprehensive documentation"
        },
      ];
      filteredTasks = List.from(tasks);
    });
  }

  // Kategorize tasks metodu
  void categorizeTasksByStatus() {
    setState(() {
      categorizedTasks = {
        "Not Started": [],
        "In Progress": [],
        "Complete": [],
      };
      for (var task in tasks) {
        String status = task["status"];
        categorizedTasks[status]?.add(task);
      }
    });
  }

  // Uygulama başladığında son dosyayı yükleme
  Future<void> _loadLastFileOnStartup() async {
    setState(() {
      isLoadingLastFile = true;
    });

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? savedFilePath = prefs.getString('last_loaded_file');
      
      if (savedFilePath != null && savedFilePath.isNotEmpty) {
        File file = File(savedFilePath);
        
        // Dosya hala var mı kontrol et
        if (await file.exists()) {
          await loadSpecificTaskFile(file, saveToPrefs: false); // Tekrar kaydetme
          lastLoadedFilePath = savedFilePath;
          
          // Başarılı yükleme mesajı göster
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.history, color: Colors.white),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "Auto-loaded: ${file.path.split('\\').last}\n${tasks.length} task(s) loaded",
                      ),
                    ),
                  ],
                ),
                backgroundColor: Colors.blue,
                duration: const Duration(seconds: 3),
                action: SnackBarAction(
                  label: 'Close',
                  textColor: Colors.white,
                  onPressed: () {},
                ),
              ),
            );
          }
        } else {
          // Dosya artık yok, preferences'i temizle
          await prefs.remove('last_loaded_file');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text("Previously loaded file no longer exists"),
                backgroundColor: Colors.orange,
                action: SnackBarAction(
                  label: 'Load New',
                  onPressed: () => showLoadTasksDialog(),
                ),
              ),
            );
          }
        }
      }
    } catch (e) {
      print('Error loading last file: $e');
    } finally {
      setState(() {
        isLoadingLastFile = false;
      });
    }
  }

  // Dosya yolunu preferences'e kaydetme
  Future<void> _saveLastLoadedFile(String filePath) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('last_loaded_file', filePath);
      lastLoadedFilePath = filePath;
    } catch (e) {
      print('Error saving last loaded file: $e');
    }
  }

  // Son dosya bilgisini temizleme
  Future<void> _clearLastLoadedFile() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.remove('last_loaded_file');
      lastLoadedFilePath = null;
    } catch (e) {
      print('Error clearing last loaded file: $e');
    }
  }

  // Belirli bir JSON dosyasını yükleyen metod - güncellenmiş
  Future<void> loadSpecificTaskFile(File file, {bool saveToPrefs = true}) async {
    try {
      String contents = await file.readAsString();
      dynamic jsonData = jsonDecode(contents);
      
      setState(() {
        // Eski format kontrolü (sadece task array)
        if (jsonData is List) {
          // Eski format - sadece task'ları yükle
          tasks = jsonData.map((task) => Map<String, dynamic>.from(task)).toList();
          _resetColumnSettingsToDefault();
        } else if (jsonData is Map<String, dynamic>) {
          // Yeni format - hem task'ları hem column settings'i yükle
          if (jsonData.containsKey('tasks')) {
            tasks = (jsonData['tasks'] as List)
                .map((task) => Map<String, dynamic>.from(task))
                .toList();
          } else {
            // Map ama 'tasks' anahtarı yok - belki eski farklı format
            tasks = [];
          }
          
          // Column settings'i yükle (varsa)
          if (jsonData.containsKey('columnSettings')) {
            _loadColumnSettings(jsonData['columnSettings']);
          } else {
            _resetColumnSettingsToDefault();
          }
        }
        
        // Kategorize tasks
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
        filteredTasks = List.from(tasks);
      });
      
      // Dosya yolunu kaydet (eğer saveToPrefs true ise)
      if (saveToPrefs) {
        await _saveLastLoadedFile(file.path);
      }
      
      String fileName = file.path.split('\\').last;
      if (mounted && saveToPrefs) { // Auto-load sırasında mesaj gösterme
        bool hasColumnSettings = jsonData is Map<String, dynamic> && 
                                jsonData.containsKey('columnSettings');
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "Successfully loaded: $fileName\n${tasks.length} task(s) imported"
                    "${hasColumnSettings ? ' + column settings restored' : ''}"
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error loading file: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Son dosyayı yeniden yükleme metodu
  Future<void> _reloadLastFile() async {
    if (lastLoadedFilePath != null) {
      File file = File(lastLoadedFilePath!);
      if (await file.exists()) {
        await loadSpecificTaskFile(file, saveToPrefs: false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.refresh, color: Colors.white),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text("Reloaded: ${file.path.split('\\').last}"),
                  ),
                ],
              ),
              backgroundColor: Colors.blue,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } else {
        await _clearLastLoadedFile();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Last loaded file no longer exists"),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("No previously loaded file found"),
            backgroundColor: Colors.grey,
          ),
        );
      }
    }
  }

  // Görev ekleme metodunu güncelle - ekleme sonrası son dosyayı güncelle
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
      filteredTasks = List.from(tasks);
    });
    
    // Eğer son yüklenen dosya varsa, değişiklik yapıldığını göster
    _markFileAsModified();
  }

  // Dosya değiştirildi işareti
  void _markFileAsModified() {
    // Bu metod, dosyanın değiştirildiğini belirtmek için kullanılabilir
    // İleride auto-save özelliği eklenirse buraya yazılabilir
  }

  // Sort tasks by deadline
  void sortTasksByDeadline({bool ascending = true}) {
    tasks.sort((a, b) {
      DateTime dateA = DateTime.parse(a['deadline']);
      DateTime dateB = DateTime.parse(b['deadline']);
      return ascending ? dateA.compareTo(dateB) : dateB.compareTo(dateA);
    });
  }

  // Move task between statuses
  void moveTask(String fromStatus, String toStatus, Map<String, dynamic> task) {
    setState(() {
      categorizedTasks[fromStatus]!.remove(task);
      categorizedTasks[toStatus]!.add(task);
      task["status"] = toStatus;
    });
  }

  // Delete task
  void deleteTask(Map<String, dynamic> task) {
    setState(() {
      tasks.remove(task);
      categorizedTasks[task["status"]]!.remove(task);
      filteredTasks = List.from(tasks);
    });
  }

  // Confirm delete task
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

  // Show add task dialog
  void showAddTaskDialog() {
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
        String errorMessage = "";

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
                    if (taskController.text.isEmpty ||
                        selectedDeadline == null ||
                        effortController.text.isEmpty ||
                        categoryController.text.isEmpty) {
                      
                      setDialogState(() {
                        errorMessage = "Please fill in all fields!";
                      });
                      return;
                    }

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

  // Show load tasks dialog
  Future<void> showLoadTasksDialog() async {
    String? selectedDirectory = await FilePicker.platform.getDirectoryPath(
      dialogTitle: "Choose folder containing JSON files",
    );
    
    if (selectedDirectory != null) {
      try {
        Directory directory = Directory(selectedDirectory);
        List<FileSystemEntity> files = directory.listSync();
        
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
                                Navigator.of(context).pop();
                                await loadSpecificTaskFile(file);
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
                    loadTasksFromFile();
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

  // Load tasks from file
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

  // Save tasks to directory - güncellenmiş (column settings dahil)
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
      String fileName = await showSaveFileNameDialog() ?? "tasks";
      String timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      String fullFileName = "${fileName}_$timestamp.json";
      
      // Task data ile birlikte column settings'i de kaydet
      Map<String, dynamic> saveData = {
        'tasks': tasks,
        'columnSettings': {
          'columnOrder': columnOrder,
          'hiddenColumns': hiddenColumns,
          'columnWidths': columnWidths,
          'savedAt': DateTime.now().toIso8601String(),
          'version': '1.0',
        }
      };
      
      String jsonString = jsonEncode(saveData);
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
                  child: Text("Saved successfully!\n$fullPath\n${tasks.length} task(s) + column settings exported"),
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

  // Show save file name dialog
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

  // Save options dialog
  void _showSaveOptionsDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.save, color: Colors.blue),
              SizedBox(width: 8),
              Text('Save Options'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.update, color: Colors.green),
                title: const Text('Update Current File'),
                subtitle: Text(
                  'Save to: ${lastLoadedFilePath!.split('\\').last}',
                  style: const TextStyle(fontSize: 12),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _saveToCurrentFile();
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.save_as, color: Colors.blue),
                title: const Text('Save As New File'),
                subtitle: const Text('Choose new location and name'),
                onTap: () {
                  Navigator.pop(context);
                  saveTasksToDirectoryAdvanced();
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  // Save to current file - güncellenmiş (column settings dahil)
  Future<void> _saveToCurrentFile() async {
    if (lastLoadedFilePath == null) return;
    
    try {
      // Task data ile birlikte column settings'i de kaydet
      Map<String, dynamic> saveData = {
        'tasks': tasks,
        'columnSettings': {
          'columnOrder': columnOrder,
          'hiddenColumns': hiddenColumns,
          'columnWidths': columnWidths,
          'savedAt': DateTime.now().toIso8601String(),
          'version': '1.0',
        }
      };
      
      String jsonString = jsonEncode(saveData);
      File file = File(lastLoadedFilePath!);
      await file.writeAsString(jsonString);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "Updated: ${file.path.split('\\').last}\n${tasks.length} task(s) + column settings saved",
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error saving file: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Dosya bilgilerini yükleme metodu - güncellenmiş
  void _showFileInfoDialog() {
    if (lastLoadedFilePath == null) return;
    
    File file = File(lastLoadedFilePath!);
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return FutureBuilder<FileStat>(
          future: file.stat(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const AlertDialog(
                title: Text('File Info'),
                content: CircularProgressIndicator(),
              );
            }
            
            FileStat fileStat = snapshot.data!;
            String fileSize = "${(fileStat.size / 1024).toStringAsFixed(1)} KB";
            String lastModified = DateFormat('dd/MM/yyyy HH:mm:ss').format(fileStat.modified);
            String lastAccessed = DateFormat('dd/MM/yyyy HH:mm:ss').format(fileStat.accessed);
            
            // Column settings info
            bool hasCustomColumnSettings = !_isDefaultColumnSettings();
            
            return AlertDialog(
              title: const Row(
                children: [
                  Icon(Icons.info, color: Colors.blue),
                  SizedBox(width: 8),
                  Text('File Information'),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoRow('Name:', file.path.split('\\').last),
                  _buildInfoRow('Path:', file.path),
                  _buildInfoRow('Size:', fileSize),
                  _buildInfoRow('Tasks:', '${tasks.length}'),
                  _buildInfoRow('Hidden Columns:', '${hiddenColumns.length}'),
                  _buildInfoRow('Custom Settings:', hasCustomColumnSettings ? 'Yes' : 'No'),
                  _buildInfoRow('Last Modified:', lastModified),
                  _buildInfoRow('Last Accessed:', lastAccessed),
                ],
              ),
              actions: [
                if (hasCustomColumnSettings)
                  TextButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _showResetColumnSettingsDialog();
                    },
                    icon: const Icon(Icons.refresh, size: 18),
                    label: const Text('Reset Columns'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.orange.shade700,
                    ),
                  ),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _reloadLastFile();
                  },
                  child: const Text('Reload'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Varsayılan column settings olup olmadığını kontrol eden metod
  bool _isDefaultColumnSettings() {
    List<String> defaultOrder = [
      'title', 'deadline', 'category', 'priority', 
      'status', 'effort', 'completionPercentage', 'actions'
    ];
    
    Map<String, double> defaultWidths = {
      'title': 3.0, 'deadline': 1.5, 'category': 1.5, 'priority': 1.0,
      'status': 1.5, 'effort': 1.0, 'completionPercentage': 2.0, 'actions': 1.0,
    };
    
    return columnOrder.toString() == defaultOrder.toString() &&
           hiddenColumns.isEmpty &&
           columnWidths.toString() == defaultWidths.toString();
  }

  // Column settings sıfırlama dialog'u
  void _showResetColumnSettingsDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.refresh, color: Colors.orange),
              SizedBox(width: 8),
              Text('Reset Column Settings'),
            ],
          ),
          content: const Text(
            'This will reset all column settings (order, visibility, and widths) to default values. '
            'Your tasks will not be affected.\n\n'
            'Do you want to continue?'
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                setState(() {
                  _resetColumnSettingsToDefault();
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.white),
                        SizedBox(width: 8),
                        Text('Column settings reset to default'),
                      ],
                    ),
                    backgroundColor: Colors.green,
                    duration: Duration(seconds: 2),
                  ),
                );
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Reset'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        );
      },
    );
  }

  // Info row builder helper
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  // Control button builder - tutarlı buton tasarımı için
  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required bool isSelected,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      height: 48, // Sabit yükseklik
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(
          icon,
          size: 18,
          color: isSelected ? Colors.white : color,
        ),
        label: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: isSelected ? Colors.white : color,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: isSelected ? color : Colors.white,
          foregroundColor: isSelected ? Colors.white : color,
          elevation: isSelected ? 3 : 1,
          shadowColor: color.withOpacity(0.3),
          side: BorderSide(
            color: isSelected ? color : color.withOpacity(0.3),
            width: 1.5,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Text("Task Manager"),
            if (lastLoadedFilePath != null)
              Expanded(
                child: Container(
                  margin: const EdgeInsets.only(left: 16),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade100,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue.shade300),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.description, 
                           size: 14, 
                           color: Colors.blue.shade700),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          lastLoadedFilePath!.split('\\').last,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.blue.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
        actions: [
          // Reload last file butonu
          if (lastLoadedFilePath != null)
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: "Reload current file",
              onPressed: _reloadLastFile,
            ),
          
          // Save tasks butonu
          IconButton(
            icon: const Icon(Icons.save),
            tooltip: "Save tasks",
            onPressed: () async {
              // Eğer son dosya varsa, direkt oraya kaydet seçeneği sun
              if (lastLoadedFilePath != null) {
                _showSaveOptionsDialog();
              } else {
                saveTasksToDirectoryAdvanced();
              }
            },
          ),
          
          // Load tasks butonu
          IconButton(
            icon: const Icon(Icons.folder_open),
            tooltip: "Load tasks",
            onPressed: showLoadTasksDialog,
          ),
          
          // Clear current file butonu
          if (lastLoadedFilePath != null)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              onSelected: (value) async {
                switch (value) {
                  case 'clear_file':
                    await _clearLastLoadedFile();
                    setState(() {
                      tasks.clear();
                      filteredTasks.clear();
                      categorizedTasks = {
                        "Not Started": [],
                        "In Progress": [],
                        "Complete": [],
                      };
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Cleared current file and tasks"),
                        backgroundColor: Colors.orange,
                      ),
                    );
                    break;
                  case 'file_info':
                    _showFileInfoDialog();
                    break;
                }
              },
              itemBuilder: (BuildContext context) => [
                const PopupMenuItem<String>(
                  value: 'file_info',
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, size: 18),
                      SizedBox(width: 8),
                      Text('File Info'),
                    ],
                  ),
                ),
                const PopupMenuItem<String>(
                  value: 'clear_file',
                  child: Row(
                    children: [
                      Icon(Icons.clear, size: 18, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Clear File', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (isLoadingLastFile)
                    const SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  else
                    const Icon(Icons.list, size: 18),
                  const SizedBox(width: 4),
                  const Text("Task List"),
                ],
              ),
            ),
            const Tab(text: "Status"),
            const Tab(text: "Reports"),
          ],
        ),
      ),
      body: isLoadingLastFile
        ? const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text("Loading last file..."),
              ],
            ),
          )
        : TabBarView(
            controller: _tabController,
            children: [
              // 1. Tab: Görev Listesi
              LayoutBuilder(
                builder: (context, constraints) {
                  return Column(
                    children: [
                      // Header Section
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
                      
                      // Filter Section
                      buildFilterSection(),
                      
                      // Button Control Panel - YENİ DÜZENLİ ALAN
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade200),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.shade200,
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            // Buton grubu
                            Row(
                              children: [
                                // List View / Table View / Detail View Toggle Buttons
                                Expanded(
                                  flex: 3,
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: _buildControlButton(
                                          icon: Icons.list,
                                          label: "List",
                                          isSelected: !isTableView && !isDetailView,
                                          color: Colors.blue,
                                          onPressed: () {
                                            setState(() {
                                              isTableView = false;
                                              isDetailView = false;
                                            });
                                          },
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: _buildControlButton(
                                          icon: Icons.grid_on,
                                          label: "Table",
                                          isSelected: isTableView,
                                          color: Colors.blue,
                                          onPressed: () {
                                            setState(() {
                                              isTableView = true;
                                              isDetailView = false;
                                            });
                                          },
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: _buildControlButton(
                                          icon: Icons.view_sidebar,
                                          label: "Detail",
                                          isSelected: isDetailView,
                                          color: Colors.blue,
                                          onPressed: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) => DetailViewScreen(tasks: tasks),
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                
                                const SizedBox(width: 12),
                                
                                // Date Filter Button
                                Expanded(
                                  child: _buildControlButton(
                                    icon: Icons.calendar_today,
                                    label: _getDateFilterLabel(),
                                    isSelected: filterDate != null || filterDateType.isNotEmpty,
                                    color: Colors.orange,
                                    onPressed: _showDateFilterDialog,
                                  ),
                                ),
                                
                                const SizedBox(width: 6),
                                
                                // Columns Button (sadece table view'da görünür)
                                if (isTableView)
                                  Expanded(
                                    child: _buildControlButton(
                                      icon: Icons.view_column,
                                      label: "Columns",
                                      isSelected: false,
                                      color: Colors.purple,
                                      onPressed: _showColumnOrderDialog,
                                    ),
                                  ),
                                
                                // Eğer table view değilse, boş alan bırak
                                if (!isTableView)
                                  const Expanded(child: SizedBox()),
                              ],
                            ),
                          ],
                        ),
                      ),
                      
                      // Content Area
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
                                        ).then((result) {
                                          if (result != null && result is Map<String, dynamic>) {
                                            _handleTaskEditResult(result, task);
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
                  filteredTasks = List.from(tasks);
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
                filteredTasks = List.from(tasks);
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
        // Kontrol butonları kaldırıldı - artık yukarıdaki panel'de
      
        // Custom Table Header
        Container(
          height: 56,
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(8),
              topRight: Radius.circular(8),
            ),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              return _buildHeaderRow(visibleColumns, constraints.maxWidth);
            },
          ),
        ),
        
        // Table Body
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(8),
                bottomRight: Radius.circular(8),
              ),
            ),
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
      filteredTasks = List.from(tasks);
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
                                ],
                              ),
                              title: Text(
                                columnTitles[columnKey] ?? columnKey,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                                overflow: TextOverflow.ellipsis,
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
                               size:  16, 
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
                                   )   );
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
    ));
  }

  // Cell content builder
  Widget _buildCellContent(String columnKey, Map<String, dynamic> task, DateTime deadline, int cp) {
    switch (columnKey) {
      case 'title':
        return Tooltip(
          message: task['title'],
          child: Text(
            task['title'],
            overflow: TextOverflow.ellipsis,
            maxLines: 2,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
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
                cp <= 75 ? Colors.blue :
                Colors.green,
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
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Edit butonu
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.blue, size: 18),
              tooltip: 'Edit Task',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => TaskDetailScreen(task: task),
                  ),
                ).then((result) {
                  if (result != null && result is Map<String, dynamic>) {
                    _handleTaskEditResult(result, task);
                  }
                });
              },
            ),
            const SizedBox(width: 4),
            // Delete butonu
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red, size: 18),
              tooltip: 'Delete Task',
              onPressed: () {
                confirmDeleteTask(context, task);
              },
            ),
          ],
        );
      default:
        return Text(
          task[columnKey]?.toString() ?? '',
          overflow: TextOverflow.ellipsis,
        );
    }
  }

// Eksik olan metodları ekleyin (class'ın sonuna ekleyin):

// Column settings yükleme metodu
void _loadColumnSettings(Map<String, dynamic> columnSettings) {
  try {
    // Column order
    if (columnSettings.containsKey('columnOrder')) {
      List<dynamic> orderList = columnSettings['columnOrder'];
      columnOrder = orderList.cast<String>();
      
      // Mevcut sütunlarla uyumluluğu kontrol et
      List<String> validColumns = [
        'title', 'deadline', 'category', 'priority', 
        'status', 'effort', 'completionPercentage', 'actions'
      ];
      
      // Eksik sütunları ekle
      for (String col in validColumns) {
        if (!columnOrder.contains(col)) {
          columnOrder.add(col);
        }
      }
      
      // Geçersiz sütunları kaldır
      columnOrder.removeWhere((col) => !validColumns.contains(col));
    }
    
    // Hidden columns
    if (columnSettings.containsKey('hiddenColumns')) {
      List<dynamic> hiddenList = columnSettings['hiddenColumns'];
      hiddenColumns = hiddenList.cast<String>();
      
      // Actions sütununun gizlenememesi için kontrol
      hiddenColumns.remove('actions');
    }
    
    // Column widths
    if (columnSettings.containsKey('columnWidths')) {
      Map<String, dynamic> widthsMap = columnSettings['columnWidths'];
      columnWidths = widthsMap.map((key, value) => 
          MapEntry(key, (value as num).toDouble()));
      
      // Eksik sütun genişliklerini varsayılan değerlerle doldur
      Map<String, double> defaultWidths = {
        'title': 3.0,
        'deadline': 1.5,
        'category': 1.5,
        'priority': 1.0,
        'status': 1.5,
        'effort': 1.0,
        'completionPercentage': 2.0,
        'actions': 1.0,
      };
      
      for (String key in defaultWidths.keys) {
        if (!columnWidths.containsKey(key)) {
          columnWidths[key] = defaultWidths[key]!;
        }
      }
      
      // Minimum genişlik kontrolü
      for (String key in columnWidths.keys) {
        double minWidth = _getMinimumColumnWidth(key);
        if (columnWidths[key]! < minWidth) {
          columnWidths[key] = minWidth;
        }
      }
    }
    
    print('Column settings loaded successfully');
  } catch (e) {
    print('Error loading column settings: $e');
    _resetColumnSettingsToDefault();
  }
}

// Column settings'i varsayılan değerlere sıfırlama metodu
void _resetColumnSettingsToDefault() {
  columnOrder = [
    'title',
    'deadline', 
    'category',
    'priority',
    'status',
    'effort',
    'completionPercentage',
    'actions'
  ];
  
  hiddenColumns = [];
  
  columnWidths = {
    'title': 3.0,
    'deadline': 1.5,
    'category': 1.5,
    'priority': 1.0,
    'status': 1.5,
    'effort': 1.0,
    'completionPercentage': 2.0,
    'actions': 1.0,
  };
}


// Class'ın sonuna bu metodu ekleyin:

// Task edit result'ını işleyen ortak metod
void _handleTaskEditResult(Map<String, dynamic> result, Map<String, dynamic>? originalTask) {
  String action = result['action'];
  Map<String, dynamic> taskData = result['task'];
  
  setState(() {
    if (action == 'update') {
      // Mevcut task'ı güncelle
      int taskIndex = -1;
      
      if (originalTask != null) {
        // Orijinal task referansı varsa onu kullan
        taskIndex = tasks.indexOf(originalTask);
      } else {
        // Yoksa title ile ara (detail view'dan geliyorsa)
        taskIndex = tasks.indexWhere((t) => t['title'] == taskData['title']);
      }
      
      if (taskIndex != -1) {
        tasks[taskIndex] = taskData;
        
        // Categorized tasks'ı da güncelle
        categorizedTasks = {
          "Not Started": [],
          "In Progress": [],
          "Complete": [],
        };
        for (var t in tasks) {
          String status = t["status"];
          categorizedTasks[status]?.add(t);
        }
        
        sortTasksByDeadline(ascending: isAscending);
        
        // Filtreleri yeniden uygula
        if (filterDate != null) {
          filterTasksByDate(filterDate!);
        } else if (selectedCategory.isNotEmpty) {
          filterTasksByCategory(selectedCategory);
        } else {
          filteredTasks = List.from(tasks);
        }
      }
    } else if (action == 'create') {
      // Yeni task oluştur
      tasks.add(taskData);
      categorizedTasks[taskData["status"]]?.add(taskData);
      sortTasksByDeadline(ascending: isAscending);
      
      // Filtreleri yeniden uygula
      if (filterDate != null) {
        filterTasksByDate(filterDate!);
      } else if (selectedCategory.isNotEmpty) {
        filterTasksByCategory(selectedCategory);
      } else {
        filteredTasks = List.from(tasks);
      }
    } else if (action == 'delete') {
      // Task'ı sil
      tasks.removeWhere((t) => t == taskData);
      
      // Categorized tasks'ı da güncelle
      categorizedTasks = {
        "Not Started": [],
        "In Progress": [],
        "Complete": [],
      };
      for (var t in tasks) {
        String status = t["status"];
        categorizedTasks[status]?.add(t);
      }
      
      sortTasksByDeadline(ascending: isAscending);
      
      // Filtreleri yeniden uygula
      if (filterDate != null) {
        filterTasksByDate(filterDate!);
      } else if (selectedCategory.isNotEmpty) {
        filterTasksByCategory(selectedCategory);
      } else {
        filteredTasks = List.from(tasks);
      }
    }
  });
  
  // Dosya değiştirildi işareti
  _markFileAsModified();
  
  // Başarı mesajı
  if (mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              action == 'delete' ? Icons.delete : Icons.check_circle,
              color: Colors.white,
            ),
            const SizedBox(width: 8),
            Text(
              action == 'update' ? 'Task updated successfully!' :
              action == 'create' ? 'New task created successfully!' :
              'Task deleted successfully!',
            ),
          ],
        ),
        backgroundColor: action == 'delete' ? Colors.red : Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
}

