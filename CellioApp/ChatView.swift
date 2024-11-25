//
//  ContentView.swift
//  CellioApp
//
//  Created by Rahul Sharma on 19/11/24.
//

import SwiftUI
import CoreData


// MARK: Extension
extension UIApplication {
    func endEditing() {
        self.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}


import SwiftUI
import CoreData

struct ChatView: View {
    @ObservedObject var chatSession: ChatSessionEntity
    @Environment(\.managedObjectContext) private var viewContext
    @State private var userInput: String = ""
    @State private var isBotTyping: Bool = false

    var body: some View {
        VStack {
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(spacing: 10) {
                        ForEach(chatSession.messagesArray, id: \.id) { message in
                            MessageRow(message: message)
                        }
                        if isBotTyping {
                            TypingIndicator()
                        }
                    }
                    .padding()
                }
                .onChange(of: chatSession.messages?.count) { _ in
                    if let lastMessage = chatSession.messagesArray.last {
                        proxy.scrollTo(lastMessage.id, anchor: .bottom)
                    }
                }
            }
            Divider()
            HStack {
                TextField("Type your message...", text: $userInput)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .frame(minHeight: 30)
                Button(action: sendMessage) {
                    Image(systemName: "paperplane.fill")
                        .rotationEffect(.degrees(45))
                }
                .padding(.leading, 5)
                .disabled(userInput.isEmpty)
            }
            .padding()
        }
        .navigationBarTitle(chatSession.title ?? "Chat", displayMode: .inline)
    }

    func sendMessage() {
        let newMessage = MessageEntity(context: viewContext)
        newMessage.id = UUID()
        newMessage.text = userInput
        newMessage.isUser = true
        newMessage.timestamp = Date()
        newMessage.session = chatSession

        userInput = ""
        UIApplication.shared.endEditing()

        saveContext()
        generateBotResponse(for: newMessage)
    }

    func generateBotResponse(for message: MessageEntity) {
        isBotTyping = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            let botMessage = MessageEntity(context: viewContext)
            botMessage.id = UUID()
            botMessage.text = "You said: \(message.text ?? "")"
            botMessage.isUser = false
            botMessage.timestamp = Date()
            botMessage.session = chatSession

            isBotTyping = false

            saveContext()
        }
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




//#Preview {
//    ChatView(chatSession: ChatsListView()).environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
//}

// MARK:Preview for chat View

struct ChatView_Previews: PreviewProvider {
    static var previews: some View {
        let context = PersistenceController.preview.container.viewContext

        // Sample chat session
        let session = ChatSessionEntity(context: context)
        session.id = UUID()
        session.title = "Preview Chat Session"

        // Sample messages
        let message1 = MessageEntity(context: context)
        message1.id = UUID()
        message1.text = "Hello! How can I assist you today?"
        message1.isUser = false
        message1.timestamp = Date()
        message1.session = session

        let message2 = MessageEntity(context: context)
        message2.id = UUID()
        message2.text = "I need help with my order."
        message2.isUser = true
        message2.timestamp = Date()
        message2.session = session

        return NavigationView {
            ChatView(chatSession: session)
                .environment(\.managedObjectContext, context)
        }
    }
}
