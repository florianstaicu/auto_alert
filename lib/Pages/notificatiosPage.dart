import 'package:auto_alert/Pages/notificationSetting.dart';
import 'package:auto_alert/SQLite/Cars.dart';
import 'package:auto_alert/SQLite/database_helper.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificatiosPageState();
}

class _NotificatiosPageState extends State<NotificationsPage> {
  List<NotificationItem> notification = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    markNotificationAsRead();
    loadNotifications();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    markNotificationAsRead();
  }

  bool shouldAddNotification(int daysRemaining) {
    return daysRemaining <= 30;
  }

  String getExpiryStatus(int daysRemaining) {
    if (daysRemaining < 0) {
      return 'EXPIRED ${daysRemaining.abs()} days ago';
    } else if (daysRemaining == 0) {
      return 'EXPIRES TODAY';
    } else if (daysRemaining == 1) {
      return 'Expires tomorrow';
    } else if (daysRemaining <= 7) {
      return 'Expires in $daysRemaining days - URGENT';
    } else if (daysRemaining <= 30) {
      return 'Expires in $daysRemaining days';
    } else {
      return 'Expires in $daysRemaining days';
    }
  }

  Color getStatusColor(int daysRemaining) {
    if (daysRemaining < 0) {
      return Colors.red;
    } else if (daysRemaining == 0) {
      return Colors.orange;
    } else if (daysRemaining <= 7) {
      return Colors.orange;
    } else if (daysRemaining <= 30) {
      return Colors.lightGreen;
    } else {
      return Colors.green;
    }
  }

  Future<void> loadNotifications() async {
    setState(() {
      isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      bool allNotifications = prefs.getBool('allNotifications') ?? true;
      bool insuranceEnabled = prefs.getBool('insuranceNotification') ?? true;
      bool itpEnabled = prefs.getBool('itpNotification') ?? true;
      bool roadTaxEnabled = prefs.getBool('roadTaxNotification') ?? true;

      final carsData = await DatabaseHelper().getCars();

      List<NotificationItem> loadedNotifications = [];

      for (var carMap in carsData) {
        Cars car = Cars.fromMap(carMap);

        if (allNotifications && insuranceEnabled) {
          int daysRemaining = car.insuranceDaysRemaining;

          if (shouldAddNotification(daysRemaining)) {
            loadedNotifications.add(
              NotificationItem(
                numberPlate: car.numberPlate,
                type: 'Insurance (RCA)',
                exipryDate: car.insuranceExpiry!,
                icon: Icons.shield,
                color: Colors.blue,
                daysRemaining: daysRemaining,
              ),
            );
          }
        }

        if (allNotifications && itpEnabled) {
          int daysRemaining = car.technicalInspectionDaysRemaining;

          if (shouldAddNotification(daysRemaining)) {
            loadedNotifications.add(
              NotificationItem(
                numberPlate: car.numberPlate,
                type: 'Tehnical Inspection (ITP)',
                exipryDate: car.technicalInspectionExpiry!,
                icon: Icons.build_rounded,
                color: Colors.deepOrange,
                daysRemaining: daysRemaining,
              ),
            );
          }
        }

        if (allNotifications && roadTaxEnabled) {
          int daysRemaining = car.roadTaxDaysRemaining;

          if (shouldAddNotification(daysRemaining)) {
            loadedNotifications.add(
              NotificationItem(
                numberPlate: car.numberPlate,
                type: 'Road Tax (Rovinieta)',
                exipryDate: car.roadTaxExpiry!,
                icon: Icons.local_parking,
                color: Colors.lightBlue,
                daysRemaining: daysRemaining,
              ),
            );
          }
        }
        if (allNotifications) {
          if (car.casco != null && car.casco!.isNotEmpty) {
            int daysRemaining = car.cascoDaysRemaining;

            if (shouldAddNotification(daysRemaining)) {
              loadedNotifications.add(
                NotificationItem(
                  numberPlate: car.numberPlate,
                  type: 'CASCO',
                  exipryDate: car.casco!,
                  icon: Icons.security,
                  color: Colors.green,
                  daysRemaining: daysRemaining,
                ),
              );
            }
          }
          if (car.medicalToolkit != null && car.medicalToolkit!.isNotEmpty) {
            int daysRemaining = car.medicalToolkitDaysRemaining;

            if (shouldAddNotification(daysRemaining)) {
              loadedNotifications.add(
                NotificationItem(
                  numberPlate: car.numberPlate,
                  type: 'Medical Toolkit',
                  exipryDate: car.medicalToolkit!,
                  icon: Icons.medical_services,
                  color: Colors.red,
                  daysRemaining: daysRemaining,
                ),
              );
            }
          }
          if (car.fireExtinguisher != null &&
              car.fireExtinguisher!.isNotEmpty) {
            int daysRemaining = car.fireExtinguisherDaysRemaining;

            if (shouldAddNotification(daysRemaining)) {
              loadedNotifications.add(
                NotificationItem(
                  numberPlate: car.numberPlate,
                  type: 'Fire Extinguisher',
                  exipryDate: car.fireExtinguisher!,
                  icon: Icons.local_fire_department,
                  color: Colors.purple,
                  daysRemaining: daysRemaining,
                ),
              );
            }
          }
          if (car.others != null && car.others!.isNotEmpty) {
            int daysRemaining = car.othersDaysRemaining;

            if (shouldAddNotification(daysRemaining)) {
              loadedNotifications.add(
                NotificationItem(
                  numberPlate: car.numberPlate,
                  type: 'Others',
                  exipryDate: car.others!,
                  icon: Icons.notifications,
                  color: Colors.grey,
                  daysRemaining: daysRemaining,
                ),
              );
            }
          }
        }
      }

      loadedNotifications.sort((a, b) {
        if (a.daysRemaining < 0 && b.daysRemaining >= 0) return -1;
        if (a.daysRemaining >= 0 && b.daysRemaining < 0) return 1;
        return a.daysRemaining.compareTo(b.daysRemaining);
      });

      setState(() {
        notification = loadedNotifications;
        isLoading = false;
      });
    } catch (e) {
      print("Error loading notifications: $e");
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Widget buildNotificationCard(NotificationItem item) {
    final statusColor = getStatusColor(item.daysRemaining);
    final status = getExpiryStatus(item.daysRemaining);

    return Card(
      margin: EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border(left: BorderSide(color: statusColor, width: 5)),
        ),
        child: Padding(
          padding: EdgeInsets.all(15),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: item.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(50),
                ),
                child: Icon(item.icon, color: item.color, size: 30),
              ),
              SizedBox(width: 15),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.type,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 5),
                    Text(
                      item.numberPlate,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 5),
                    Text(
                      'Expiry Date: ${item.exipryDate}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                    SizedBox(height: 5),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        status,
                        style: TextStyle(
                          fontSize: 12,
                          color: statusColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_none, size: 50, color: Colors.grey),
          SizedBox(height: 20),
          Text(
            'No notifications available',
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),

          SizedBox(height: 10),

          Text(
            'Notifications about expiring documents will appear here.',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),

          SizedBox(height: 30),

          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
            },
            icon: Icon(Icons.add),
            label: Text('Add a Car'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void markNotificationAsRead() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('unread_notifications', 0);
    print("Notifications marked as read from NotificationsPage");
  }

  @override
  Widget build(BuildContext context) {
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      markNotificationAsRead();
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Notifications',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black,
            letterSpacing: 2,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.black),
        centerTitle: true,

        actions: [
          IconButton(
            icon: Icon(Icons.settings_outlined),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => NotificationSettings()),
              );
              loadNotifications();
            },
          ),
        ],
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : notification.isEmpty
          ? buildEmptyState()
          : RefreshIndicator(
              onRefresh: () async {
                await loadNotifications();
              },
              child: ListView.builder(
                padding: EdgeInsets.all(15.0),
                itemCount: notification.length,
                itemBuilder: (context, index) {
                  return buildNotificationCard(notification[index]);
                },
              ),
            ),
    );
  }
}

class NotificationItem {
  final String numberPlate;
  final String type;
  final String exipryDate;
  final IconData icon;
  final Color color;
  final int daysRemaining;

  NotificationItem({
    required this.numberPlate,
    required this.type,
    required this.exipryDate,
    required this.icon,
    required this.color,
    required this.daysRemaining,
  });
}
