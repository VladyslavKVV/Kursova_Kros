import 'package:flutter/material.dart';
import 'db_helper.dart';
import 'login_screen.dart';

class WorkoutScreen extends StatefulWidget {
  final int userId;

  const WorkoutScreen({Key? key, required this.userId}) : super(key: key);

  @override
  _WorkoutScreenState createState() => _WorkoutScreenState();
}

class _WorkoutScreenState extends State<WorkoutScreen> {
  final DBHelper dbHelper = DBHelper();
  final TextEditingController _exerciseController = TextEditingController();
  final TextEditingController _repsController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();

  List<Map<String, dynamic>> _workouts = [];

  @override
  void initState() {
    super.initState();
    _loadWorkouts();
  }

  void _loadWorkouts() async {
    final workouts = await dbHelper.getWorkouts(widget.userId);
    setState(() {
      _workouts = workouts;
    });
  }

  void _addWorkout() async {
    final exercise = _exerciseController.text.trim();
    final repetitions = int.tryParse(_repsController.text.trim());
    final weight = double.tryParse(_weightController.text.trim());

    if (exercise.isEmpty || repetitions == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Заповніть всі поля для вправи!'),
      ));
      return;
    }

    await dbHelper.insertWorkout(widget.userId, DateTime.now().toIso8601String(), exercise, repetitions, weight);
    _loadWorkouts();

    // Очищення полів
    _exerciseController.clear();
    _repsController.clear();
    _weightController.clear();
  }

  void _logout() {
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => LoginScreen()));
  }

  void _deleteAccount() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Видалити акаунт?'),
        content: Text('Це видалить ваш обліковий запис та всі пов’язані тренування. Ви впевнені?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text('Скасувати')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: Text('Видалити')),
        ],
      ),
    );

    if (confirm == true) {
      final db = await dbHelper.database;
      await db.delete('workouts', where: 'userId = ?', whereArgs: [widget.userId]);
      await db.delete('users', where: 'id = ?', whereArgs: [widget.userId]);

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Акаунт видалено.')));
      _logout();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Мої тренування'),
        actions: [
          IconButton(onPressed: _logout, icon: Icon(Icons.logout), tooltip: 'Вийти з акаунту'),
          IconButton(onPressed: _deleteAccount, icon: Icon(Icons.delete), tooltip: 'Видалити акаунт'),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                TextField(
                  controller: _exerciseController,
                  decoration: InputDecoration(labelText: 'Назва вправи'),
                ),
                TextField(
                  controller: _repsController,
                  decoration: InputDecoration(labelText: 'Кількість повторень'),
                  keyboardType: TextInputType.number,
                ),
                TextField(
                  controller: _weightController,
                  decoration: InputDecoration(labelText: 'Вага (якщо є)'),
                  keyboardType: TextInputType.number,
                ),
                SizedBox(height: 10),
                ElevatedButton(onPressed: _addWorkout, child: Text('Додати вправу')),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _workouts.length,
              itemBuilder: (context, index) {
                final workout = _workouts[index];
                return ListTile(
                  title: Text(workout['exercise']),
                  subtitle: Text(
                    'Повторення: ${workout['repetitions']}, Вага: ${workout['weight']} кг',
                  ),
                  trailing: Text(workout['date'].substring(0, 10)), // Показуємо дату
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
