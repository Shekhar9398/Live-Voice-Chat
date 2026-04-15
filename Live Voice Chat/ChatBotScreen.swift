//
//  ContentView.swift
//  Live Voice Chat
//
//  Created by Mac on 15/04/26.
//

import SwiftUI

struct ChatBotScreen: View {
    
    @State private var userText: String = ""
    @State private var messages: [Message] = [
        Message(text: "Hello! How can I help you?", isUser: false)
    ]
    
    var body: some View {
        ZStack {
            Color.indigo.opacity(0.2)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                
                // Header
                Text("Chat Bot")
                    .bold()
                    .font(.title)
                    .padding()
                
                // Chat Area
                ScrollViewReader { proxy in
                    ScrollView {
                        VStack(spacing: 12) {
                            ForEach(messages) { message in
                                HStack {
                                    if message.isUser {
                                        Spacer()
                                        MessageBubble(text: message.text, isUser: true)
                                    } else {
                                        MessageBubble(text: message.text, isUser: false)
                                        Spacer()
                                    }
                                }
                                .id(message.id)
                            }
                        }
                        .padding()
                    }
                    .onChange(of: messages.count) { _ in
                        if let lastID = messages.last?.id {
                            withAnimation {
                                proxy.scrollTo(lastID, anchor: .bottom)
                            }
                        }
                    }
                }
                
                // Input Field
                HStack{
                    TextField("Enter the text", text: $userText)
                        .padding()
                        .frame(maxWidth: .infinity, minHeight: 50)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                        .overlay {
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Color.gray, lineWidth: 1)
                        }
                        .onSubmit {
                            sendMessage() //on enter btn hit
                        }
                    
                    //send Button
                    Button {
                        sendMessage()
                    } label: {
                        Image(systemName: "paperplane.circle.fill")
                            .resizable()
                            .frame(width: 40, height: 40)
                            .foregroundStyle(Color.indigo)
                    }
                    
                    
                }
                .padding(.horizontal)
            }
            .padding()
        }
    }
    
    // MARK: - Actions
    private func sendMessage() {
        let trimmed = userText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        
        // Add user message
        messages.append(Message(text: trimmed, isUser: true))
        userText = ""
        
        // Simulate bot response
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            let reply = generateBotReply(for: trimmed)
            messages.append(Message(text: reply, isUser: false))
        }
    }
    
    private func generateBotReply(for text: String) -> String {
        return "You said: \(text)"
    }
}

// MARK: - Models
struct Message: Identifiable {
    let id = UUID()
    let text: String
    let isUser: Bool
}

// MARK: - UI
private struct MessageBubble: View {
    var text: String
    var isUser: Bool
    
    var body: some View {
        Text(text)
            .font(.body)
            .padding(12)
            .background(isUser ? Color.indigo : Color.white)
            .foregroundStyle(isUser ? .white : .black)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .frame(maxWidth: 260, alignment: isUser ? .trailing : .leading)
    }
}

#Preview {
    ChatBotScreen()
}
