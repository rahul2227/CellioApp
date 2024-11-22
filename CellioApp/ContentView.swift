//
//  ContentView.swift
//  CellioApp
//
//  Created by Rahul Sharma on 19/11/24.
//

import SwiftUI
import CoreData

struct Message: Identifiable {
    let id: UUID = UUID()
    let text: String
    let isUser: Bool // this will be true if the message is from the user
}

struct ContentView: View {
    @State private var messages: [Message] = [
        // Sample messages
        Message(text: "Hello! How can I assist you today?", isUser: false)
    ]
    @State private var userInput: String = ""
    
    var body: some View {
        VStack {
            ScrollViewReader { proxy in
                ScrollView{
                    VStack(spacing: 10) {
                        ForEach(messages) { message in
                            MessageRow(message: message)
                        }
                    }
                    .padding()
                }.onChange(of: messages.count) { _ in
                    // Scroll to the bottom when new message is added
                    if let lastMessage = messages.last {
                        proxy.scrollTo(lastMessage.id, anchor: .bottom)
                    }
                }
            }
            Divider()
            HStack {
                TextField("Enter your message", text: $userInput)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .frame(minHeight: 30 )
                Button(action: sendMessage) {
                    Image(systemName: "paperplane.fill")
                        .rotationEffect(.degrees(45))
                }
                .padding(.leading, 5)
                .disabled(userInput.isEmpty)
            }
            .padding()
        }
        .background(Color(UIColor.systemGroupedBackground))
    }
    func sendMessage() {
        let newMessage = Message(text: userInput, isUser: true)
        messages.append(newMessage)
        userInput = ""
        
        // Simulate bot response
        generateBotResponse(for: newMessage)
    }
    
    func generateBotResponse(for message: Message) {
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1)) {
            let botResponseText = "You said: \(message.text)"
            let botMessage = Message(text: botResponseText, isUser: false)
            messages.append(botMessage)
        }
    }
}



#Preview {
    ContentView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
