//
//  ContentView.swift
//  CellioApp
//
//  Created by Rahul Sharma on 19/11/24.
//

import SwiftUI
import CoreData
import CoreML
import Tokenizers
import Hub

// MARK: Extension
extension UIApplication {
    func endEditing() {
        self.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}


struct ChatView: View {
    @ObservedObject var chatSession: ChatSessionEntity
    @Environment(\.managedObjectContext) private var viewContext
    @State private var userInput: String = ""
    @State private var isBotTyping: Bool = false
    @State private var model: Galactica_1_3B_pruned_fp16?
    @State private var tokenizer: AutoTokenizer?
    
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
                .onAppear {
                    do {
                        let configuration = MLModelConfiguration()
                        self.model = try Galactica_1_3B_pruned_fp16(configuration: configuration)
                        
                        // Load the tokenizer
                        if let tokenizerConfigPath = Bundle.main.path(forResource: "tokenizer_config", ofType: "json"),
                           let tokenizerDataPath = Bundle.main.path(forResource: "tokenizer", ofType: "json") {
                            
                            // Load tokenizer config
                            let tokenizerConfigURL = URL(fileURLWithPath: tokenizerConfigPath)
                            let tokenizerConfigData = try Data(contentsOf: tokenizerConfigURL)
                            let tokenizerConfig = try JSONDecoder().decode(Config.self, from: tokenizerConfigData)
                            
                            // Load tokenizer data
                            let tokenizerDataURL = URL(fileURLWithPath: tokenizerDataPath)
                            let tokenizerData = try Data(contentsOf: tokenizerDataURL)
                            
                            // Initialize the tokenizer
                            self.tokenizer = try AutoTokenizer.from(tokenizerConfig: tokenizerConfig, tokenizerData: tokenizerData)
                        } else {
                            print("Tokenizer files not found.")
                        }
                    } catch {
                        print("Failed to load the model or tokenizer: \(error)")
                    }
                }
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
    
    // Reads a config from Files/ directory
    func readConfig(name: String) throws -> Config? {
        if let url = Bundle.main.url(forResource: "Files/\(name)", withExtension: "json") {
            do {
                let data = try Data(contentsOf: url, options: .mappedIfSafe)
                let jsonResult = try JSONSerialization.jsonObject(with: data, options: .mutableLeaves)
                if let jsonDict = jsonResult as? [NSString: Any] {
                    return Config(jsonDict)
                }
            } catch {
                 print("Error retrieving json config: \(error)")
            }
        }
        return nil
    }

    
    func generateBotResponse(for message: MessageEntity) {
            isBotTyping = true
            DispatchQueue.global(qos: .userInitiated).async {
                guard let model = self.model, let tokenizer = self.tokenizer else {
                    print("Model or tokenizer is not loaded.")
                    DispatchQueue.main.async {
                        self.isBotTyping = false
                    }
                    return
                }
                
                let userMessage = message.text ?? ""
                do {
                    // Tokenize the user input
                    let inputIds = try tokenizer.encode(text: userMessage)
//                    let inputIds = try tokenizer.tokenize(text: userMessage)
                    
                    // Prepare MLMultiArray input
                    let inputSize = NSNumber(value: inputIds.count)
                    let inputArray = try MLMultiArray(shape: [inputSize], dataType: .int32)
                    for (index, token) in inputIds.enumerated() {
                        inputArray[index] = NSNumber(value: token)
                    }
                    
                    // Create model input
                    let modelInput = Galactica_1_3B_pruned_fp16Input(input_ids: inputArray)
                    
                    // Run the model
                    let prediction = try model.prediction(input: modelInput)
                    
                    // Get output tokens
                    guard let outputArray = prediction.output_ids else {
                        throw NSError(domain: "ModelOutputError", code: -1, userInfo: [NSLocalizedDescriptionKey: "No output from model"])
                    }
                    let outputIds = outputArray.map { $0.intValue }
                    
                    // Detokenize the output
                    let generatedText = try tokenizer.decode(tokens: outputIds)
                    
                    DispatchQueue.main.async {
                        // Create bot message
                        let botMessage = MessageEntity(context: viewContext)
                        botMessage.id = UUID()
                        botMessage.text = generatedText
                        botMessage.isUser = false
                        botMessage.timestamp = Date()
                        botMessage.session = chatSession
                        
                        self.isBotTyping = false
                        saveContext()
                    }
                } catch {
                    print("Error during tokenization or prediction: \(error)")
                    DispatchQueue.main.async {
                        self.isBotTyping = false
                    }
                }
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

// MARK: Preview for ChatView

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
