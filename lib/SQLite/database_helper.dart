import 'package:auto_alert/SQLite/Cars.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  late Future<Database> _db;
  bool _isDbInitialized = false;

  String dbName = "auto_alert.db";
  String cars = "cars";

  Future<Database> get database async {
    if (!_isDbInitialized) {
      _db = initDB();
      _isDbInitialized = true;
    }
    return _db;
  }

  Future<Database> initDB() async {
    String path = await getDatabasesPath();
    return await openDatabase(
      join(path, dbName),
      version: 1,
      onCreate: _onCreate,
      onOpen: (db) async {},
    );
  }

  Future<void> insertNewCar(Cars car) async {
    final db = await initDB();
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      throw Exception('User not authenticated');
    }
    
    Map<String, dynamic> carMap = car.toMap();
    carMap['userId'] = currentUser.uid;
    
    await db.insert("cars", carMap);
    return;
  }

  Future<List<Map<String, dynamic>>> getCars() async {
    final db = await database;
    final currentUser = FirebaseAuth.instance.currentUser;
    
    if (currentUser == null) {
      return [];
    }
    
    return await db.query(
      cars,
      where: 'userId = ?',
      whereArgs: [currentUser.uid],
    );
  }


  Future<int> updateCar(int id, Map<String, dynamic> car) async {
    final db = await database;
    final currentUser = FirebaseAuth.instance.currentUser;
    
    if (currentUser == null) {
      throw Exception('User not authenticated');
    }
    
    return await db.update(
      'cars',
      car,
      where: 'id = ? AND userId = ?',
      whereArgs: [id, currentUser.uid],
    );
  }

  Future<void> deleteValues(String numberPlate) async {
    final db = await database;
    final currentUser = FirebaseAuth.instance.currentUser;
    
    if (currentUser == null) {
      throw Exception('User not authenticated');
    }
    
    await db.delete(
      "cars", 
      where: 'numberPlate = ? AND userId = ?', 
      whereArgs: [numberPlate, currentUser.uid]
    );
  }


  Future<void> insertAdditionalFields({
    required String numberPlate,
    String? casco,
    String? oilMileage,
    String? medicalToolkit,
    String? fireExtinguisher,
    String? others,
  }) async {
    final db = await database;
    final currentUser = FirebaseAuth.instance.currentUser;
    
    if (currentUser == null) {
      throw Exception('User not authenticated');
    }

    Map<String, dynamic> updateFields = {};

    if (casco != null && casco.isNotEmpty) {
      updateFields['casco'] = casco;
    }
    if (oilMileage != null && oilMileage.isNotEmpty) {
      updateFields['oilMileage'] = oilMileage;
    }
    if (medicalToolkit != null && medicalToolkit.isNotEmpty) {
      updateFields['medicalToolkit'] = medicalToolkit;
    }
    if (fireExtinguisher != null && fireExtinguisher.isNotEmpty) {
      updateFields['fireExtinguisher'] = fireExtinguisher;
    }
    if (others != null && others.isNotEmpty) {
      updateFields['others'] = others;
    }

    if (updateFields.isNotEmpty) {
      await db.update(
        cars,
        updateFields,
        where: 'numberPlate = ?',
        whereArgs: [numberPlate],
      );
    }
  }

  Future<List<Map<String, dynamic>>> getAdditionalFields(
    String numberPlate,
  ) async {
    final db = await database;
    final currentUser = FirebaseAuth.instance.currentUser;
    
    if (currentUser == null) {
      return [];
    }

    return await db.query(
      cars,
      columns: [
        'casco',
        'oilMileage',
        'medicalToolkit',
        'fireExtinguisher',
        'others',
      ],
      where: 'numberPlate = ?',
      whereArgs: [numberPlate],
    );
  }

  Future<void> deleteCar(String numberPlate) async {
    final db = await database;
    final currentUser = FirebaseAuth.instance.currentUser;
    
    if (currentUser == null) {
      throw Exception('User not authenticated');
    }
    
    await db.delete(
      cars, 
      where: 'numberPlate = ? AND userId = ?', 
      whereArgs: [numberPlate, currentUser.uid]
    );
  }


  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $cars (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        userId TEXT NOT NULL,
        numberPlate TEXT NOT NULL,
        model TEXT,
        year INTEGER,
        fuelType TEXT,
        insuranceExpiry TEXT,
        technicalInspectionExpiry TEXT,
        roadTaxExpiry TEXT,
        casco TEXT,
        oilMileage TEXT,
        medicalToolkit TEXT,
        fireExtinguisher TEXT,
        others TEXT
      )
    ''');
  }

  void deleteDB() async {
    String path = join(await getDatabasesPath(), 'auto_alert.db');
    await deleteDatabase(path);
    print("Database deleted successfully");
  }
}
