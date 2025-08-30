import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';

class TaskDetailScreen extends StatefulWidget {
  final Map<String, dynamic>? task;
  const TaskDetailScreen({super.key, this.task});

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
  final List<String> priorities = ["High", "Medium", "Low"];

  bool get isEditMode => widget.task != null;

  @override
  void initState() {
    super.initState();
    if (isEditMode) {
      // Edit mode - mevcut task verilerini doldur
      titleController = TextEditingController(text: widget.task!["title"]);
      effortController = TextEditingController(text: widget.task!["effort"].toString());
      descriptionController = TextEditingController(text: widget.task!["description"]);
      categoryController = TextEditingController(text: widget.task!["category"]);
      selectedDeadline = DateTime.parse(widget.task!["deadline"]);
      selectedPriority = widget.task!["priority"] ?? "Medium";
      selectedStatus = widget.task!["status"] ?? "Not Started";
      completionPercentage = widget.task!["completionPercentage"] ?? 0;
    } else {
      // Create mode - boş değerler
      titleController = TextEditingController();
      effortController = TextEditingController();
      descriptionController = TextEditingController();
      categoryController = TextEditingController();
      selectedStatus = "Not Started";
      completionPercentage = 0;
    }
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
    if (completionPercentage >= 100) return Colors.green;
    if (completionPercentage >= 75) return Colors.blue;
    if (completionPercentage >= 50) return Colors.orange;
    if (completionPercentage >= 25) return Colors.red;
    return Colors.grey;
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

  void saveChanges() {
    if (titleController.text.isEmpty || 
        selectedDeadline == null || 
        effortController.text.isEmpty || 
        categoryController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please fill in all required fields!"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    Map<String, dynamic> taskData = {
      "title": titleController.text,
      "effort": int.tryParse(effortController.text) ?? 0,
      "description": descriptionController.text,
      "category": categoryController.text,
      "priority": selectedPriority,
      "status": selectedStatus,
      "completionPercentage": completionPercentage,
      "deadline": selectedDeadline!.toIso8601String(),
    };

    Navigator.pop(context, {
      'action': 'update',
      'task': taskData,
    });
  }

  void saveAsNew() {
    if (titleController.text.isEmpty || 
        selectedDeadline == null || 
        effortController.text.isEmpty || 
        categoryController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please fill in all required fields!"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Title değiştirme dialog'u
    showDialog(
      context: context,
      builder: (context) {
        TextEditingController newTitleController = TextEditingController(text: titleController.text + " (Copy)");
        return AlertDialog(
          title: const Text("Save as New Task"),
          content: TextField(
            controller: newTitleController,
            decoration: const InputDecoration(
              labelText: "New Task Title",
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                
                Map<String, dynamic> taskData = {
                  "title": newTitleController.text,
                  "effort": int.tryParse(effortController.text) ?? 0,
                  "description": descriptionController.text,
                  "category": categoryController.text,
                  "priority": selectedPriority,
                  "status": selectedStatus,
                  "completionPercentage": completionPercentage,
                  "deadline": selectedDeadline!.toIso8601String(),
                };

                Navigator.pop(context, {
                  'action': 'create',
                  'task': taskData,
                });
              },
              child: const Text("Save"),
            ),
          ],
        );
      },
    );
  }

  void cancelChanges() {
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(isEditMode ? "Edit Task" : "New Task"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              // Header Card
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title Field
                      _buildSectionHeader("Task Title", Icons.edit, Colors.blue),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: titleController,
                        decoration: InputDecoration(
                          hintText: "Enter task title",
                          prefixIcon: const Icon(Icons.task_alt),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Description Field
                      _buildSectionHeader("Description", Icons.description, Colors.green),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: descriptionController,
                        decoration: InputDecoration(
                          hintText: "Enter task description",
                          prefixIcon: const Icon(Icons.notes),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                        ),
                        maxLines: 2,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Details Card
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      // Row 1: Category + Effort
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildSectionHeader("Category", Icons.category, Colors.purple),
                                const SizedBox(height: 8),
                                TextFormField(
                                  controller: categoryController,
                                  decoration: InputDecoration(
                                    hintText: "Category",
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    filled: true,
                                    fillColor: Colors.grey.shade50,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildSectionHeader("Effort (hours)", Icons.timer, Colors.orange),
                                const SizedBox(height: 8),
                                TextFormField(
                                  controller: effortController,
                                  decoration: InputDecoration(
                                    hintText: "Hours",
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    filled: true,
                                    fillColor: Colors.grey.shade50,
                                  ),
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // Row 2: Priority + Status
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildSectionHeader("Priority", Icons.flag, Colors.red),
                                const SizedBox(height: 8),
                                DropdownButtonFormField<String>(
                                  value: selectedPriority,
                                  decoration: InputDecoration(
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    filled: true,
                                    fillColor: Colors.grey.shade50,
                                  ),
                                  items: priorities.map((String priority) {
                                    return DropdownMenuItem<String>(
                                      value: priority,
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.circle,
                                            size: 12,
                                            color: priority == "High" ? Colors.red :
                                                   priority == "Medium" ? Colors.orange : Colors.green,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(priority),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: (String? newValue) {
                                    setState(() {
                                      selectedPriority = newValue!;
                                    });
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildSectionHeader("Status", Icons.track_changes, Colors.teal),
                                const SizedBox(height: 8),
                                DropdownButtonFormField<String>(
                                  value: selectedStatus,
                                  decoration: InputDecoration(
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    filled: true,
                                    fillColor: Colors.grey.shade50,
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
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Deadline & Progress Card
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      // Deadline Section
                      _buildSectionHeader("Deadline", Icons.calendar_today, Colors.indigo),
                      const SizedBox(height: 12),
                      InkWell(
                        onTap: pickDeadline,
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(8),
                            color: Colors.grey.shade50,
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.event, color: Colors.indigo),
                              const SizedBox(width: 12),
                              Text(
                                selectedDeadline != null 
                                  ? DateFormat('EEEE, dd MMMM yyyy').format(selectedDeadline!)
                                  : "Select deadline date",
                                style: TextStyle(
                                  fontSize: 16,
                                  color: selectedDeadline != null ? Colors.black87 : Colors.grey.shade600,
                                ),
                              ),
                              const Spacer(),
                              Icon(Icons.arrow_drop_down, color: Colors.grey.shade600),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Progress Section
                      _buildSectionHeader("Completion Progress", Icons.pie_chart, Colors.deepPurple),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                          color: Colors.grey.shade50,
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "$completionPercentage%",
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Row(
                                  children: [
                                    IconButton(
                                      onPressed: decrementCompletion,
                                      icon: const Icon(Icons.remove_circle),
                                      color: Colors.red.shade400,
                                    ),
                                    IconButton(
                                      onPressed: incrementCompletion,
                                      icon: const Icon(Icons.add_circle),
                                      color: Colors.green.shade400,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            LinearProgressIndicator(
                              value: completionPercentage / 100,
                              backgroundColor: Colors.grey.shade300,
                              valueColor: AlwaysStoppedAnimation<Color>(getCompletionColor()),
                              minHeight: 8,
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "0%",
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                                Text(
                                  "100%",
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: cancelChanges,
                      icon: const Icon(Icons.close),
                      label: const Text("Cancel"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade400,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  if (isEditMode) ...[
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: saveAsNew,
                        icon: const Icon(Icons.copy),
                        label: const Text("Save As"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange.shade400,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: saveChanges,
                      icon: const Icon(Icons.save),
                      label: Text(isEditMode ? "Save" : "Create"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade400,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icon, size: 16, color: color),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }
}