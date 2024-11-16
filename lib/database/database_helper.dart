import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';


class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('denomination.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE Summary (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT,
        description TEXT,
        total_counts INTEGER,
        grand_total INTEGER,
        category TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE Denomination (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        denomination TEXT,
        count INTEGER,
        total INTEGER,
        summary_id INTEGER,
        FOREIGN KEY (summary_id) REFERENCES Summary (id)
      )
    ''');
  }

  // Insert Summary and related Denominations
  Future<void> insertSummaryAndDenominations({
    required String date,
    required String description,
    required String category,
    required int totalCounts,
    required int grandTotal,
    required List<Denomination> denominations,
  }) async {
    final db = await DatabaseHelper.instance.database;

    // Insert Summary
    int summaryId = await db.insert('Summary', {
      'date': date,
      'description': description,
      'total_counts': totalCounts,
      'grand_total': grandTotal,
      'category': category,
    });

    // Insert Denominations
    for (var denom in denominations) {
      await db.insert('Denomination', {
        'denomination': denom.denomination,
        'count': denom.count,
        'total': denom.total,
        'summary_id': summaryId,
      });
    }
  }

  // Fetch Summary with related Denominations
  Future<List<SummaryWithDenominations>> fetchSummaryWithDenominations() async {
    final db = await DatabaseHelper.instance.database;

    final summaries = await db.query('Summary');

    List<SummaryWithDenominations> result = [];

    for (var summary in summaries) {
      int summaryId = summary['id'] as int;

      final denominations = await db.query(
        'Denomination',
        where: 'summary_id = ?',
        whereArgs: [summaryId],
      );

      List<Denomination> denominationList = denominations
          .map((denom) => Denomination.fromMap(denom))
          .toList();

      result.add(SummaryWithDenominations(
        summary: Summary.fromMap(summary),
        denominations: denominationList,
      ));
    }

    return result;
  }


  Future<void> deleteSummaryWithDenominations(int summaryId) async {
    final db = await database;

    // Start a transaction to ensure atomicity
    await db.transaction((txn) async {
      // Delete related Denominations
      await txn.delete(
        'Denomination',
        where: 'summary_id = ?',
        whereArgs: [summaryId],
      );

      // Delete the Summary
      await txn.delete(
        'Summary',
        where: 'id = ?',
        whereArgs: [summaryId],
      );
    });
  }


  Future<void> updateSummaryAndDenominations({
    required int summaryId,  // Pass the summaryId of the record you want to update
    required String date,
    required String description,
    required String category,
    required int totalCounts,
    required int grandTotal,
    required List<Denomination> denominations,
  }) async {
    final db = await DatabaseHelper.instance.database;

    // Update Summary
    await db.update(
      'Summary',
      {
        'date': date,
        'description': description,
        'total_counts': totalCounts,
        'grand_total': grandTotal,
        'category': category,
      },
      where: 'id = ?', // Condition to find the specific record to update
      whereArgs: [summaryId], // The summaryId that you want to update
    );

    // First, delete existing denominations related to the summaryId
    await db.delete(
      'Denomination',
      where: 'summary_id = ?', // Condition to find the related denominations
      whereArgs: [summaryId],
    );

    // Insert updated Denominations
    for (var denom in denominations) {
      await db.insert('Denomination', {
        'denomination': denom.denomination,
        'count': denom.count,
        'total': denom.total,
        'summary_id': summaryId,
      });
    }
  }


  Future<SummaryWithDenominations?> fetchSummaryWithDenominationsById(int id) async {
    final db = await DatabaseHelper.instance.database;

    // Fetch the specific summary by id
    final List<Map<String, dynamic>> summaries = await db.query(
      'Summary',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (summaries.isEmpty) {
      return null;
    }

    final summary = summaries.first;

    final List<Map<String, dynamic>> denominations = await db.query(
      'Denomination',
      where: 'summary_id = ?',  // Fetch denominations related to the given summary_id
      whereArgs: [id],
    );

    // Convert the fetched denominations to a list of Denomination objects
    List<Denomination> denominationList = denominations
        .map((denom) => Denomination.fromMap(denom))
        .toList();

    // Return a SummaryWithDenominations object containing the summary and its related denominations
    return SummaryWithDenominations(
      summary: Summary.fromMap(summary),
      denominations: denominationList,
    );
  }



  Future close() async {
    final db = await instance.database;
    db.close();
  }
}

class SummaryWithDenominations {
  final Summary summary;
  final List<Denomination> denominations;

  SummaryWithDenominations({required this.summary, required this.denominations});
}


class Summary {
  final int id;
  final String date;
  final String description;
  final String category;
  final int totalCounts;
  final int grandTotal;

  Summary({
    required this.id,
    required this.date,
    required this.description,
    required this.category,
    required this.totalCounts,
    required this.grandTotal,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date,
      'description': description,
      'category': category,
      'total_counts': totalCounts,
      'grand_total': grandTotal,
    };
  }

  factory Summary.fromMap(Map<String, dynamic> map) {
    return Summary(
      id: map['id'],
      date: map['date'],
      description: map['description'],
      category: map['category'],
      totalCounts: map['total_counts'],
      grandTotal: map['grand_total'],
    );
  }

  @override
  String toString() {
    return 'Summary(id: $id, date: $date, description: $description, totalCounts: $totalCounts, grandTotal: $grandTotal, category: $category)';
  }
}

class Denomination {
  final int id;
  final String denomination;
  final int count;
  final int total;
  final int summaryId;

  Denomination({
    required this.id,
    required this.denomination,
    required this.count,
    required this.total,
    required this.summaryId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'denomination': denomination,
      'count': count,
      'total': total,
      'summary_id': summaryId,
    };
  }

  factory Denomination.fromMap(Map<String, dynamic> map) {
    return Denomination(
      id: map['id'],
      denomination: map['denomination'],
      count: map['count'],
      total: map['total'],
      summaryId: map['summary_id'],
    );
  }

  @override
  String toString() {
    return 'Denomination(denomination: $denomination, count: $count, total: $total)';
  }
}


