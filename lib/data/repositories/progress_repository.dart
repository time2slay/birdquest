import 'package:drift/drift.dart';

import '../database/app_database.dart';

/// A daily quest the user completed.
class QuestCompletion {
  const QuestCompletion({
    required this.day,
    required this.questId,
    required this.xp,
  });

  /// Local date, 'yyyy-mm-dd'.
  final String day;
  final String questId;
  final int xp;
}

/// Local date key used for daily quests, e.g. '2026-10-15'.
String dayKey(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-'
    '${d.month.toString().padLeft(2, '0')}-'
    '${d.day.toString().padLeft(2, '0')}';

/// Quest completions and listening time.
class ProgressRepository {
  ProgressRepository(this._db);
  final AppDatabase _db;

  Stream<List<QuestCompletion>> watchCompletions() => _db
      .select(_db.questCompletions)
      .watch()
      .map(
        (rows) => [
          for (final r in rows)
            QuestCompletion(day: r.day, questId: r.questId, xp: r.xp),
        ],
      );

  /// Records a completion once; returns false if it was already recorded.
  Future<bool> recordCompletion(String day, String questId, int xp) =>
      _db.transaction(() async {
        final existing =
            await (_db.select(_db.questCompletions)
                  ..where((q) => q.day.equals(day) & q.questId.equals(questId)))
                .getSingleOrNull();
        if (existing != null) return false;
        await _db
            .into(_db.questCompletions)
            .insert(
              QuestCompletionsCompanion.insert(
                day: day,
                questId: questId,
                xp: xp,
                completedAt: DateTime.now(),
              ),
            );
        return true;
      });

  /// Seconds spent listening (non-demo, finished sessions) since [from].
  Stream<int> watchListeningSeconds(DateTime from) {
    final q = _db.select(_db.sessions)
      ..where(
        (s) =>
            s.isDemo.equals(false) &
            s.endedAt.isNotNull() &
            s.startedAt.isBiggerOrEqualValue(from),
      );
    return q.watch().map(
      (rows) => rows.fold(
        0,
        (sum, s) => sum + s.endedAt!.difference(s.startedAt).inSeconds,
      ),
    );
  }
}
