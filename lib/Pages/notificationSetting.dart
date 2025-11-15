import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationSettings extends StatefulWidget {
  const NotificationSettings({super.key});

  @override
  State<NotificationSettings> createState() => NotificationSettingStateState();
}

class NotificationSettingStateState extends State<NotificationSettings> {
  bool insuranceNotification = true;
  bool itpNotification = true;
  bool roadTaxNotification = true;
  bool allNotifications = true;

  Future<void> saveSetting(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  void showScheduleInfoDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.schedule),
            SizedBox(width: 10),
            Text('Schedule Info'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            Text(
              'Notifications are sent by following schedule:',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            SizedBox(height: 10),
            Row(
              children: [
              Icon(Icons.calendar_today, size: 20, color: Colors.grey),
              SizedBox(width: 10),
              Text('30 days before expiration'),
              ],
            ),
            SizedBox(height: 5),
            Row(
              children: [
              Icon(Icons.calendar_today, size: 20, color: Colors.grey),
              SizedBox(width: 10),
              Text('7 days before expiration'),
              ],
            ),
            SizedBox(height: 5),
            Row(
              children: [
              Icon(Icons.calendar_today, size: 20, color: Colors.grey),
              SizedBox(width: 10),
              Text('On the day of expiration'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        title: Text(
          'Notification Settings',
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
            icon: Icon(Icons.info_outline),
            onPressed: showScheduleInfoDialog,
          ),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.all(15.0),
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: SwitchListTile(
              value: allNotifications,
              onChanged: (value) async {
                setState(() {
                  allNotifications = value;

                  if (!value) {
                    insuranceNotification = false;
                    itpNotification = false;
                    roadTaxNotification = false;
                  } else {
                    insuranceNotification = true;
                    itpNotification = true;
                    roadTaxNotification = true;
                  }
                });
                await saveSetting('allNotifications', allNotifications);
                await saveSetting(
                  'insuranceNotification',
                  insuranceNotification,
                );
                await saveSetting('itpNotification', itpNotification);
                await saveSetting('roadTaxNotification', roadTaxNotification);
              },
              title: Text(
                'Enable All Notifications',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
              ),
              subtitle: Text('Toggle all notification settings at once'),
              secondary: Icon(
                Icons.notifications,
                color: allNotifications ? Colors.blue : Colors.grey,
              ),
              activeColor: Colors.blue,
            ),
          ),

          SizedBox(height: 20),

          Text(
            'Notification Types',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 10),

          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                SwitchListTile(
                  value: insuranceNotification && allNotifications,
                  onChanged: allNotifications
                      ? (value) async {
                          setState(() {
                            insuranceNotification = value;
                          });
                          await saveSetting('notifications_insurance', value);
                        }
                      : null,
                  title: Text('Asigurare (RCA)'),
                  subtitle: Text('Notificări pentru expirarea asigurării'),
                  secondary: Icon(
                    Icons.shield_outlined,
                    color: insuranceNotification && allNotifications
                        ? Colors.blue
                        : Colors.grey,
                  ),
                  activeColor: Colors.blue,
                ),
                Divider(height: 1),
                SwitchListTile(
                  value: itpNotification && allNotifications,
                  onChanged: allNotifications
                      ? (value) async {
                          setState(() {
                            itpNotification = value;
                          });
                          await saveSetting('notifications_itp', value);
                        }
                      : null,
                  title: Text('ITP'),
                  subtitle: Text('Notificări pentru expirarea ITP-ului'),
                  secondary: Icon(
                    Icons.build_outlined,
                    color: itpNotification && allNotifications
                        ? Colors.blue
                        : Colors.grey,
                  ),
                  activeColor: Colors.blue,
                ),
                Divider(height: 1),
                SwitchListTile(
                  value: roadTaxNotification && allNotifications,
                  onChanged: allNotifications
                      ? (value) async {
                          setState(() {
                            roadTaxNotification = value;
                          });
                          await saveSetting('notifications_rovinieta', value);
                        }
                      : null,
                  title: Text('Rovinieta'),
                  subtitle: Text('Notificări pentru expirarea rovinietei'),
                  secondary: Icon(
                    Icons.local_parking_outlined,
                    color: roadTaxNotification && allNotifications
                        ? Colors.blue
                        : Colors.grey,
                  ),
                  activeColor: Colors.blue,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
