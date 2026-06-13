# Drift Database

> Reference for: Flutter Expert  
> Load when: Database, Drift, SQLite, persistence, DAO, migrations  
> Docs: [https://drift.simonbinder.eu/](https://drift.simonbinder.eu/)

## Overview

Drift is a **reactive persistence library** for relational data in Dart/Flutter. Built on sqlite3, sqflite, etc. It provides:

- **Type safety**: Rows become typed Dart objects; no raw `List<Map<String, dynamic>>`.
- **Stream queries**: `select(...).watch()` gives auto-updating streams when data changes.
- **Fluent API**: `select(tables)`, `into(tables).insert()`, `update(tables).write()`.
- **Type-safe SQL**: Optional SQL with compile-time parsing and generated row types.
- **Migrations**: Helpers like `.createAllTables()`, migrator APIs.

## Setup

```yaml
# pubspec.yaml
dependencies:
  drift: ^2.30.0
  drift_flutter: ^0.2.8
  path_provider: ^2.1.5
  path: ^1.9.1

dev_dependencies:
  drift_dev: ^2.29.0
  build_runner: ^2.10.4
```

```bash
dart run build_runner build --delete-conflicting-outputs
```

## Defining Tables

```dart
import 'package:drift/drift.dart';

@DataClassName('NotesEntry')
class Notes extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get content => text()();
  DateTimeColumn get dueDate => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get deletedAt => dateTime().nullable()();
}
```

- Use `Table` and column getters: `integer()`, `text()`, `dateTime()`, `boolean()`, etc.
- `@DataClassName('X')` names the generated row class (default: table name in PascalCase).
- `.autoIncrement()`, `.nullable()`, `.withDefault(...)` as needed.

## Database Class

```dart
import 'package:drift/drift.dart';
import '../../../../claude/skills/flutter-expert/references/connection.dart';  // QueryExecutor factory
import '../../../../claude/skills/flutter-expert/references/notes.dart';
import '../../../../claude/skills/flutter-expert/references/notes_dao.dart';

part '../../../../claude/skills/flutter-expert/references/database.g.dart';

@DriftDatabase(tables: [Notes])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.queryExecutor);

  @override
  int get schemaVersion => 1;

  NotesDao get notesDao => NotesDao(this);
}

final database = AppDatabase(createConnection('notes0'));
```

- `@DriftDatabase(tables: [...])` lists all tables; `part '../../../../claude/skills/flutter-expert/references/database.g.dart'` is generated.
- Override `schemaVersion` for migrations.
- Expose DAOs as getters.

## Connection (Native / Web)

```dart
// connection.dart — conditional export per platform
export '../../../../claude/skills/flutter-expert/references/unsupported.dart'
    if (dart.library.js_interop) 'web.dart'
    if (dart.library.ffi) 'native.dart';

QueryExecutor createConnection(String name) => createDatabaseConnection(name);
```

```dart
// native.dart
import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

QueryExecutor createDatabaseConnection(String databaseName) {
  return LazyDatabase(() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, '$databaseName.sqlite'));
    return NativeDatabase(file);
  });
}
```

- Use `LazyDatabase` + `NativeDatabase(file)` for native; drift_flutter/web for web.

## DAOs (Data Access Objects)

```dart
import 'package:drift/drift.dart';
import '../../../../claude/skills/flutter-expert/references/database.dart';
import '../../../../claude/skills/flutter-expert/references/notes.dart';

part '../../../../claude/skills/flutter-expert/references/notes_dao.g.dart';

@DriftAccessor(tables: [Notes])
class NotesDao extends DatabaseAccessor<AppDatabase> with _$NotesDaoMixin {
  NotesDao(super.db);

  Future<List<NotesEntry>> getAllNotes() {
    return (select(notes)..where((t) => t.deletedAt.isNull())).get();
  }

  Stream<List<NotesEntry>> watchAllNotes() {
    return (select(notes)..where((t) => t.deletedAt.isNull())).watch();
  }

  Future<int> insertNote(NotesCompanion entry) {
    final now = DateTime.now();
    return into(notes).insert(
      entry.copyWith(createdAt: Value(now), updatedAt: Value(now)),
    );
  }

  Future<int> updateNote(int id, NotesCompanion entry) {
    final now = DateTime.now();
    return (update(notes)..where((t) => t.id.equals(id)))
        .write(entry.copyWith(updatedAt: Value(now)));
  }

  Future<int> deleteNote(int id) {
    return (delete(notes)..where((t) => t.id.equals(id))).go();
  }
}
```

- `@DriftAccessor(tables: [Notes])` + `DatabaseAccessor<AppDatabase>` + `_$NotesDaoMixin`.
- `select(table)`, `into(table).insert()`, `update(table).write()`, `delete(table).go()`.
- `.get()` → `Future`; `.watch()` → `Stream` (reactive).

## Companions (Insert / Update)

```dart
// Insert: use Companion to omit auto fields
await db.notesDao.insertNote(NotesCompanion(
  content: Value('Hello'),
  dueDate: Value.absentIfNull(null),
));

// Update: only set changed fields
await db.notesDao.updateNote(id, NotesCompanion(content: Value('Updated')));
```

- `Value(value)` or `Value.absent()` / `Value.absentIfNull(null)` for optional fields.

## Migrations

```dart
@override
int get schemaVersion => 2;

@override
MigrationStrategy get migration => MigrationStrategy(
  onCreate: (m) async {
    await m.createAll();
  },
  onUpgrade: (m, from, to) async {
    if (from < 2) {
      await m.addColumn(notes, notes.newColumn);
    }
  },
);
```

- Bump `schemaVersion`; implement `onUpgrade` for additive changes (new columns/tables).

## Quick Reference

| Task | API |
|------|-----|
| Table | `class X extends Table` with column getters |
| DB | `@DriftDatabase(tables: [...])`, `schemaVersion`, DAO getters |
| DAO | `@DriftAccessor(tables: [...])`, `select` / `into` / `update` / `delete` |
| One-shot query | `(...).get()` |
| Reactive query | `(...).watch()` |
| Insert | `into(table).insert(Companion)` |
| Update | `update(table).write(Companion)` + `where` |
| Delete | `delete(table).go()` + `where` |
| Native executor | `LazyDatabase(() => NativeDatabase(file))` |
| Codegen | `dart run build_runner build` |

## Constraints

- Run build_runner after changing tables/DAOs/database.
- Use `Companion` types for inserts/updates with partial fields.
- Prefer DAOs over raw SQL for type safety; use `customStatement` / SQL when needed.
- For schema changes, upgrade `schemaVersion` and implement `onUpgrade`.
