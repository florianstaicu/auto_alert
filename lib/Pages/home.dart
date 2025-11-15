import 'package:auto_alert/Pages/insertingNewCar.dart';
import 'package:auto_alert/Pages/notificatiosPage.dart';
import 'package:auto_alert/Pages/profileAccount.dart';
import 'package:auto_alert/SQLite/Cars.dart';
import 'package:auto_alert/SQLite/database_helper.dart';
import 'package:auto_alert/Services/notification_service.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

int currentPage = 0;
List<Cars> cars = [];
Cars? carSelected;

class _HomePageState extends State<HomePage> {
  int notificationCount = 0;
  int unreadNotifications = 0;

  @override
  void initState() {
    loadCars();
    //  DatabaseHelper().deleteDB();
    // loadUnreadNotificationCount();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
    await NotificationService().printPendingNotifications();
    
    for (var car in cars) {
      NotificationService().scheduleCarNotifications(car);
    }
  });

    super.initState();
  }

  Future<void> insertNumberPlate(String numberPlate) async {
    final newCar = Cars(
      numberPlate: numberPlate,
      year: null,
      model: '',
      fuelType: '',
      insuranceExpiry: '',
      technicalInspectionExpiry: '',
      roadTaxExpiry: '',
    );
    await DatabaseHelper().insertNewCar(newCar);
    // loadCars();
    setState(() {
      cars.add(newCar);
    });
    await NotificationService().scheduleCarNotifications(newCar);

    updateNotificationCount();

    print("Fetched and inserted car with number plate: $numberPlate");
  }

  void saveCar(Cars car) async {
    await DatabaseHelper().updateCar(car.id!, car.toMap());

    updateNotificationCount();

    print("Updated car: ${car.toMap()}");
  }

  void loadCars() async {
    final carList = await DatabaseHelper().getCars();
    setState(() {
      cars = carList.map((car) => Cars.fromMap(car)).toList();
    });

    updateNotificationCount();

    print("Loaded cars: $cars");
  }

  void addCars() {
    final TextEditingController carController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Adaugă o mașină'),
          content: TextField(
            controller: carController,
            decoration: InputDecoration(
              labelText: 'Numarul mașinii',
              hintText: 'ex: PH 17 PLK',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Anulează'),
            ),
            TextButton(
              onPressed: () async {
                // final numberPlate = carController.text.trim();
                insertNumberPlate(carController.text.trim());

                Navigator.of(context).pop();
              },
              child: Text('Adaugă'),
            ),
          ],
        );
      },
    );
  }

  void _editCarAttributes(Cars car) async {
    final updateCar = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => InsertingNewCar(car: car)),
    );
    if (updateCar != null) {
      saveCar(updateCar);

      await NotificationService().cancelCarNotifications(updateCar!);
      await NotificationService().scheduleCarNotifications(updateCar);

      loadCars();
    }
  }

  void updateNotificationCount() async {
    int count = 0;

    for (var car in cars) {
      print("Car: ${car.numberPlate}");

      if (car.insuranceExpiry != null && car.insuranceExpiry!.isNotEmpty) {
        int daysRemaining = car.insuranceDaysRemaining;
        print("Insurance: $daysRemaining days remaining");
        if (daysRemaining <= 30) {
          count++;
        }
      }

      if (car.technicalInspectionExpiry != null &&
          car.technicalInspectionExpiry!.isNotEmpty) {
        int daysRemaining = car.technicalInspectionDaysRemaining;
        print("ITP: $daysRemaining days remaining");
        if (daysRemaining <= 30) {
          count++;
        }
      }

      if (car.roadTaxExpiry != null && car.roadTaxExpiry!.isNotEmpty) {
        int daysRemaining = car.roadTaxDaysRemaining;
        print("Road Tax: $daysRemaining days remaining");
        if (daysRemaining <= 30) {
          count++;
        }
      }

      if (car.medicalToolkit != null && car.medicalToolkit!.isNotEmpty) {
        int daysRemaining = car.medicalToolkitDaysRemaining;
        print("Medical Toolkit: $daysRemaining days remaining");
        if (daysRemaining <= 30) {
          count++;
        }
      }

      if (car.fireExtinguisher != null && car.fireExtinguisher!.isNotEmpty) {
        int daysRemaining = car.fireExtinguisherDaysRemaining;
        print("Fire Extinguisher: $daysRemaining days remaining");
        if (daysRemaining <= 30) {
          count++;
        }
      }

      if (car.others != null && car.others!.isNotEmpty) {
        int daysRemaining = car.othersDaysRemaining;
        print("Others: $daysRemaining days remaining");
        if (daysRemaining <= 30) {
          count++;
        }
      }
    }

    print('Notification count updated: $count, unread: $unreadNotifications');
    
    await loadUnreadNotificationCount();

    if (count > unreadNotifications) {
      saveUnreadNotificationCount(count);
      setState(() {
        unreadNotifications = count;
      });
    }

    if (unreadNotifications > count) {
       saveUnreadNotificationCount(count);
      setState(() {
        unreadNotifications = count;
      });
    }


    setState(() {
      notificationCount = count;
    });
  }

  Future<void> loadUnreadNotificationCount() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      unreadNotifications =
          prefs.getInt('unread_notifications') ?? notificationCount;
    });
  }

  void saveUnreadNotificationCount(int count) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('unread_notifications', count);
  }

  void markNotificationAsRead() async {
    setState(() {
      unreadNotifications = 0;
    });
    saveUnreadNotificationCount(0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Auto Alert',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black,
            letterSpacing: 2,
          ),
        ),
        centerTitle: true,

        actions: [
          
          IconButton(
            icon: Icon(Icons.car_crash_outlined, color: Colors.black, size: 30),
            onPressed: () async {
              // await DatabaseHelper().deleteValues(
              //   carSelected?.numberPlate ?? '',
              // );
            },
          ),

          SizedBox(width: 10),

          Stack(
            children: [
              IconButton(
                icon: Icon(
                  Icons.notifications_none,
                  color: Colors.black,
                  size: 30,
                ),
                onPressed: () async {
                  markNotificationAsRead();

                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => NotificationsPage(),
                    ),
                  ).then((_) {
                    updateNotificationCount();
                  });

                  
                },
              ),

              if (unreadNotifications > 0)
                Positioned(
                  right: 3,
                  top: 3,
                  child: Container(
                    padding: EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.red[600],
                      shape: BoxShape.circle,
                    ),
                    constraints: BoxConstraints(minWidth: 20, minHeight: 18),
                    child: Text(
                      unreadNotifications > 9
                          ? unreadNotifications.toString()
                          : '9+',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        ],
        leading: IconButton(
          icon: Icon(Icons.person_outline, color: Colors.black, size: 30),
          onPressed: () async {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => ProfilePage()),
            );
          },
        ),
      ),

      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: cars.isEmpty
                  ? Center(
                      child: Text(
                        'Nu există mașini adăugate. Adaugă una!',
                        style: TextStyle(fontSize: 15),
                      ),
                    )
                  : ListView.builder(
                      itemCount: cars.length,
                      itemBuilder: (context, index) {
                        final car = cars[index];
                        return Card(
                          margin: EdgeInsets.symmetric(vertical: 8),
                          child: ListTile(
                            title: Text(
                              car.numberPlate,
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(car.model ?? 'Model necunoscut'),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: Icon(Icons.edit, color: Colors.blue),
                                  onPressed: () => _editCarAttributes(car),
                                ),
                                IconButton(
                                  icon: Icon(Icons.delete, color: Colors.red),
                                  onPressed: () async {
                                    await DatabaseHelper().deleteCar(
                                      car.numberPlate,
                                    );

                                    Navigator.pushReplacement(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) {
                                          return HomePage();
                                        },
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                            onTap: () {
                              setState(() {
                                carSelected = car;
                              });
                            },
                          ),
                        );
                      },
                    ),
            ),
            Stack(
              children: [
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.all(Radius.circular(50)),
                        ),
                        child: BottomNavigationBar(
                          backgroundColor: Colors.grey[100],
                          type: BottomNavigationBarType.fixed,

                          selectedLabelStyle: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                          unselectedLabelStyle: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.normal,
                          ),

                          currentIndex: currentPage,
                          onTap: (value) {
                            setState(() {
                              currentPage = value;
                            });
                          },
                          selectedItemColor: Colors.blue,
                          items: <BottomNavigationBarItem>[
                            BottomNavigationBarItem(
                              icon: Icon(Icons.home),
                              label: 'Acasa',
                            ),

                            BottomNavigationBarItem(
                              icon: Icon(Icons.bar_chart_outlined),
                              label: 'Finante',
                            ),

                            BottomNavigationBarItem(
                              icon: Icon(Icons.list_alt_outlined),
                              label: 'Documente',
                            ),

                            BottomNavigationBarItem(
                              icon: Icon(Icons.more_horiz_outlined),
                              label: 'Mai multe',
                            ),
                          ],
                        ),
                      ),
                      Positioned(
                        top: -35,
                        left: MediaQuery.of(context).size.width / 2 - 40,
                        child: FloatingActionButton(
                          onPressed: () {
                            addCars();
                          },
                          backgroundColor: Colors.blue,
                          child: Icon(
                            Icons.add_rounded,
                            color: Colors.white,
                            size: 40,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
