//
//  ChatSession.swift
//  CellioApp
//
//  Created by Rahul Sharma on 24/11/24.
//


import SwiftUI
import CoreData


// MARK: Extension
// Extension to get messages as an array
extension ChatSessionEntity {
    var messagesArray: [MessageEntity] {
        let set = messages as? Set<MessageEntity> ?? []
        return set.sorted {
            ($0.timestamp ?? Date()) < ($1.timestamp ?? Date())
        }
    }
}


struct ChatsListView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        sortDescriptors: [],
        animation: .default)
    private var chatSessions: FetchedResults<ChatSessionEntity>

    @State private var editMode: EditMode = .inactive

    var body: some View {
        NavigationView {
            List {
                ForEach(chatSessions) { session in
                    NavigationLink(destination: ChatView(chatSession: session)) {
                        HStack {
                            Image(systemName: "message.fill")
                                .foregroundColor(.blue)
                            if editMode == .active {
                                TextField("Session Title", text: Binding(
                                    get: { session.title ?? "" },
                                    set: { session.title = $0; saveContext() }
                                ))
                            } else {
                                VStack(alignment: .leading) {
                                    Text(session.title ?? "Chat")
                                        .font(.headline)
                                    Text(session.messagesArray.last?.text ?? "")
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                        .lineLimit(1)
                                }
                            }
                        }
                        .padding(.vertical, 5)
                    }
                }
                .onDelete(perform: deleteSession)
            }
            .navigationTitle("Chats")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    EditButton()
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: newChatSession) {
                        Image(systemName: "plus")
                    }
                }
            }
            .environment(\.editMode, $editMode)
        }
    }

    func newChatSession() {
        let newSession = ChatSessionEntity(context: viewContext)
        newSession.id = UUID()
        newSession.title = "New Chat"

        saveContext()
    }

    func deleteSession(at offsets: IndexSet) {
        for index in offsets {
            let session = chatSessions[index]
            viewContext.delete(session)
        }
        saveContext()
    }

    private func saveContext() {
        do {
            try viewContext.save()
        } catch {
            // Handle the error appropriately
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
    }
}


// MARK: Preview
struct ChatsListView_Previews: PreviewProvider {
    static var previews: some View {
        let context = PersistenceController.preview.container.viewContext

        return ChatsListView()
            .environment(\.managedObjectContext, context)
    }
}
