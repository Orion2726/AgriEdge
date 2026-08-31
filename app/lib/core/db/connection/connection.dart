import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3_flutter_libs/sqlite3_flutter_libs.dart';

/// Native (Android/iOS/macOS/Linux/Windows) drift connection. The app targets
/// mobile in production; desktop is used here for fast local verification.
/// Web is intentionally unsupported — this app is not meant to run in a
/// browser, offline-first mobile is the point.
QueryExecutor openConnection() {
  return LazyDatabase(() async {
    await applyWorkaroundToOpenSqlite3OnOldAndroidVersions();
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'agriedge.sqlite'));
    return NativeDatabase.createInBackground(file, setup: (db) {
      db.execute('PRAGMA foreign_keys = ON;');
    });
  });
}
