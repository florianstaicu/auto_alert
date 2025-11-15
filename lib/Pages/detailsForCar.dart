import 'package:auto_alert/Pages/notificatiosPage.dart';
import 'package:auto_alert/SQLite/Cars.dart';
import 'package:auto_alert/SQLite/database_helper.dart';
import 'package:auto_alert/Services/notification_service.dart';
import 'package:flutter/material.dart';

class CarDetails extends StatefulWidget {
  final Cars car;

  const CarDetails({super.key, required this.car});

  @override
  State<CarDetails> createState() => _CarDetailsState();
}

class _CarDetailsState extends State<CarDetails> {
  
  List<Widget> additionalFields = [];
  late List<TextEditingController> additionalControllers;

  int notificationCount = 0;
  bool isDisposed = false;

  @override
  void initState() {
    super.initState();
    additionalControllers = List.generate(
      4,
      (index) => TextEditingController(),
    );

    loadAdditionalFields();
    updateNotificationCount();
  }

  @override
  void dispose() {
    isDisposed = true;
    for (var controller in additionalControllers) {
      controller.dispose();
    }

    super.dispose();
  }

  double getProgress(int daysLeft, int totalDays) {
    if (daysLeft <= 0) return 0.0;
    return daysLeft / totalDays;
  }

  Color getProgressColor(double progress) {
    if (progress >= 250.0 / 365.0) {
      return Colors.green;
    } else if (progress >= 150 / 365.0) {
      return Colors.lightGreen;
    } else if (progress >= 100 / 365.0) {
      return Colors.orange[300]!;
    } else if (progress >= 50 / 365.0) {
      return Colors.orange[700]!;
    } else {
      return Colors.red;
    }
  }

  void addFieldWidget(
    String fieldName,
    int controllerIndex,
    String expiryDate,
  ) {
    int daysRemaining = widget.car.daysRemaining(expiryDate);

    Widget field = Padding(
      padding: const EdgeInsets.only(top: 12.0),
      child: Column(
        children: [
          TextField(
            textAlign: TextAlign.start,
            decoration: InputDecoration(
              counterText: expiryDate,
              errorText: daysRemaining >= 0
                  ? 'Expira in: $daysRemaining zile'
                  : 'Expirat sau data invalida',
              labelText: fieldName,
              labelStyle: TextStyle(
                fontSize: 18,
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
              enabled: false,
            ),
          ),
          SizedBox(height: 10),
          Container(
            height: 10,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: Colors.grey[300],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: daysRemaining > 0
                    ? getProgress(daysRemaining, 365)
                    : 0.0,
                valueColor: AlwaysStoppedAnimation(
                  getProgressColor(getProgress(daysRemaining, 365)),
                ),
                backgroundColor: Colors.transparent,
              ),
            ),
          ),
          SizedBox(height: 20),
        ],
      ),
    );

    additionalFields.add(Container(key: Key(fieldName), child: field));
  }

  void addOtherFieldWidget(String fieldName, String expiryDate) {
    int daysRemaining = widget.car.daysRemaining(expiryDate);

    Widget field = Padding(
      padding: const EdgeInsets.only(top: 12.0),
      child: Column(
        children: [
          TextField(
            textAlign: TextAlign.start,
            decoration: InputDecoration(
              counterText: expiryDate,
              errorText: daysRemaining >= 0
                  ? 'Expira in: $daysRemaining zile'
                  : 'Expirat sau data invalida',
              labelText: fieldName,
              labelStyle: TextStyle(
                fontSize: 18,
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
              enabled: false,
            ),
          ),
          SizedBox(height: 10),
          Container(
            height: 10,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: Colors.grey[300],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: daysRemaining > 0
                    ? getProgress(daysRemaining, 365)
                    : 0.0,
                valueColor: AlwaysStoppedAnimation(
                  getProgressColor(getProgress(daysRemaining, 365)),
                ),
                backgroundColor: Colors.transparent,
              ),
            ),
          ),
          SizedBox(height: 20),
        ],
      ),
    );

    additionalFields.add(Container(key: Key(fieldName), child: field));
  }

  void loadAdditionalFields() async {

    if(isDisposed) return;

    final fields = await DatabaseHelper().getAdditionalFields(
      widget.car.numberPlate,
    );

    if(isDisposed) return;

    if (fields.isNotEmpty) {
      setState(() {
        final additionalData = {
          'CASCO': fields[0]['casco'] ?? '',
          'Oil Mileage': fields[0]['oilMileage'] ?? '',
          'Medical Toolkit': fields[0]['medicalToolkit'] ?? '',
          'Fire Extinguisher': fields[0]['fireExtinguisher'] ?? '',
        };

        if (additionalControllers.length > 0 && !isDisposed) {
          additionalControllers[0].text = additionalData['CASCO']!;
          additionalControllers[1].text = additionalData['Oil Mileage']!;
          additionalControllers[2].text = additionalData['Medical Toolkit']!;
          additionalControllers[3].text = additionalData['Fire Extinguisher']!;
        }


        String othersData = fields[0]['others'] ?? '';

        additionalFields.clear();

        if (additionalControllers[0].text.isNotEmpty) {
          addFieldWidget('CASCO', 0, additionalControllers[0].text);
        }
        if (additionalControllers[1].text.isNotEmpty) {
          addFieldWidget('Oil Mileage', 1, additionalControllers[1].text);
        }
        if (additionalControllers[2].text.isNotEmpty) {
          addFieldWidget('Medical Toolkit', 2, additionalControllers[2].text);
        }
        if (additionalControllers[3].text.isNotEmpty) {
          addFieldWidget('Fire Extinguisher', 3, additionalControllers[3].text);
        }
        if (othersData.isNotEmpty) {
          if (othersData.contains('##')) {
            List<String> multipleFields = othersData.split('##');
            for (String field in multipleFields) {
              if (field.contains('|')) {
                List<String> parts = field.split('|');
                if (parts.length >= 2) {
                  String fieldName = parts[0];
                  String fieldValue = parts[1];
                  if (fieldValue.isNotEmpty) {
                    addOtherFieldWidget(fieldName, fieldValue);
                  }
                }
              }
            }
          } else if (othersData.contains('|')) {
            List<String> parts = othersData.split('|');
            String fieldName = parts[0];
            String fieldValue = parts[1];
            if (fieldValue.isNotEmpty) {
              addOtherFieldWidget(fieldName, fieldValue);
            }
          } else if (othersData.isNotEmpty) {
            addOtherFieldWidget('Others', othersData);
          }
        }
      });
    }
  }

  void updateNotificationCount() async {
    if (isDisposed) return;

    final count = await NotificationService().getCarNotificationCount(
      widget.car.numberPlate,
    );
    
    if (isDisposed) return;

    setState(() {
      notificationCount = count;
    });
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
            onPressed: () async {},
          ),

          SizedBox(width: 10),

          Stack(
            children: [
              IconButton(
                icon: Badge.count(
                  count: notificationCount,
                  child: Icon(
                    Icons.notifications_outlined,
                    color: Colors.black,
                    size: 30,
                  ),
                ),
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => NotificationsPage(),
                    ),
                  );
                  updateNotificationCount();
                },
              ),
              if (notificationCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    constraints: BoxConstraints(minWidth: 18, minHeight: 18),
                    child: Text(
                      notificationCount > 9
                          ? '9+'
                          : notificationCount.toString(),
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
      ),

      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                textAlign: TextAlign.start,
                decoration: InputDecoration(
                  icon: Image.asset(
                    'assets/photo_with_car.png',
                    width: 50,
                    // height: 50,
                  ),

                  suffixText: TextEditingController(
                    text: widget.car.numberPlate,
                  ).text,
                  // border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.all(20),
                ),

                controller: TextEditingController(text: widget.car.model),

                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
                enabled: false,
                readOnly: true,
              ),
              SizedBox(height: 20),

              TextField(
                textAlign: TextAlign.start,
                decoration: InputDecoration(
                  counterText: TextEditingController(
                    text: widget.car.insuranceExpiry,
                  ).text,
                  errorText:
                      'Expira in: ${widget.car.insuranceDaysRemaining} zile',
                  labelText: 'Asigurare',
                  labelStyle: TextStyle(
                    fontSize: 18,
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                  enabled: false,
                ),
              ),
              SizedBox(height: 10),
              Container(
                height: 10,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: Colors.grey[300],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: getProgress(widget.car.insuranceDaysRemaining, 365),
                    valueColor: AlwaysStoppedAnimation(
                      getProgressColor(
                        getProgress(widget.car.insuranceDaysRemaining, 365),
                      ),
                    ),
                    backgroundColor: Colors.transparent,
                  ),
                ),
              ),
              SizedBox(height: 20),

              TextField(
                textAlign: TextAlign.start,
                decoration: InputDecoration(
                  counterText: TextEditingController(
                    text: widget.car.technicalInspectionExpiry,
                  ).text,
                  errorText:
                      'Expira in: ${widget.car.technicalInspectionDaysRemaining} zile',
                  labelText: 'ITP',
                  labelStyle: TextStyle(
                    fontSize: 18,
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                  enabled: false,
                ),
              ),
              SizedBox(height: 10),
              Container(
                height: 10,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: Colors.grey[300],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: getProgress(
                      widget.car.technicalInspectionDaysRemaining,
                      365,
                    ),
                    valueColor: AlwaysStoppedAnimation(
                      getProgressColor(
                        getProgress(
                          widget.car.technicalInspectionDaysRemaining,
                          365,
                        ),
                      ),
                    ),
                    backgroundColor: Colors.transparent,
                  ),
                ),
              ),
              SizedBox(height: 20),

              TextField(
                textAlign: TextAlign.start,
                decoration: InputDecoration(
                  counterText: TextEditingController(
                    text: widget.car.roadTaxExpiry,
                  ).text,
                  errorText:
                      'Expira in: ${widget.car.roadTaxDaysRemaining} zile',
                  labelText: 'Rovinieta',
                  labelStyle: TextStyle(
                    fontSize: 18,
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                  enabled: false,
                ),
              ),
              SizedBox(height: 10),
              Container(
                height: 10,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: Colors.grey[300],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: getProgress(widget.car.roadTaxDaysRemaining, 365),
                    valueColor: AlwaysStoppedAnimation(
                      getProgressColor(
                        getProgress(widget.car.roadTaxDaysRemaining, 365),
                      ),
                    ),
                    backgroundColor: Colors.transparent,
                  ),
                ),
              ),
              SizedBox(height: 10),

              ...additionalFields,
            ],
          ),
        ),
      ),
    );
  }
}
