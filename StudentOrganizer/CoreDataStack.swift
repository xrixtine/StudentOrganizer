import CoreData
import os

/// Owns the app's single Core Data stack (data model + SQLite file + main context).
/// Every screen reads and writes through `CoreDataStack.shared`, so all of them work on
/// the same objects and every change ends up in one database file on the device.
final class CoreDataStack {

    static let shared = CoreDataStack()

    /// Loads StudentOrganizer.xcdatamodeld and opens (or creates) the SQLite store.
    let container: NSPersistentContainer

    /// The main-thread "scratchpad": objects are created, changed and deleted here,
    /// and nothing is permanent until `save()` is called.
    var context: NSManagedObjectContext { container.viewContext }

    /// Errors go to the system log (visible in Xcode's console) instead of print statements.
    private let logger = Logger(subsystem: "com.interlink.studentorganizer", category: "CoreData")

    private init() {
        // The name must match the .xcdatamodeld file name, not the app's product name.
        container = NSPersistentContainer(name: "StudentOrganizer")
        container.loadPersistentStores { _, error in
            if let error = error {
                // Without its database the app cannot work at all, so stop immediately.
                fatalError("Core Data failed to load: \(error)")
            }
        }
    }

    /// Runs a fetch request and returns an empty array if it fails, so a screen
    /// can always show its (empty) list instead of crashing.
    func fetch<T: NSFetchRequestResult>(_ request: NSFetchRequest<T>) -> [T] {
        do {
            return try context.fetch(request)
        } catch {
            let entity = request.entityName ?? "unknown entity"
            logger.error("Fetch failed for \(entity, privacy: .public): \(error.localizedDescription, privacy: .public)")
            return []
        }
    }

    /// Writes pending changes to the database file. Skips the disk write when nothing changed.
    func save() {
        guard context.hasChanges else { return }
        do {
            try context.save()
        } catch {
            logger.error("Save failed: \(error.localizedDescription, privacy: .public)")
        }
    }
}
