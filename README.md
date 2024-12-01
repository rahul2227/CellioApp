# Cellio Application

Cellio is a SwiftUI application that serves as the front-end interface for a medical chatbot. It builds upon an existing [NLP Project]([url](https://github.com/rahul2227/chatbot_ic_NLP)) to provide users with an interactive platform for accessing medical information and assistance.


### Features
These are the feature list of the application, some are implemented while others serve as a roadmap for future work
- Interactive Chat Interface: Engage in real-time conversations with a medical chatbot.
- Core ML Integration: Utilizes Core ML models for natural language processing.
- Persistence: Stores chat sessions and messages using Core Data.
- [ ] Medical Data Integration: Access accurate and up-to-date medical information.
- [ ] User-Friendly Design: Intuitive UI built with SwiftUI for a seamless user experience.
- [ ] Custom Tokenization: Implements advanced tokenizers to handle medical terminology effectively.    


### Dependencies

The project uses the following Swift packages:
    •    Jinja: A Swift templating engine inspired by Jinja2.
    •    swift-argument-parser: A library for building command-line tools.
    •    swift-transformers: Implementation of Transformer models in Swift.
    •    SwiftTokenizer: A tokenizer library for handling medical terminology.

### Installation

1. Clone the Repository
2. git clone https://github.com/yourusername/Cellio.git
3. cd Cellio
4. Open the Project
5. Open Cellio.xcodeproj in Xcode:
6. open Cellio.xcodeproj
7. Add Dependencies


### Build and Run

- Select the target device or simulator.
- Click the Run button in Xcode or press Cmd + R.

### Usage

1. Launch the App
  - Upon launching, you’ll be greeted with a chat interface.
2. Start a Conversation
  - Type your medical query or message into the text field at the bottom.
3. Receive Assistance
  - The chatbot will process your input and provide relevant medical information or guidance.
4. View Previous Conversations
- Access past chat sessions to review previous interactions.

Project Structure

- Views
- ChatView.swift: Main chat interface.
- MessageRow.swift: UI component for individual messages.
- TypingIndicator.swift: Shows when the bot is generating a response.
- Models
- MessageEntity: Core Data model for chat messages.
- ChatSessionEntity: Core Data model for chat sessions.
- Controllers
- PersistenceController.swift: Manages Core Data stack.
- Utilities
- Extensions.swift: Contains utility extensions, such as dismissing the keyboard.
- Core ML Model
- Galactica_1_3B_pruned_fp16.mlmodel: Machine learning model for NLP tasks.
- Tokenizers
- tokenizer.json: Tokenizer data file.
- tokenizer_config.json: Configuration for the tokenizer.


Acknowledgments

- NLP Backend: Thanks to the original NLP project that powers the chatbot’s intelligence.
- Apple Developer Community: For resources and tutorials on SwiftUI and Core ML.



Thank you for using Cellio! I hope this application assists you in accessing valuable medical information with ease.

Note: If any of the dependency URLs or package names differ, please let me know by raising an issue
