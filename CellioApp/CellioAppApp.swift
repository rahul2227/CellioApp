//
//  CellioAppApp.swift
//  CellioApp
//
//  Created by Rahul Sharma on 19/11/24.
//

import SwiftUI

@main
struct CellioAppApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ChatsListView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
