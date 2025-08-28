import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
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