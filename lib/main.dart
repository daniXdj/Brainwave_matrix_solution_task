import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart'; // For date formatting

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ToDo List',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: TodoListScreen(),
    );
  }
}

class TodoListScreen extends StatefulWidget {
  const TodoListScreen({super.key});

  @override
  _TodoListScreenState createState() => _TodoListScreenState();
}

class _TodoListScreenState extends State<TodoListScreen> {
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  List<Task> tasks = [];
  List<Task> filteredTasks = [];
  TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    filteredTasks = tasks;
    _initializeNotifications();
    searchController.addListener(_filterTasks);
  }

  void _initializeNotifications() async {
    var initializationSettingsAndroid = const AndroidInitializationSettings('app_icon');
    var initializationSettings = InitializationSettings(android: initializationSettingsAndroid);
    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  void _showNotification(String title, String body) async {
    var androidDetails = const AndroidNotificationDetails(
      'todo_channel',
      'ToDo Notifications',
      importance: Importance.high,
      priority: Priority.high,
    );
    var generalNotificationDetails = NotificationDetails(android: androidDetails);
    await flutterLocalNotificationsPlugin.show(0, title, body, generalNotificationDetails);
  }

  void _addTask() {
    showDialog(
      context: context,
      builder: (context) {
        return AddTaskDialog(
          onSave: (name, priority, deadline) {
            setState(() {
              Task newTask = Task(name, priority, deadline, false);
              tasks.add(newTask);
              filteredTasks = tasks;
            });
            Navigator.pop(context);
          },
        );
      },
    );
  }

  void _editTask(Task task) {
    showDialog(
      context: context,
      builder: (context) {
        return AddTaskDialog(
          task: task,
          onSave: (name, priority, deadline) {
            setState(() {
              task.name = name;
              task.priority = priority;
              task.deadline = deadline;
            });
            Navigator.pop(context);
          },
        );
      },
    );
  }

  void _filterTasks() {
    setState(() {
      String query = searchController.text.toLowerCase();
      filteredTasks = tasks.where((task) {
        return task.name.toLowerCase().contains(query) ||
            task.priority.toLowerCase().contains(query) ||
            task.deadline.contains(query);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Enhanced ToDo List'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: searchController,
              decoration: const InputDecoration(
                hintText: 'Search by Name, Priority, or Due Date',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.search),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: filteredTasks.length,
              itemBuilder: (context, index) {
                return Dismissible(
                  key: Key(filteredTasks[index].name),
                  onDismissed: (direction) {
                    setState(() {
                      tasks.removeAt(index);
                      filteredTasks = tasks;
                    });
                  },
                  child: ListTile(
                    title: Text(filteredTasks[index].name),
                    subtitle: Text(
                        'Priority: ${filteredTasks[index].priority} - Due: ${filteredTasks[index].deadline}'),
                    trailing: IconButton(
                      icon: const Icon(Icons.notifications),
                      onPressed: () {
                        _showNotification('Reminder', filteredTasks[index].name);
                      },
                    ),
                    tileColor: filteredTasks[index].priority == 'High'
                        ? Colors.red[200]
                        : Colors.green[200],
                    onTap: () => _editTask(filteredTasks[index]),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addTask,
        tooltip: 'Add Task',
        child: Icon(Icons.add),
      ),
    );
  }
}

class Task {
  String name;
  String priority;
  String deadline;
  bool completed;

  Task(this.name, this.priority, this.deadline, this.completed);
}

class AddTaskDialog extends StatefulWidget {
  final Task? task;
  final Function(String, String, String) onSave;

  const AddTaskDialog({super.key, this.task, required this.onSave});

  @override
  _AddTaskDialogState createState() => _AddTaskDialogState();
}

class _AddTaskDialogState extends State<AddTaskDialog> {
  late TextEditingController _nameController;
  late TextEditingController _priorityController;
  late TextEditingController _deadlineController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.task?.name);
    _priorityController = TextEditingController(text: widget.task?.priority);
    _deadlineController = TextEditingController(text: widget.task?.deadline);
  }

  void _pickDate(BuildContext context) async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );

    if (pickedDate != null) {
      setState(() {
        _deadlineController.text = DateFormat('yyyy-MM-dd').format(pickedDate);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.task == null ? 'Add Task' : 'Edit Task'),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(labelText: 'Task Name'),
          ),
          TextField(
            controller: _priorityController,
            decoration: const InputDecoration(labelText: 'Priority (High/Low)'),
          ),
          GestureDetector(
            onTap: () => _pickDate(context),
            child: AbsorbPointer(
              child: TextField(
                controller: _deadlineController,
                decoration: const InputDecoration(
                  labelText: 'Due Date (YYYY-MM-DD)',
                ),
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            widget.onSave(
              _nameController.text,
              _priorityController.text,
              _deadlineController.text,
            );
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
