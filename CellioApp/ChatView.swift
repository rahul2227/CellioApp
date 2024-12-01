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

// MARK: Chat View
struct ChatView: View {
    @ObservedObject var chatSession: ChatSessionEntity
    @Environment(\.managedObjectContext) private var viewContext
    @State private var userInput: String = ""
    @State private var isBotTyping: Bool = false
    @State private var model: Galactica_1_3B_pruned_fp16?
    @State private var tokenizer: Tokenizer?
    
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
            initializeModelAndTokenizer()
        }
    }
    // MARK: Tokenizer init
    /// Initializes the Core ML model and the Tokenizer using the readConfig function.
    func initializeModelAndTokenizer() {
        do {
            // Initialize the Core ML model
            let configuration = MLModelConfiguration()
            self.model = try Galactica_1_3B_pruned_fp16(configuration: configuration)
            
            // Load the tokenizer using readConfig
            guard let tokenizerConfig = try readConfig(name: "tokenizer_config") else {
                print("Tokenizer config not found.")
                return
            }
            guard let tokenizerData = try readConfig(name: "tokenizer") else {
                print("Tokenizer data not found.")
                return
            }
            
            // Initialize the tokenizer
            self.tokenizer = try! AutoTokenizer.from(tokenizerConfig: tokenizerConfig, tokenizerData: tokenizerData)
            
            print("Tokenizer initialized successfully.")
        } catch {
            print("Failed to load the model or tokenizer: \(error)")
        }
    }
    
    /// Reads a config from Files/ directory similar to the reference implementation.
    /// - Parameter name: The name of the config file (without extension).
    /// - Returns: A `Config` object if successful, otherwise `nil`.
    func readConfig(name: String) throws -> Config? {
        guard let url = Bundle.main.url(forResource: "\(name)", withExtension: "json") else {
            print("file \(name).json not found in Files directory.")
            return nil
        }
        
        do {
            let data = try Data(contentsOf: url, options: .mappedIfSafe)
            let jsonResult = try JSONSerialization.jsonObject(with: data, options: .mutableLeaves)
            if let jsonDict = jsonResult as? [String: Any] {
                // Convert keys to NSString
                let nsDict = jsonDict.reduce(into: [NSString: Any]()) { result, pair in
                    result[pair.key as NSString] = pair.value
                }
                return Config(nsDict)
            } else {
                print("Invalid JSON structure in \(name).json.")
                return nil
            }
        } catch {
            print("Error retrieving json config \(name).json: \(error)")
            throw error
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
    
    //MARK: Bot Response Handler
    func generateBotResponse(for message: MessageEntity) {
        isBotTyping = true
        let workItem = DispatchWorkItem {
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
                var inputIds = try tokenizer.encode(text: userMessage)
                
                // Adjust inputIds to length 512
                let maxSequenceLength = 512
                let paddingTokenId = 0 // Adjust if your tokenizer uses a different padding token ID
                
                if inputIds.count < maxSequenceLength {
                    // Pad with padding token ID
                    let paddingCount = maxSequenceLength - inputIds.count
                    let paddingTokens = [Int](repeating: paddingTokenId, count: paddingCount)
                    inputIds += paddingTokens
                } else if inputIds.count > maxSequenceLength {
                    // Truncate to maxSequenceLength
                    inputIds = Array(inputIds.prefix(maxSequenceLength))
                }
                
                // Prepare MLMultiArray input
                let inputArray = try MLMultiArray(shape: [1, NSNumber(value: maxSequenceLength)], dataType: .int32)
                
                // Fill the MLMultiArray with inputIds
                for (index, token) in inputIds.enumerated() {
                    // Set the value at position [0, index]
                    inputArray[[0, NSNumber(value: index)]] = NSNumber(value: token)
                }
                
                // Create model input
                let modelInput = Galactica_1_3B_pruned_fp16Input(input_ids: inputArray)
                
                // Run the model
                let prediction = try model.prediction(input: modelInput)
                
                // Get logits from the model output
                let logits = prediction.linear_144
                
                // Convert logits to token IDs by performing argmax
                let outputIds = try self.extractTokenIds(from: logits)
                
                // Detokenize the output
                let generatedText = try tokenizer.decode(tokens: outputIds)
                
                DispatchQueue.main.async {
                    // Create bot message
                    let botMessage = MessageEntity(context: self.viewContext)
                    botMessage.id = UUID()
                    botMessage.text = generatedText
                    botMessage.isUser = false
                    botMessage.timestamp = Date()
                    botMessage.session = self.chatSession
                    
                    self.isBotTyping = false
                    self.saveContext()
                }
            } catch {
                print("Error during tokenization or prediction: \(error)")
                DispatchQueue.main.async {
                    self.isBotTyping = false
                }
            }
        }
        DispatchQueue.global(qos: .userInitiated).async(execute: workItem)
    }
    
    func extractTokenIds(from logits: MLMultiArray) throws -> [Int] {
        // Get the shape of the logits array
        let shape = logits.shape.map { Int(truncating: $0) } // [1, sequence_length, vocab_size]
        guard shape.count == 3 else {
            throw NSError(domain: "LogitsShapeError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Unexpected logits shape"])
        }
        
        let sequenceLength = shape[1]
        let vocabSize = shape[2]
        
        // Initialize a pointer to the logits data
        let ptr = UnsafeMutablePointer<Float>(OpaquePointer(logits.dataPointer))
        
        var outputIds: [Int] = []
        
        for position in 0..<sequenceLength {
            // Calculate the offset for the current position
            let offset = position * vocabSize
            
            // Find the index of the maximum logit value for this position
            var maxLogit: Float = -Float.infinity
            var maxIndex: Int = 0
            for vocabIndex in 0..<vocabSize {
                let value = ptr[offset + vocabIndex]
                if value > maxLogit {
                    maxLogit = value
                    maxIndex = vocabIndex
                }
            }
            outputIds.append(maxIndex)
        }
        
        return outputIds
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
