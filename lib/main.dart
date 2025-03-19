import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:async';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  tz.initializeTimeZones(); // Инициализация часовых поясов
  await NotificationService().initNotifications(); // Инициализация уведомлений
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'İlaç Hatırlatma',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const ReminderPage(),
    );
  }
}

class ReminderPage extends StatefulWidget {
  const ReminderPage({super.key});

  @override
  State<ReminderPage> createState() => _ReminderPageState();
}

class _ReminderPageState extends State<ReminderPage> {
  final List<Map<String, dynamic>> reminders = [];
  final TextEditingController nameController = TextEditingController();
  final NotificationService notificationService = NotificationService();
  int _selectedMinutes = 10; // Default selected minutes

  // Добавляем новое напоминание
  void addReminder() {
    if (nameController.text.isNotEmpty) {
      int minutes = _selectedMinutes;
      int seconds = minutes * 60; // Переводим минуты в секунды
      setState(() {
        reminders.add({
          'name': nameController.text,
          'time': minutes,
          'remaining': seconds,
        });
      });
      notificationService.scheduleNotification(reminders.length, nameController.text, seconds);

      // Запускаем таймер для отсчета времени
      startTimer(reminders.length - 1, seconds);

      nameController.clear();
    }
  }

  // Удаляем напоминание
  void removeReminder(int index) {
    setState(() {
      reminders.removeAt(index);
    });
  }

  // Запускаем таймер
  void startTimer(int index, int seconds) {
    Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (reminders[index]['remaining'] > 0) {
          reminders[index]['remaining']--;
        } else {
          timer.cancel();
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.teal[50],
      appBar: AppBar(
        title: const Text('İlaç Hatırlatma'),
        backgroundColor: Colors.teal,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'İlaç Adı:',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'İlaç Adını Giriniz',
                border: OutlineInputBorder(),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.teal),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Hatırlatma Süresi:',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline, size: 30, color: Colors.teal),
                  onPressed: () {
                    setState(() {
                      if (_selectedMinutes > 1) {
                        _selectedMinutes--;
                      }
                    });
                  },
                ),
                Text(
                  '$_selectedMinutes dakika',
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline, size: 30, color: Colors.teal),
                  onPressed: () {
                    setState(() {
                      _selectedMinutes++;
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: addReminder,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal, // Заменили primary на backgroundColor
                padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              ),
              child: const Text(
                'Hatırlatmayı Ekle',
                style: TextStyle(fontSize: 18),
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: reminders.length,
                itemBuilder: (context, index) {
                  int remainingMinutes = (reminders[index]['remaining'] ~/ 60);
                  int remainingSeconds = reminders[index]['remaining'] % 60;
                  return Card(
                    color: Colors.teal[100],
                    margin: const EdgeInsets.symmetric(vertical: 10),
                    child: ListTile(
                      title: Text(
                          '${reminders[index]['name']} - ${remainingMinutes}m ${remainingSeconds}s'),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => removeReminder(index),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class NotificationService {
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  // Инициализация уведомлений
  Future<void> initNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initializationSettings = InitializationSettings(android: initializationSettingsAndroid);
    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  // Планирование уведомления
  Future<void> scheduleNotification(int id, String name, int seconds) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics = AndroidNotificationDetails(
        'channel_id', 'channel_name',
        importance: Importance.max,
        priority: Priority.high,
        sound: RawResourceAndroidNotificationSound('notification')
    );
    const NotificationDetails platformChannelSpecifics = NotificationDetails(android: androidPlatformChannelSpecifics);
    await flutterLocalNotificationsPlugin.zonedSchedule(
      id,
      'İlaç Zamanı!',
      '$name ilacını almayı unutma!',
      tz.TZDateTime.now(tz.local).add(Duration(seconds: seconds)),
      platformChannelSpecifics,
      androidAllowWhileIdle: true,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
    );
  }
}
