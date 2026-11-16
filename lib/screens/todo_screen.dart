import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../models/todo_item.dart';
import '../services/database_service.dart';

class TodoScreen extends StatefulWidget {
  final DatabaseService databaseService;

  const TodoScreen({super.key, required this.databaseService});

  @override
  State<TodoScreen> createState() => _TodoScreenState();
}

class _TodoScreenState extends State<TodoScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<TodoItem> _allTodos = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadTodos();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _loadTodos() {
    setState(() {
      _allTodos = widget.databaseService.getTodos();
    });
  }

  List<TodoItem> get _pendingTodos => _allTodos.where((t) => !t.isCompleted).toList();
  List<TodoItem> get _completedTodos => _allTodos.where((t) => t.isCompleted).toList();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('To-Do List', style: TextStyle(fontWeight: FontWeight.bold)),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'All (${_allTodos.length})'),
            Tab(text: 'Pending (${_pendingTodos.length})'),
            Tab(text: 'Done (${_completedTodos.length})'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildTodoList(_allTodos, 'No tasks yet. Tap + to add one!'),
          _buildTodoList(_pendingTodos, 'Great job! No pending tasks.'),
          _buildTodoList(_completedTodos, 'No completed tasks yet.'),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddOrEditTaskSheet(null),
        icon: const Icon(Icons.add),
        label: const Text('Add Task'),
      ),
    );
  }

  Widget _buildTodoList(List<TodoItem> todos, String emptyMessage) {
    if (todos.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.assignment_turned_in_outlined, size: 56, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text(
              emptyMessage,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 15),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: todos.length,
      itemBuilder: (context, index) {
        final todo = todos[index];
        final priorityColor = _getPriorityColor(todo.priority);

        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          elevation: 0.5,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: todo.isCompleted
                  ? Colors.transparent
                  : Theme.of(context).colorScheme.outlineVariant.withOpacity(0.5),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Completion Checkbox
                Checkbox(
                  value: todo.isCompleted,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
                  onChanged: (val) async {
                    await widget.databaseService.toggleTodoComplete(todo.id);
                    _loadTodos();
                  },
                ),
                const SizedBox(width: 6),

                // Main Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              todo.title,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                decoration: todo.isCompleted ? TextDecoration.lineThrough : null,
                                color: todo.isCompleted ? Colors.grey : null,
                              ),
                            ),
                          ),
                          // Priority Badge
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: priorityColor.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              todo.priority,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: priorityColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (todo.description.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          todo.description,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                            decoration: todo.isCompleted ? TextDecoration.lineThrough : null,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      const SizedBox(height: 8),

                      // Category & Due Date
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surfaceVariant,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              todo.category,
                              style: TextStyle(
                                fontSize: 11,
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                          if (todo.dueDate != null) ...[
                            const SizedBox(width: 8),
                            Icon(Icons.event_outlined, size: 13, color: Colors.grey.shade600),
                            const SizedBox(width: 3),
                            Text(
                              DateFormat('MMM d, h:mm a').format(todo.dueDate!),
                              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),

                // Edit & Delete Actions
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, size: 20),
                  onSelected: (val) async {
                    if (val == 'edit') {
                      _showAddOrEditTaskSheet(todo);
                    } else if (val == 'delete') {
                      await widget.databaseService.deleteTodo(todo.id);
                      _loadTodos();
                    }
                  },
                  itemBuilder: (ctx) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit_outlined, size: 18),
                          SizedBox(width: 8),
                          Text('Edit'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline, size: 18, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Delete', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Color _getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'high':
        return Colors.redAccent;
      case 'medium':
        return Colors.amber.shade800;
      case 'low':
        return Colors.green;
      default:
        return Colors.blue;
    }
  }

  void _showAddOrEditTaskSheet(TodoItem? existing) {
    final titleController = TextEditingController(text: existing?.title ?? '');
    final descController = TextEditingController(text: existing?.description ?? '');
    String priority = existing?.priority ?? 'Medium';
    String category = existing?.category ?? 'Work';
    DateTime? dueDate = existing?.dueDate;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      existing == null ? 'Create New Task' : 'Edit Task',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: titleController,
                      autofocus: existing == null,
                      decoration: const InputDecoration(
                        labelText: 'Task Title *',
                        hintText: 'e.g. Submit Sprint PR on GitHub',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: descController,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Description / Notes',
                        hintText: 'Optional details',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Priority & Category Dropdowns
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: priority,
                            decoration: const InputDecoration(
                              labelText: 'Priority',
                              border: OutlineInputBorder(),
                            ),
                            items: const [
                              DropdownMenuItem(value: 'High', child: Text('High')),
                              DropdownMenuItem(value: 'Medium', child: Text('Medium')),
                              DropdownMenuItem(value: 'Low', child: Text('Low')),
                            ],
                            onChanged: (val) {
                              if (val != null) setModalState(() => priority = val);
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: category,
                            decoration: const InputDecoration(
                              labelText: 'Category',
                              border: OutlineInputBorder(),
                            ),
                            items: const [
                              DropdownMenuItem(value: 'Work', child: Text('Work')),
                              DropdownMenuItem(value: 'Personal', child: Text('Personal')),
                              DropdownMenuItem(value: 'Urgent', child: Text('Urgent')),
                            ],
                            onChanged: (val) {
                              if (val != null) setModalState(() => category = val);
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Due Date Selector
                    OutlinedButton.icon(
                      icon: const Icon(Icons.calendar_today_outlined, size: 18),
                      label: Text(
                        dueDate == null
                            ? 'Set Due Date & Time'
                            : 'Due: ${DateFormat('MMM d, h:mm a').format(dueDate!)}',
                      ),
                      onPressed: () async {
                        final now = DateTime.now();
                        final pickedDate = await showDatePicker(
                          context: ctx,
                          initialDate: dueDate ?? now,
                          firstDate: now.subtract(const Duration(days: 30)),
                          lastDate: now.add(const Duration(days: 365)),
                        );
                        if (pickedDate != null) {
                          final pickedTime = await showTimePicker(
                            context: ctx,
                            initialTime: TimeOfDay.fromDateTime(dueDate ?? now),
                          );
                          setModalState(() {
                            dueDate = DateTime(
                              pickedDate.year,
                              pickedDate.month,
                              pickedDate.day,
                              pickedTime?.hour ?? 12,
                              pickedTime?.minute ?? 0,
                            );
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 20),

                    // Save Button
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: FilledButton(
                        onPressed: () async {
                          if (titleController.text.trim().isEmpty) return;
                          final item = TodoItem(
                            id: existing?.id ?? const Uuid().v4(),
                            title: titleController.text.trim(),
                            description: descController.text.trim(),
                            priority: priority,
                            category: category,
                            dueDate: dueDate,
                            isCompleted: existing?.isCompleted ?? false,
                            createdAt: existing?.createdAt ?? DateTime.now(),
                          );
                          await widget.databaseService.saveTodo(item);
                          if (mounted) {
                            Navigator.pop(ctx);
                            _loadTodos();
                          }
                        },
                        child: Text(existing == null ? 'Save Task' : 'Update Task'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
