/// Shared contract every feature repository follows: local reads never
/// block on network; refresh() opportunistically pulls fresh data from the
/// backend and upserts it into the local Drift store, which watchAll()
/// streams back out. Kept as a thin interface rather than shared base-class
/// logic because each table's upsert shape differs enough that a generic
/// implementation would fight Drift's typed API more than it would save.
abstract class OfflineRepository<T> {
  Stream<List<T>> watchAll();
  Future<void> refresh();
}
