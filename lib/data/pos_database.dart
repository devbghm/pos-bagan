import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../models/pos_models.dart';

class PosDatabase {
  PosDatabase._();
  static final PosDatabase instance = PosDatabase._();

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    final dbPath = await getDatabasesPath();
    _database = await openDatabase(
      p.join(dbPath, 'pos_bagan.db'),
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE products (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            category TEXT NOT NULL DEFAULT '',
            price INTEGER NOT NULL CHECK(price >= 0)
          )
        ''');
        await db.execute('''
          CREATE TABLE sales (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            total INTEGER NOT NULL CHECK(total >= 0),
            created_at TEXT NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE sale_items (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            sale_id INTEGER NOT NULL,
            product_id INTEGER,
            product_name TEXT NOT NULL,
            unit_price INTEGER NOT NULL,
            quantity INTEGER NOT NULL CHECK(quantity > 0),
            FOREIGN KEY(sale_id) REFERENCES sales(id) ON DELETE CASCADE
          )
        ''');
        await db.execute('''
          CREATE TABLE settings (
            key TEXT PRIMARY KEY,
            value TEXT NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE teams (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL UNIQUE,
            color TEXT NOT NULL DEFAULT '#8A4B18'
          )
        ''');
        await db.execute('''
          CREATE TABLE tables (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            label TEXT NOT NULL UNIQUE,
            team_name TEXT NOT NULL DEFAULT '',
            occupied INTEGER NOT NULL DEFAULT 0
          )
        ''');

        await db.insert('settings', {'key': 'business_name', 'value': 'POS Bagan'});
        await db.insert('settings', {'key': 'currency', 'value': 'MMK'});

        await db.insert('teams', {'name': 'General', 'color': '#8A4B18'});
        for (var i = 0; i < 100; i++) {
          final label = i.toString().padLeft(2, '0');
          await db.insert('tables', {
            'label': label,
            'team_name': 'General',
            'occupied': 0,
          });
        }
      },
    );
    return _database!;
  }

  Future<List<Product>> getProducts() async {
    final rows = await (await database).query('products', orderBy: 'name COLLATE NOCASE');
    return rows.map(Product.fromMap).toList();
  }

  Future<int> addProduct(Product product) async =>
      (await database).insert('products', product.toMap());

  Future<void> deleteProduct(int id) async {
    await (await database).delete('products', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<PosTeam>> getTeams() async {
    final rows = await (await database).query('teams', orderBy: 'name COLLATE NOCASE');
    return rows.map(PosTeam.fromMap).toList();
  }

  Future<int> addTeam(PosTeam team) async =>
      (await database).insert('teams', team.toMap());

  Future<List<PosTable>> getTables() async {
    final rows = await (await database).query('tables', orderBy: 'label');
    return rows.map(PosTable.fromMap).toList();
  }

  Future<int> addTable(PosTable table) async =>
      (await database).insert('tables', table.toMap());

  Future<void> updateTable(PosTable table) async {
    if (table.id == null) return;
    await (await database).update(
      'tables',
      table.toMap(),
      where: 'id = ?',
      whereArgs: [table.id],
    );
  }

  Future<int> saveSale(List<CartLine> lines) async {
    if (lines.isEmpty) throw ArgumentError('Cannot save an empty sale.');
    final db = await database;
    return db.transaction((txn) async {
      final total = lines.fold<int>(0, (sum, line) => sum + line.total);
      final saleId = await txn.insert('sales', {
        'total': total,
        'created_at': DateTime.now().toUtc().toIso8601String(),
      });
      final batch = txn.batch();
      for (final line in lines) {
        batch.insert('sale_items', {
          'sale_id': saleId,
          'product_id': line.product.id,
          'product_name': line.product.name,
          'unit_price': line.product.price,
          'quantity': line.quantity,
        });
      }
      await batch.commit(noResult: true);
      return saleId;
    });
  }

  Future<List<SaleSummary>> getRecentSales({int limit = 30}) async {
    final rows = await (await database).query('sales', orderBy: 'id DESC', limit: limit);
    return rows.map(SaleSummary.fromMap).toList();
  }

  Future<Map<String, String>> getSettings() async {
    final rows = await (await database).query('settings');
    return {for (final row in rows) row['key'] as String: row['value'] as String};
  }

  Future<void> saveSettings({required String businessName, required String currency}) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.insert(
        'settings',
        {'key': 'business_name', 'value': businessName},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      await txn.insert(
        'settings',
        {'key': 'currency', 'value': currency},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    });
  }
}
