//
//  ChatSession.swift
//  CellioApp
//
//  Created by Rahul Sharma on 24/11/24.
//


import SwiftUI

// MARK: Chat Session Model

struct ChatSession: Identifiable {
    let id = UUID()
    var title: String
    var messages: [Message]
    
    var lastMessageTime: String {
        guard let lastMessage = messages.last else { return "" }
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: lastMessage.timestamp)
    }
}

struct ChatsListView: View {
    @State private var chatSessions: [ChatSession] = [
        // Sample chat sessions
        ChatSession(title: "Chat with Bot", messages: [
            Message(text: "Hello! How can I assist you today?", isUser: false)
        ])
    ]
    @State private var editMode: EditMode = .inactive
    
    var body: some View {
            NavigationView {
                List {
                    ForEach($chatSessions) { $session in
                        NavigationLink(destination: ChatView(chatSession: $session)) {
                            HStack {
                                Image(systemName: "message.fill")
                                    .foregroundColor(.blue)
                                if editMode == .active {
                                    TextField("Session Title", text: $session.title)
                                } else {
                                    VStack(alignment: .leading) {
                                        HStack {
                                            Text(session.title)
                                                .font(.headline)
                                            Spacer()
                                            Text(session.lastMessageTime)
                                                .font(.subheadline)
                                                .foregroundColor(.gray)
                                        }
                                        Text(session.messages.last?.text ?? "")
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
    
    // Helper function to get binding for a chat session
    func binding(for session: ChatSession) -> Binding<ChatSession> {
        guard let index = chatSessions.firstIndex(where: { $0.id == session.id }) else {
            fatalError("Chat session not found")
        }
        return $chatSessions[index]
    }
    
    func newChatSession() {
        let newSession = ChatSession(title: "New Chat", messages: [])
        chatSessions.append(newSession)
    }
    
    func deleteSession(at offsets: IndexSet) {
        chatSessions.remove(atOffsets: offsets)
    }
}

//#Preview {
//    ChatsListView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
//}

