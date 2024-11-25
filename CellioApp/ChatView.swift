//
//  ContentView.swift
//  CellioApp
//
//  Created by Rahul Sharma on 19/11/24.
//

import SwiftUI
import CoreData


// MARK: Message Model
struct Message: Identifiable {
    let id = UUID()
    let text: String
    let isUser: Bool
    let timestamp: Date = Date()
}


import UIKit

extension UIApplication {
    func endEditing() {
        self.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}


struct ChatView: View {
    @Binding var chatSession: ChatSession
    @State private var userInput: String = ""
    @State private var isBotTyping: Bool = false
    
    var body: some View {
        VStack {
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(spacing: 10) {
                        ForEach(chatSession.messages) { message in
                            MessageRow(message: message)
                        }
                        if isBotTyping {
                            TypingIndicator()
                        }
                    }
                    .padding()
                }
                .onChange(of: chatSession.messages.count) { _ in
                    if let lastMessage = chatSession.messages.last {
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
        .navigationBarTitle(chatSession.title, displayMode: .inline)
    }
    
    func sendMessage() {
        let userMessage = Message(text: userInput, isUser: true)
        chatSession.messages.append(userMessage)
        userInput = ""
        UIApplication.shared.endEditing()
        
        generateBotResponse(for: userMessage)
    }
    
    func generateBotResponse(for message: Message) {
        isBotTyping = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            let botResponseText = "You said: \(message.text)"
            let botMessage = Message(text: botResponseText, isUser: false)
            chatSession.messages.append(botMessage)
            isBotTyping = false
        }
    }
}


// MARK: Typing Indicator
struct TypingIndicator: View {
    var body: some View {
        HStack {
            Spacer()
            Text("Bot is typing...")
                .italic()
                .foregroundColor(.gray)
                .padding(.trailing, 60)
        }
        .padding(.bottom, 5)
    }
}


//#Preview {
//    ChatView(chatSession: ChatsListView()).environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
//}
