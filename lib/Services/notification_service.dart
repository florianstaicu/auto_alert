import 'package:auto_alert/SQLite/Cars.dart';
import 'package:auto_alert/SQLite/database_helper.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

class NotificationService {
  static final NotificationService instance = NotificationService.internal();
  factory NotificationService() => instance;
  NotificationService.internal();

  final FlutterLocalNotificationsPlugin notifications =
      FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Europe/Bucharest'));

    print('Current time: ${DateTime.now()}');

    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );

    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await notifications.initialize(
      settings,
      onDidReceiveNotificationResponse: onNotificationTapped,
    );

    await requestPermissions();
  }

  Future<void> requestPermissions() async {
    await notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();

    await notifications
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(alert: true, badge: true, sound: true);
  }

  void onNotificationTapped(NotificationResponse response) {
    print('Notification tapped: ${response.payload}');
  }

  DateTime? parseDate(String dateStr) {
    if (dateStr.isEmpty) return null;

    try {
      if (dateStr.contains('.')) {

        final parts = dateStr.split('.');
        if (parts.length == 3) {
          final day = int.parse(parts[0].trim());
          final month = int.parse(parts[1].trim());
          final year = int.parse(parts[2].trim());
          return DateTime(year, month, day);
        }
      } else if (dateStr.contains('-')) {
        return DateTime.parse(dateStr);
      }
    } catch (e) {
      print('Error parsing date: $dateStr - $e');
    }

    return null;
  }

  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
  }) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'car_expiry_channel',
          'Car Expiry Notifications',
          channelDescription: 'Notifications for car document expiries',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await notifications.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledDate, tz.local),
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );

    print('Scheduled notification $id for $scheduledDate');
  }

  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'car_expiry_channel',
          'Car Expiry Notifications',
          channelDescription: 'Notifications for car document expiries',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await notifications.show(id, title, body, details);
  }

  Future<void> scheduleCarNotifications(Cars car) async {
    final prefs = await SharedPreferences.getInstance();
    bool allNotifications = prefs.getBool('allNotifications') ?? true;

    if (!allNotifications) return;

    final carHash = car.numberPlate.hashCode.abs();
    print(
      'Scheduling notifications for ${car.numberPlate} (ID base: $carHash)',
    );

    if (car.insuranceExpiry != null && car.insuranceExpiry!.isNotEmpty) {
      bool insuranceEnabled = prefs.getBool('insuranceNotification') ?? true;
      if (insuranceEnabled) {
        await scheduleExpiryNotifications(
          baseId: carHash,
          title: 'Asigurare ${car.numberPlate}',
          type: 'Asigurarea',
          expiryDate: car.insuranceExpiry!,
          carName: car.numberPlate,
        );
      }
    }

    if (car.technicalInspectionExpiry != null &&
        car.technicalInspectionExpiry!.isNotEmpty) {
      bool itpEnabled = prefs.getBool('itpNotification') ?? true;
      if (itpEnabled) {
        await scheduleExpiryNotifications(
          baseId: carHash + 1000,
          title: 'ITP ${car.numberPlate}',
          type: 'ITP-ul',
          expiryDate: car.technicalInspectionExpiry!,
          carName: car.numberPlate,
        );
      }
    }

    if (car.roadTaxExpiry != null && car.roadTaxExpiry!.isNotEmpty) {
      bool roadTaxEnabled = prefs.getBool('roadTaxNotification') ?? true;
      if (roadTaxEnabled) {
        await scheduleExpiryNotifications(
          baseId: carHash + 2000,
          title: 'Rovinieta ${car.numberPlate}',
          type: 'Rovinieta',
          expiryDate: car.roadTaxExpiry!,
          carName: car.numberPlate,
        );
      }
    }

    if (car.casco != null && car.casco!.isNotEmpty) {
      await scheduleExpiryNotifications(
        baseId: carHash + 3000,
        title: 'CASCO ${car.numberPlate}',
        type: 'CASCO',
        expiryDate: car.casco!,
        carName: car.numberPlate,
      );
    }

    if (car.medicalToolkit != null && car.medicalToolkit!.isNotEmpty) {
      await scheduleExpiryNotifications(
        baseId: carHash + 4000,
        title: 'Trusa Medicală ${car.numberPlate}',
        type: 'Trusa medicală',
        expiryDate: car.medicalToolkit!,
        carName: car.numberPlate,
      );
    }

    if (car.fireExtinguisher != null && car.fireExtinguisher!.isNotEmpty) {
      await scheduleExpiryNotifications(
        baseId: carHash + 5000,
        title: 'Stingător ${car.numberPlate}',
        type: 'Stingătorul',
        expiryDate: car.fireExtinguisher!,
        carName: car.numberPlate,
      );
    }
  }

  Future<void> scheduleExpiryNotifications({
    required int baseId,
    required String title,
    required String type,
    required String expiryDate,
    required String carName,

    int hourTime = 9,
    int minutesTime = 0,
  }) async {
    try {
    if (expiryDate.isEmpty) {
      print('Skipping $type for $carName - no expiry date set');
      return;
    }

    final expiry = parseDate(expiryDate);
    if (expiry == null) {
      print('Invalid date format for $type - $carName: $expiryDate');
      return;
    }

    final now = DateTime.now();

    if (expiry.isBefore(now.subtract(Duration(days: 1)))) {
      print('Skipping $type for $carName - date is in the past: $expiryDate');
      return;
    }

    final daysUntilExpiry = expiry.difference(now).inDays;
    
    if (daysUntilExpiry <= 0) {
      await scheduleNotification(
        id: baseId,
        title: title,
        body: '🚨 $type pentru $carName EXPIRĂ ASTĂZI!',
        scheduledDate: expiry.copyWith(hour: hourTime, minute: minutesTime),
      );
      print('✅ Scheduled TODAY notification for $type - $carName');
      
    } else if (daysUntilExpiry == 1) {
      await scheduleNotification(
        id: baseId,
        title: title,
        body: '⚠️ URGENT: $type pentru $carName expiră mâine!',
        scheduledDate: expiry.subtract(Duration(days: 1))
            .copyWith(hour: hourTime, minute: minutesTime),
      );
      print('✅ Scheduled TOMORROW notification for $type - $carName');
      
    } else if (daysUntilExpiry <= 7) {
      await scheduleNotification(
        id: baseId,
        title: title,
        body: '⚠️ $type pentru $carName expiră în $daysUntilExpiry zile!',
        scheduledDate: expiry.subtract(Duration(days: 7))
            .copyWith(hour: hourTime, minute: minutesTime),
      );
      print('✅ Scheduled 7-day notification for $type - $carName');
      
    } else if (daysUntilExpiry <= 30) {
      await scheduleNotification(
        id: baseId,
        title: title,
        body: '$type pentru $carName expiră în $daysUntilExpiry zile!',
        scheduledDate: expiry.subtract(Duration(days: 30))
            .copyWith(hour: hourTime, minute: minutesTime),
      );
      print('✅ Scheduled 30-day notification for $type - $carName');
    }

  } catch (e) {
    print('Error scheduling $type for $carName: $e');
  }
}


  Future<void> cancelCarNotifications(int carId) async {
    for (int type = 0; type <= 5000; type += 1000) {
      for (int offset = 1; offset <= 4; offset++) {
        await notifications.cancel(carId + type + offset);
      }
    }
  }

  Future<void> cancelAllNotifications() async {
    await notifications.cancelAll();
  }

  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return await notifications.pendingNotificationRequests();
  }

  bool shouldShowNotification(String? expiryDateStr) {
    if (expiryDateStr == null || expiryDateStr.isEmpty) return false;

    try {
      final expiryDate = parseDate(expiryDateStr);
      if (expiryDate == null) return false;

      final daysUntilExpiry = expiryDate.difference(DateTime.now()).inDays;
      return daysUntilExpiry <= 30;
    } catch (e) {
      return false;
    }
  }

  Future<int> getNotificationCount() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      bool allNotifications = prefs.getBool('allNotifications') ?? true;
      bool insuranceEnabled = prefs.getBool('insuranceNotification') ?? true;
      bool itpEnabled = prefs.getBool('itpNotification') ?? true;
      bool roadTaxEnabled = prefs.getBool('roadTaxNotification') ?? true;

      if (!allNotifications) {
        return 0;
      }

      final carsData = await DatabaseHelper().getCars();
      int count = 0;

      for (var carMap in carsData) {
        Cars car = Cars.fromMap(carMap);

        if (insuranceEnabled) {
          int daysRemaining = car.insuranceDaysRemaining;
          if (shouldShowNotification(car.insuranceExpiry) &&
              daysRemaining <= 30) {
            count++;
          }
        }

        if (itpEnabled) {
          int daysRemaining = car.technicalInspectionDaysRemaining;
          if (shouldShowNotification(car.technicalInspectionExpiry) &&
              daysRemaining <= 30) {
            count++;
          }
        }

        if (roadTaxEnabled) {
          int daysRemaining = car.roadTaxDaysRemaining;
          if (shouldShowNotification(car.roadTaxExpiry) &&
              daysRemaining <= 30) {
            count++;
          }
        }

        if (car.casco != null && car.casco!.isNotEmpty) {
          int daysRemaining = car.cascoDaysRemaining;
          if (shouldShowNotification(car.casco) && daysRemaining <= 30) {
            count++;
          }
        }

        if (car.medicalToolkit != null && car.medicalToolkit!.isNotEmpty) {
          int daysRemaining = car.medicalToolkitDaysRemaining;
          if (shouldShowNotification(car.medicalToolkit) &&
              daysRemaining <= 30) {
            count++;
          }
        }

        if (car.fireExtinguisher != null && car.fireExtinguisher!.isNotEmpty) {
          int daysRemaining = car.fireExtinguisherDaysRemaining;
          if (shouldShowNotification(car.fireExtinguisher) &&
              daysRemaining <= 30) {
            count++;
          }
        }

        if (car.others != null && car.others!.isNotEmpty) {
          int daysRemaining = car.othersDaysRemaining;
          if (shouldShowNotification(car.others) && daysRemaining <= 30) {
            count++;
          }
        }
      }

      return count;
    } catch (e) {
      print('Error getting notification count: $e');
      return 0;
    }
  }

  Future<int> getCarNotificationCount(String numberPlate) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      bool allNotifications = prefs.getBool('allNotifications') ?? true;

      if (!allNotifications) {
        return 0;
      }

      final carsData = await DatabaseHelper().getCars();
      int count = 0;

      for (var carMap in carsData) {
        Cars car = Cars.fromMap(carMap);

        if (car.numberPlate != numberPlate) continue;

        if (shouldShowNotification(car.insuranceExpiry) &&
            car.insuranceDaysRemaining <= 30) {
          count++;
        }

        if (shouldShowNotification(car.technicalInspectionExpiry) &&
            car.technicalInspectionDaysRemaining <= 30) {
          count++;
        }

        if (shouldShowNotification(car.roadTaxExpiry) &&
            car.roadTaxDaysRemaining <= 30) {
          count++;
        }

        if (car.casco != null &&
            shouldShowNotification(car.casco) &&
            car.cascoDaysRemaining <= 30) {
          count++;
        }

        if (car.medicalToolkit != null &&
            shouldShowNotification(car.medicalToolkit) &&
            car.medicalToolkitDaysRemaining <= 30) {
          count++;
        }

        if (car.fireExtinguisher != null &&
            shouldShowNotification(car.fireExtinguisher) &&
            car.fireExtinguisherDaysRemaining <= 30) {
          count++;
        }

        if (car.others != null &&
            shouldShowNotification(car.others) &&
            car.othersDaysRemaining <= 30) {
          count++;
        }

        break;
      }

      return count;
    } catch (e) {
      print('Error getting car notification count: $e');
      return 0;
    }
  }

  Future<void> printPendingNotifications() async {
    final pending = await notifications.pendingNotificationRequests();
    print('📋 PENDING NOTIFICATIONS (${pending.length}):');

    if (pending.isEmpty) {
      print('   No pending notifications');
      return;
    }

    for (var notif in pending) {
      print('   ID: ${notif.id}');
      print('   Title: ${notif.title}');
      print('   Body: ${notif.body}');
      print('   ---');
    }
  }
}
