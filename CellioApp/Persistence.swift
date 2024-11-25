//
//  Persistence.swift
//  CellioApp
//
//  Created by Rahul Sharma on 19/11/24.
//

import CoreData

struct PersistenceController {
    static let shared = PersistenceController()
    
    let container: NSPersistentContainer

    // Preview instance for SwiftUI previews
    static var preview: PersistenceController = {
        let controller = PersistenceController(inMemory: true)
        
        // Create sample data
        let viewContext = controller.container.viewContext
        for index in 0..<3 {
            let session = ChatSessionEntity(context: viewContext)
            session.id = UUID()
            session.title = "Chat Session \(index + 1)"
            
            // Add sample messages
            for i in 0..<5 {
                let message = MessageEntity(context: viewContext)
                message.id = UUID()
                message.text = "Message \(i + 1) in Session \(index + 1)"
                message.isUser = i % 2 == 0
                message.timestamp = Date()
                message.session = session
            }
        }
        
        do {
            try viewContext.save()
        } catch {
            // Handle the error appropriately
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
        
        return controller
    }()
    
    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "ChatAppModel") // Match your .xcdatamodeld filename
        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        }
        container.loadPersistentStores { _, error in
            if let error = error as NSError? {
                // Handle the error appropriately
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        }
    }
}
