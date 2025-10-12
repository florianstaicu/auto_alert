import 'package:auto_alert/Pages/detailsForCar.dart';
import 'package:auto_alert/Pages/home.dart';
import 'package:auto_alert/SQLite/Cars.dart';
import 'package:auto_alert/SQLite/database_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class InsertingNewCar extends StatefulWidget {
  const InsertingNewCar({super.key, required this.car});
  final Cars car;

  @override
  State<InsertingNewCar> createState() => _InsertingNewCarStateState();
}

List<Cars> cars = [];
DateTime? _selectedDate;
String? selectedValue;

class _InsertingNewCarStateState extends State<InsertingNewCar> {
  List<Widget> additionalFields = [];
  late List<TextEditingController> additionalControllers;

  List<Map<String, dynamic>> othersFields = [];
  int othersId = 0;

  late TextEditingController numberPlateController;
  late TextEditingController modelController;
  late TextEditingController yearController;
  late TextEditingController fuelTypeController;
  late TextEditingController insuranceExpiryController;
  late TextEditingController technicalInspectionExpiryController;
  late TextEditingController roadTaxExpiryController;

  @override
  void initState() {
    super.initState();
    numberPlateController = TextEditingController(text: widget.car.numberPlate);
    modelController = TextEditingController(text: widget.car.model);
    yearController = TextEditingController(
      text: widget.car.year?.toString() ?? '',
    );
    fuelTypeController = TextEditingController(text: widget.car.fuelType);
    insuranceExpiryController = TextEditingController(
      text: widget.car.insuranceExpiry,
    );
    technicalInspectionExpiryController = TextEditingController(
      text: widget.car.technicalInspectionExpiry,
    );
    roadTaxExpiryController = TextEditingController(
      text: widget.car.roadTaxExpiry,
    );

    additionalControllers = List.generate(
      4,
      (index) => TextEditingController(),
    );

    loadAdditionalFields();
  }

  @override
  void dispose() {
    numberPlateController.dispose();
    modelController.dispose();
    yearController.dispose();
    fuelTypeController.dispose();
    insuranceExpiryController.dispose();
    technicalInspectionExpiryController.dispose();
    roadTaxExpiryController.dispose();

    for (var controller in additionalControllers) {
      controller.dispose();
    }

    for(var field in othersFields){ 
      field['controller'].dispose();
    }

    super.dispose();
  }

  void saveCar(Cars car) async {
    car.numberPlate = numberPlateController.text.trim();
    car.model = modelController.text.trim();
    car.year = int.tryParse(yearController.text.trim());
    car.fuelType = fuelTypeController.text.trim();
    car.insuranceExpiry = insuranceExpiryController.text.trim();
    car.technicalInspectionExpiry = technicalInspectionExpiryController.text
        .trim();
    car.roadTaxExpiry = roadTaxExpiryController.text.trim();

    await DatabaseHelper().updateCar(car.id!, car.toMap());

    String othersValue = '';
    List<String> othersData = [];

    for (var field in othersFields) {
      if (field['controller'].text.trim().isNotEmpty) {
        othersData.add('${field['name']}|${field['controller'].text.trim()}');
      }
    }
    
    othersValue = othersData.join('##');


    await DatabaseHelper().insertAdditionalFields(
      numberPlate: car.numberPlate,
      casco: additionalControllers[0].text.trim(),
      oilMileage: additionalControllers[1].text.trim(),
      medicalToolkit: additionalControllers[2].text.trim(),
      fireExtinguisher: additionalControllers[3].text.trim(),
      others: othersValue,
    );

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => CarDetails(car: car)),
    ).then((_) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => HomePage()),
      );
    });
  }

  void loadCars() async {
    final carList = await DatabaseHelper().getCars();
    setState(() {
      cars = carList.map((car) => Cars.fromMap(car)).toList();
    });
    print("Loaded cars: $cars");
  }

  void loadAdditionalFields() async {
    final fields = await DatabaseHelper().getAdditionalFields(
      widget.car.numberPlate,
    );
    if (fields.isNotEmpty) {
      setState(() {
        additionalControllers[0].text = fields[0]['casco'] ?? '';
        additionalControllers[1].text = fields[0]['oilMileage'] ?? '';
        additionalControllers[2].text = fields[0]['medicalToolkit'] ?? '';
        additionalControllers[3].text = fields[0]['fireExtinguisher'] ?? '';

        String othersData = fields[0]['others'] ?? '';

      othersFields.clear();

        if (othersData.isNotEmpty) {
          if (othersData.contains('##')) {

            List<String> multipleFields = othersData.split('##');
            for (String fieldData in multipleFields) {
              if (fieldData.contains('|')) {
                List<String> parts = fieldData.split('|');
                if (parts.length >= 2) {
                  String fieldName = parts[0];
                  String fieldValue = parts[1];
                  
                  TextEditingController controller = TextEditingController(text: fieldValue);
                  othersFields.add({
                    'id': othersId++,
                    'name': fieldName,
                    'controller': controller,
                  });
                }
              }
            }
          } else if (othersData.contains('|')) {

            List<String> parts = othersData.split('|');
            String fieldName = parts[0];
            String fieldValue = parts[1];
            
            TextEditingController controller = TextEditingController(text: fieldValue);
            othersFields.add({
              'id': othersId++,
              'name': fieldName,
              'controller': controller,
            });
          } else if (othersData.isNotEmpty) {

            TextEditingController controller = TextEditingController(text: othersData);
            othersFields.add({
              'id': othersId++,
              'name': 'Others',
              'controller': controller,
            });
          }
        }

        additionalFields.clear();

        if (additionalControllers[0].text.isNotEmpty) {
          addFieldWidget('CASCO', 0);
        }
        if (additionalControllers[1].text.isNotEmpty) {
          addFieldWidget('Oil Mileage', 1);
        }
        if (additionalControllers[2].text.isNotEmpty) {
          addFieldWidget('Medical Toolkit', 2);
        }
        if (additionalControllers[3].text.isNotEmpty) {
          addFieldWidget('Fire Extinguisher', 3);
        }


        for(var field in othersFields) {
          addOthersFieldWidget(field['name'], field['id'], field['controller']);
        }
     
    });
    }
  }

  void addOthersFieldWidget(String fieldName, int fieldId, TextEditingController controller){
    Widget field = Padding(
      padding: const EdgeInsets.only(top: 12.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              decoration: InputDecoration(
                labelText: fieldName,
                hintText: 'DD.MM.YYYY',
                suffixIcon: IconButton(
                  icon: Icon(Icons.calendar_today),
                  onPressed: () {
                    _selectDate(context, controller);
                  },
                ),
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.delete, color: Colors.red),
            onPressed: () {
              setState(() {
                othersFields.removeWhere((field) => field['id'] == fieldId);
                additionalFields.removeWhere(
                  (widget) => widget.key == Key('others_$fieldId'),
                );
                controller.dispose();
              });
            },
          ),
        ],
      ),
    );

    additionalFields.add(Container(key: Key('others_$fieldId'), child: field));
  }

  void addFieldWidget(String fieldName, int controllerIndex) {
    Widget field = Padding(
      padding: const EdgeInsets.only(top: 12.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: additionalControllers[controllerIndex],
              decoration: InputDecoration(
                labelText: fieldName,
                hintText: 'DD.MM.YYYY',
                suffixIcon: IconButton(
                  icon: Icon(Icons.calendar_today),
                  onPressed: () {
                    _selectDate(
                      context,
                      additionalControllers[controllerIndex],
                    );
                  },
                ),
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.delete, color: Colors.red),
            onPressed: () {
              setState(() {
                othersFields.removeWhere((field) => field['id'] == controllerIndex);
                additionalFields.removeWhere(
                  (widget) => widget.key == Key('others_$controllerIndex'),
                );
                additionalControllers[controllerIndex].dispose();
              });
            },
          ),
        ],
      ),
    );

    additionalFields.add(Container(key: Key(fieldName), child: field));
  }

  void updateMoreExpiryItems() {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text('Adauga mai multe items'),
              content: DropdownButtonFormField(
                value: selectedValue,
                items: [
                  DropdownMenuItem(value: 'CASCO', child: Text('CASCO')),
                  DropdownMenuItem(
                    value: 'Oil Mileage',
                    child: Text('Oil Mileage'),
                  ),
                  DropdownMenuItem(
                    value: 'Medical Toolkit',
                    child: Text('Medical Toolkit'),
                  ),
                  DropdownMenuItem(
                    value: 'Fire Extinguisher',
                    child: Text('Fire Extinguisher'),
                  ),
                  DropdownMenuItem(
                    value: 'Others',
                    child: Text('Others'),
                  ),
                ],

                onChanged: (value) {
                  setDialogState(() {
                    selectedValue = value;
                  });
                },
                decoration: InputDecoration(labelText: 'Selectează un item'),
              ),

              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text('Închide'),
                ),
                TextButton(
                  onPressed: () async {
                    if (selectedValue != null) {
                      if (selectedValue == 'Others') {
                        Navigator.of(context).pop();
                        
                        othersCustomField();
                      } else {
                        addNewField(selectedValue!);
                        selectedValue = null;
                        Navigator.of(context).pop();
                      }
                    }
                  },
                  child: Text('Adaugă'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void othersCustomField() {
    TextEditingController customOthersController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Adaugă un câmp personalizat'),
          content: TextField(
            controller: customOthersController,
            decoration: InputDecoration(
              labelText: 'Numele câmpului',
              hintText: 'Alte preferinte de adaugat.',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Anuleaza'),
            ),
            TextButton(
              onPressed: () {
                if (customOthersController.text.trim().isNotEmpty) {
                  TextEditingController newController = TextEditingController();
                  int newId = othersId++;

                  setState(() {
                    othersFields.add({
                      'id': newId,
                      'name': customOthersController.text.trim(),
                      'controller': newController,
                    });
                    addOthersFieldWidget(
                      customOthersController.text.trim(),
                      newId,
                      newController,
                    );
                  });

                  Navigator.of(context).pop();
                }
              },
              child: Text('Adaugă'),
            ),
          ],
        );
      },
    );
  }

  void addNewField(String fieldName) {
    int controllerIndex;

    switch (fieldName) {
      case "CASCO":
        controllerIndex = 0;
        break;
      case "Oil Mileage":
        controllerIndex = 1;
        break;
      case "Medical Toolkit":
        controllerIndex = 2;
        break;
      case "Fire Extinguisher":
        controllerIndex = 3;
        break;
      default:
        controllerIndex = 4;
        break;
    }

    bool fieldExists = additionalFields.any(
      (widget) => widget.key == Key(fieldName),
    );

    if (!fieldExists) {
      setState(() {
        addFieldWidget(fieldName, controllerIndex);
      });
    }
  }

  void _selectDate(
    BuildContext context,
    TextEditingController controller,
  ) async {
    DateTime? newSelectedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.black,
              // onPrimary: Colors.white
            ),
          ),
          child: child ?? SizedBox.shrink(),
        );
      },
    );

    if (newSelectedDate != null) {
      _selectedDate = newSelectedDate;
      controller.text = DateFormat('dd.MM.yyyy').format(_selectedDate!);

      _selectedDate = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Detaliile masinii')),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: ListView(
          children: [
            TextField(
              controller: numberPlateController,
              decoration: InputDecoration(
                labelText: 'Număr de înmatriculare',
                icon: Icon(Icons.time_to_leave_rounded),
              ),
            ),
            TextField(
              controller: modelController,
              decoration: InputDecoration(labelText: 'Model'),
            ),
            TextField(
              controller: yearController,
              decoration: InputDecoration(labelText: 'An'),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: fuelTypeController,
              decoration: InputDecoration(labelText: 'Tip combustibil'),
            ),
            TextField(
              controller: insuranceExpiryController,
              decoration: InputDecoration(
                labelText: 'Expirare asigurare',
                hintText: 'DD.MM.YYYY',
                suffixIcon: IconButton(
                  icon: Icon(Icons.calendar_today),
                  onPressed: () {
                    _selectDate(context, insuranceExpiryController);
                  },
                ),
              ),
              inputFormatters: [LengthLimitingTextInputFormatter(10)],
            ),
            TextField(
              controller: technicalInspectionExpiryController,
              decoration: InputDecoration(
                labelText: 'Expirare ITP',
                hintText: 'DD.MM.YYYY',
                suffixIcon: IconButton(
                  icon: Icon(Icons.calendar_today),
                  onPressed: () {
                    _selectDate(context, technicalInspectionExpiryController);
                  },
                ),
              ),
              inputFormatters: [LengthLimitingTextInputFormatter(10)],
            ),
            TextField(
              controller: roadTaxExpiryController,
              decoration: InputDecoration(
                labelText: 'Expirare rovinietă',
                hintText: 'DD.MM.YYYY',
                suffixIcon: IconButton(
                  icon: Icon(Icons.calendar_today),
                  onPressed: () {
                    _selectDate(context, roadTaxExpiryController);
                  },
                ),
              ),
              inputFormatters: [LengthLimitingTextInputFormatter(10)],
            ),
            ...additionalFields,
            SizedBox(height: 10),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: Text('Anuleaza'),
                ),

                ElevatedButton(
                  onPressed: () async {
                    widget.car.numberPlate = numberPlateController.text.trim();
                    widget.car.model = modelController.text.trim();
                    widget.car.year = int.tryParse(yearController.text.trim());
                    widget.car.fuelType = fuelTypeController.text.trim();
                    widget.car.insuranceExpiry = insuranceExpiryController.text
                        .trim();
                    widget.car.technicalInspectionExpiry =
                        technicalInspectionExpiryController.text.trim();
                    widget.car.roadTaxExpiry = roadTaxExpiryController.text
                        .trim();

                    saveCar(widget.car);
                  },
                  child: Text('Salvează'),
                ),
              ],
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          updateMoreExpiryItems();
        },
        backgroundColor: Colors.grey[500],
        child: Icon(Icons.add_rounded, color: Colors.white, size: 40),
      ),
    );
  }
}
