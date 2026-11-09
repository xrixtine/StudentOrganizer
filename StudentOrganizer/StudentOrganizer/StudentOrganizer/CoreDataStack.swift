import CoreData


final class CoreDataStack {

    static let shared = CoreDataStack()

    let container: NSPersistentContainer

    var context: NSManagedObjectContext { container.viewContext }

    private init() {
        container = NSPersistentContainer(name: "StudentOrganizer")
        container.loadPersistentStores { storeDescription, error in
            if let error = error {
                fatalError("Core Data failed to load: \(error)")
            }
            print("Database file: \(storeDescription.url?.path ?? "unknown")")
        }
    }

    func save() {
        guard context.hasChanges else { return }
        do {
            try context.save()
        } catch {
            print("Core Data save failed: \(error)")
        }
    }
}
