import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../utils/password_hasher.dart';
import 'database_constants.dart';

class AppDatabase {
  static AppDatabase? _instance;
  static Database? _database;

  AppDatabase._internal();

  factory AppDatabase() {
    _instance ??= AppDatabase._internal();
    return _instance!;
  }

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    String path;
    if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
      final docDir = await getApplicationSupportDirectory();
      path = join(docDir.path, DatabaseConstants.dbName);
    } else {
      path = join(await getDatabasesPath(), DatabaseConstants.dbName);
    }

    return await openDatabase(
      path,
      version: DatabaseConstants.dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON;');
      },
    );
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute(
        'ALTER TABLE ${DatabaseConstants.tableVehicles} ADD COLUMN image_path TEXT;',
      );
    }
    if (oldVersion < 3) {
      await db.execute(
        'ALTER TABLE ${DatabaseConstants.tableSales} ADD COLUMN notes TEXT;',
      );
    }
    if (oldVersion < 4) {
      await db.execute(
        'ALTER TABLE ${DatabaseConstants.tableVehicles} ADD COLUMN sale_price REAL DEFAULT 0.0;',
      );
    }

    // Ensure official default business profile is populated
    try {
      final existingProfiles = await db.query(DatabaseConstants.tableBusinessProfile);
      if (existingProfiles.isEmpty) {
        final now = DateTime.now().toIso8601String();
        await db.insert(DatabaseConstants.tableBusinessProfile, {
          'id': 1,
          'business_name': "BROTHER'S AUTO CONSULTING",
          'address': '#4, 100 Feet Road, Abirami Nagar, Udumalpet, Tiruppur (Dt.), 642126',
          'phone': '+91 9578940360, +91 8072663566',
          'email': null,
          'gst_number': null,
          'updated_at': now,
        });
      } else if (existingProfiles.first['business_name'] == 'Vehicle Consulting Office') {
        await db.update(
          DatabaseConstants.tableBusinessProfile,
          {
            'business_name': "BROTHER'S AUTO CONSULTING",
            'address': '#4, 100 Feet Road, Abirami Nagar, Udumalpet, Tiruppur (Dt.), 642126',
            'phone': '+91 9578940360, +91 8072663566',
          },
          where: 'id = 1',
        );
      }
    } catch (_) {}
  }

  Future<void> _onCreate(Database db, int version) async {
    // 1. Users table
    await db.execute('''
      CREATE TABLE ${DatabaseConstants.tableUsers} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT UNIQUE NOT NULL,
        password_hash TEXT NOT NULL,
        passkey_hash TEXT NOT NULL,
        role TEXT NOT NULL,
        is_active INTEGER NOT NULL DEFAULT 1,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // Seed default admin and staff users
    final now = DateTime.now().toIso8601String();
    final adminPassHash = PasswordHasher.hash('admin123');
    final staffPassHash = PasswordHasher.hash('staff123');
    final passkeyHash = PasswordHasher.hash('1234');

    await db.insert(DatabaseConstants.tableUsers, {
      'username': 'admin',
      'password_hash': adminPassHash,
      'passkey_hash': passkeyHash,
      'role': 'admin',
      'is_active': 1,
      'created_at': now,
      'updated_at': now,
    });

    await db.insert(DatabaseConstants.tableUsers, {
      'username': 'staff',
      'password_hash': staffPassHash,
      'passkey_hash': passkeyHash,
      'role': 'staff',
      'is_active': 1,
      'created_at': now,
      'updated_at': now,
    });

    // 2. Business Profile table
    await db.execute('''
      CREATE TABLE ${DatabaseConstants.tableBusinessProfile} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        business_name TEXT NOT NULL,
        address TEXT NOT NULL,
        phone TEXT NOT NULL,
        email TEXT,
        gst_number TEXT,
        updated_at TEXT NOT NULL
      )
    ''');

    // Seed official default business profile
    await db.insert(DatabaseConstants.tableBusinessProfile, {
      'id': 1,
      'business_name': "BROTHER'S AUTO CONSULTING",
      'address': '#4, 100 Feet Road, Abirami Nagar, Udumalpet, Tiruppur (Dt.), 642126',
      'phone': '+91 9578940360, +91 8072663566',
      'email': null,
      'gst_number': null,
      'updated_at': now,
    });

    // 3. Vehicles table
    await db.execute('''
      CREATE TABLE ${DatabaseConstants.tableVehicles} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        vehicle_number TEXT UNIQUE NOT NULL,
        vehicle_name TEXT NOT NULL,
        vehicle_model TEXT NOT NULL,
        vehicle_type TEXT NOT NULL,
        owner_name TEXT NOT NULL,
        owner_phone TEXT NOT NULL,
        manufacturing_year INTEGER NOT NULL,
        registration_year INTEGER NOT NULL,
        purchase_date TEXT NOT NULL,
        purchase_amount REAL NOT NULL,
        payment_method TEXT NOT NULL,
        reference_name TEXT,
        commission_amount REAL DEFAULT 0.0,
        sale_price REAL DEFAULT 0.0,
        status TEXT NOT NULL,
        notes TEXT,
        image_path TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // 4. Expenses table
    await db.execute('''
      CREATE TABLE ${DatabaseConstants.tableExpenses} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        vehicle_id INTEGER NOT NULL,
        expense_title TEXT NOT NULL,
        description TEXT,
        amount REAL NOT NULL,
        expense_date TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (vehicle_id) REFERENCES ${DatabaseConstants.tableVehicles} (id) ON DELETE CASCADE
      )
    ''');

    // 5. Sales table
    await db.execute('''
      CREATE TABLE ${DatabaseConstants.tableSales} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        vehicle_id INTEGER UNIQUE NOT NULL,
        customer_name TEXT NOT NULL,
        customer_phone TEXT NOT NULL,
        sale_date TEXT NOT NULL,
        payment_type TEXT NOT NULL,
        is_emi INTEGER NOT NULL DEFAULT 0,
        finance_name TEXT,
        total_amount REAL NOT NULL,
        notes TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (vehicle_id) REFERENCES ${DatabaseConstants.tableVehicles} (id) ON DELETE CASCADE
      )
    ''');

    // 6. Payments table
    await db.execute('''
      CREATE TABLE ${DatabaseConstants.tablePayments} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        vehicle_id INTEGER NOT NULL,
        sale_id INTEGER NOT NULL,
        amount REAL NOT NULL,
        payment_date TEXT NOT NULL,
        payment_method TEXT NOT NULL,
        notes TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY (vehicle_id) REFERENCES ${DatabaseConstants.tableVehicles} (id) ON DELETE CASCADE,
        FOREIGN KEY (sale_id) REFERENCES ${DatabaseConstants.tableSales} (id) ON DELETE CASCADE
      )
    ''');

    // Indexes
    await db.execute('CREATE INDEX idx_vehicles_number ON ${DatabaseConstants.tableVehicles} (vehicle_number);');
    await db.execute('CREATE INDEX idx_vehicles_status ON ${DatabaseConstants.tableVehicles} (status);');
    await db.execute('CREATE INDEX idx_expenses_vehicle_id ON ${DatabaseConstants.tableExpenses} (vehicle_id);');
    await db.execute('CREATE INDEX idx_sales_vehicle_id ON ${DatabaseConstants.tableSales} (vehicle_id);');
    await db.execute('CREATE INDEX idx_payments_vehicle_id ON ${DatabaseConstants.tablePayments} (vehicle_id);');
  }
}
