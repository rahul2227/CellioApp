//
//  MessageRow.swift
//  CellioApp
//
//  Created by Rahul Sharma on 21/11/24.
//

import SwiftUI


struct MessageRow: View {
    let message: MessageEntity

    var body: some View {
        HStack(alignment: .bottom) {
            if message.isUser {
                Spacer()
                Text(message.text ?? "")
                    .padding(10)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    .frame(maxWidth: 250, alignment: .trailing)
                Image(systemName: "person.crop.circle.fill")
                    .resizable()
                    .frame(width: 30, height: 30)
                    .foregroundColor(.blue)
            } else {
                Image(systemName: "bubble.left.fill")
                    .resizable()
                    .frame(width: 30, height: 30)
                    .foregroundColor(.gray)
                Text(message.text ?? "")
                    .padding(10)
                    .background(Color.white)
                    .foregroundColor(.black)
                    .cornerRadius(10)
                    .frame(maxWidth: 250, alignment: .leading)
                Spacer()
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 5)
    }
}

// MARK: Preview

struct MessageRow_Previews: PreviewProvider {
    static var previews: some View {
        let context = PersistenceController.preview.container.viewContext

        let userMessage = MessageEntity(context: context)
        userMessage.id = UUID()
        userMessage.text = "This is a user message."
        userMessage.isUser = true
        userMessage.timestamp = Date()

        let botMessage = MessageEntity(context: context)
        botMessage.id = UUID()
        botMessage.text = "This is a bot message."
        botMessage.isUser = false
        botMessage.timestamp = Date()

        return Group {
            MessageRow(message: userMessage)
                .previewLayout(.sizeThatFits)
                .environment(\.managedObjectContext, context)

            MessageRow(message: botMessage)
                .previewLayout(.sizeThatFits)
                .environment(\.managedObjectContext, context)
        }
    }
}
