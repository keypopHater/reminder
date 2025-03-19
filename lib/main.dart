import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:async';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  tz.initializeTimeZones();
  await NotificationService().initNotifications();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'İlaç Hatırlatma',
      theme: ThemeData(
        primarySwatch: Colors.green,
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
  int _selectedInterval = 6; // Интервал приема в часах
  String _selectedDuration = '1 Hafta';
  String _selectedTimeOfDay = 'Sabah';

  final List<String> durations = ['1 Hafta', '2 Hafta', '1 Ay', '6 Ay', '1 Yıl', '2 Yıl'];
  final List<String> timeOfDayOptions = ['Sabah', 'Öğle', 'Akşam'];

  void addReminder() {
    if (nameController.text.isNotEmpty) {
      setState(() {
        reminders.add({
          'name': nameController.text,
          'interval': _selectedInterval,
          'duration': _selectedDuration,
          'timeOfDay': _selectedTimeOfDay,
        });
      });
      nameController.clear();
      // Add notification after reminder is added
      notificationService.scheduleNotification(
        _selectedInterval,
        'İlaç Hatırlatma',
        '${nameController.text} içme zamanı geldi!',
      );
    }
  }

  void removeReminder(int index) {
    setState(() {
      reminders.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green[50],
      appBar: AppBar(
        title: const Text('İlaç Hatırlatma'),
        backgroundColor: Colors.green,
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
                  borderSide: BorderSide(color: Colors.green),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'İçme Aralığı (Saat):',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline, size: 30, color: Colors.green),
                  onPressed: () {
                    setState(() {
                      if (_selectedInterval > 1) {
                        _selectedInterval--;
                      }
                    });
                  },
                ),
                Text(
                  '$_selectedInterval saat',
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline, size: 30, color: Colors.green),
                  onPressed: () {
                    setState(() {
                      _selectedInterval++;
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Text(
              'Kullanım Süresi:',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            DropdownButton<String>(
              value: _selectedDuration,
              items: durations.map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              onChanged: (newValue) {
                setState(() {
                  _selectedDuration = newValue!;
                });
              },
            ),
            const SizedBox(height: 20),
            const Text(
              'İçme Zamanı:',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            DropdownButton<String>(
              value: _selectedTimeOfDay,
              items: timeOfDayOptions.map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              onChanged: (newValue) {
                setState(() {
                  _selectedTimeOfDay = newValue!;
                });
              },
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: addReminder,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
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
                  return Card(
                    color: Colors.green[100],
                    margin: const EdgeInsets.symmetric(vertical: 10),
                    child: ListTile(
                      title: Text(
                          '${reminders[index]['name']} - ${reminders[index]['interval']} saat - ${reminders[index]['duration']} - ${reminders[index]['timeOfDay']}'),
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
  late FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;

  // Инициализация уведомлений
  Future<void> initNotifications() async {
    flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

    const AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('app_icon');

    // Упрощённая инициализация iOS


    final InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  // Планирование уведомлений
  Future<void> scheduleNotification(int interval, String title, String body) async {
    final tz.TZDateTime scheduledDate = _nextInstanceOfTimeOfDay(interval);

    await flutterLocalNotificationsPlugin.zonedSchedule(
      0,
      title,
      body,
      scheduledDate,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'your_channel_id',
          'your_channel_name',
          channelDescription: 'your_channel_description',
          importance: Importance.max,
          priority: Priority.high,
        ),
      ),
      androidAllowWhileIdle: true,
      uiLocalNotificationDateInterpretation:
      UILocalNotificationDateInterpretation.wallClockTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  // Вычисление следующего времени для уведомления
  tz.TZDateTime _nextInstanceOfTimeOfDay(int interval) {
    final now = tz.TZDateTime.now(tz.local);
    return tz.TZDateTime.now(tz.local).add(Duration(hours: interval));
  }
}
