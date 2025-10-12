import 'package:intl/intl.dart';

class Cars {
  int? id;
  String? userId;
  String numberPlate;
  String? model;
  int? year;
  String? fuelType;
  String? insuranceExpiry;
  String? technicalInspectionExpiry;
  String? roadTaxExpiry;
  String? casco;
  String? oilMileage;
  String? medicalToolkit;
  String? fireExtinguisher;
  String? others;

  Map<String, String> additionalFields = {};
  

  Cars({
    this.id,
    this.userId,
    required this.numberPlate,
    required this.model,
    required this.year,
    required this.fuelType,
    required this.insuranceExpiry,
    required this.technicalInspectionExpiry,
    required this.roadTaxExpiry,
    this.casco,
    this.oilMileage,
    this.medicalToolkit,
    this.fireExtinguisher,
    this.others,
  });


  int daysRemaining(String? expiryDate) {
    if (expiryDate == null || expiryDate.isEmpty)
      return -1; 
    try {
      DateTime expiryDateTime = DateFormat(
        'dd.MM.yyyy',
      ).parse(expiryDate); 
      DateTime currentDateTime = DateTime.now(); 
      return expiryDateTime
          .difference(currentDateTime)
          .inDays;
    } catch (e) {
      print('Invalid date format: $expiryDate');
      return -1;
    }
  }

  int get insuranceDaysRemaining => daysRemaining(insuranceExpiry);
  int get technicalInspectionDaysRemaining =>
      daysRemaining(technicalInspectionExpiry);
  int get roadTaxDaysRemaining => daysRemaining(roadTaxExpiry);
  int get cascoDaysRemaining => daysRemaining(casco);
  int get oilMileageDaysRemaining => daysRemaining(oilMileage);
  int get medicalToolkitDaysRemaining =>
      daysRemaining(medicalToolkit);
  int get fireExtinguisherDaysRemaining =>
      daysRemaining(fireExtinguisher);
  int get othersDaysRemaining => daysRemaining(others);




  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'numberPlate': numberPlate,
      'model': model,
      'year': year,
      'fuelType': fuelType,
      'insuranceExpiry': insuranceExpiry,
      'technicalInspectionExpiry': technicalInspectionExpiry,
      'roadTaxExpiry': roadTaxExpiry,
      'casco': additionalFields['CASCO'],
      'oilMileage': additionalFields['Oil Mileage'],
      'medicalToolkit': additionalFields['Medical Toolkit'],
      'fireExtinguisher': additionalFields['Fire Extinguisher'],
      'others': additionalFields['Others'],
    };
  }

  factory Cars.fromMap(Map<String, dynamic> map) {
    return Cars(
      id: map['id'],
      userId: map['userId'],
      numberPlate: map['numberPlate'],
      model: map['model'],
      year: map['year'] is int
          ? map['year']
          : int.tryParse(map['year'].toString()),
      fuelType: map['fuelType'],
      insuranceExpiry: map['insuranceExpiry'],
      technicalInspectionExpiry: map['technicalInspectionExpiry'],
      roadTaxExpiry: map['roadTaxExpiry'],
      casco: map['casco'],
      oilMileage: map['oilMileage'],
      medicalToolkit: map['medicalToolkit'],
      fireExtinguisher: map['fireExtinguisher'],
      others: map['others'],
    );
  }
}
