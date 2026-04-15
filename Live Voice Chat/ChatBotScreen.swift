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
        Message(text: "Hello! How can I help you today?", isUser: false)
    ]
    @FocusState private var inputFocused: Bool

    var body: some View {
        ZStack {
            AppTheme.appBackground
                .ignoresSafeArea()

            VStack(spacing: 0) {
                header

                chatArea

                inputBar
            }
            
        }
    }

    // MARK: - Header
    private var header: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(AppTheme.aiBubbleLight)
                    .frame(width: 48, height: 48)
                
                Image(systemName: "sparkles")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(AppTheme.aiBubbleDark)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("Chat Assistant")
                    .font(AppTheme.font(.bold, size: 24))
                    .foregroundStyle(AppTheme.textPrimary)

                HStack(spacing: 6) {
                    Circle()
                        .fill(AppTheme.userBubble)
                        .frame(width: 8, height: 8)
                    Text("Online")
                        .font(AppTheme.font(.medium, size: 15))
                        .foregroundStyle(AppTheme.textSecondary)
                }
            }

            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(AppTheme.cardBackground)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(Color.black.opacity(0.05))
                .frame(height: 1)
        }
    }

    // MARK: - Chat Area
    private var chatArea: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(spacing: 16) {
                    ForEach(messages) { message in
                        MessageRow(message: message)
                            .id(message.id)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 20)
            }
            .onChange(of: messages.count) { _ in
                if let lastID = messages.last?.id {
                    withAnimation(.easeOut(duration: 0.25)) {
                        proxy.scrollTo(lastID, anchor: .bottom)
                    }
                }
            }
        }
    }

    // MARK: - Input Bar
    private var inputBar: some View {
        HStack(spacing: 12) {
            HStack(spacing: 10) {
                TextField("", text: $userText, prompt:
                    Text("Type a message…")
                        .font(AppTheme.font(.regular, size: 18))
                        .foregroundColor(AppTheme.textPlaceholder)
                )
                .font(AppTheme.font(.regular, size: 18))
                .foregroundStyle(AppTheme.textPrimary)
                .focused($inputFocused)
                .submitLabel(.send)
                .onSubmit { sendMessage() }

                if !userText.isEmpty {
                    Button {
                        userText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 20))
                            .foregroundStyle(AppTheme.textPlaceholder)
                    }
                }
            }
            .padding(.horizontal, 18)
            .frame(minHeight: 54)
            .background(AppTheme.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 27, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 27, style: .continuous)
                    .stroke(
                        inputFocused ? AppTheme.userBubble.opacity(0.6)
                                     : Color.black.opacity(0.08),
                        lineWidth: inputFocused ? 1.5 : 1
                    )
            )

            Button {
                sendMessage()
            } label: {
                ZStack {
                    Circle()
                        .fill(
                            userText.trimmingCharacters(in: .whitespaces).isEmpty
                            ? AppTheme.buttonPrimary.opacity(0.45)
                            : AppTheme.buttonPrimary
                        )
                        .frame(width: 54, height: 54)
                        .shadow(color: AppTheme.buttonPrimary.opacity(0.35),
                                radius: 8, x: 0, y: 4)

                    Image(systemName: "paperplane.fill")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(.white)
                        .offset(x: -1, y: 1)
                }
            }
            .disabled(userText.trimmingCharacters(in: .whitespaces).isEmpty)
            .animation(.easeInOut(duration: 0.15), value: userText)
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
        .padding(.bottom, 14)
        .background(
            AppTheme.cardBackground
                .overlay(alignment: .top) {
                    Rectangle()
                        .fill(Color.black.opacity(0.05))
                        .frame(height: 1)
                }
        )
    }

    // MARK: - Actions
    private func sendMessage() {
        let trimmed = userText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        messages.append(Message(text: trimmed, isUser: true))
        userText = ""

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

// MARK: - Message Row
private struct MessageRow: View {
    let message: Message

    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            if message.isUser {
                Spacer(minLength: 40)
                MessageBubble(text: message.text, isUser: true)
                Avatar(isUser: true)
            } else {
                Avatar(isUser: false)
                MessageBubble(text: message.text, isUser: false)
                Spacer(minLength: 40)
            }
        }
    }
}

// MARK: - Avatar
private struct Avatar: View {
    let isUser: Bool

    var body: some View {
        ZStack {
            Circle()
                .fill(isUser ? AppTheme.userBubbleLight : AppTheme.aiBubbleLight)
                .frame(width: 36, height: 36)
            
            Image(systemName: isUser ? "person.fill" : "sparkles")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(isUser ? AppTheme.userBubbleDark : AppTheme.aiBubbleDark)
        }
    }
}

// MARK: - Message Bubble
private struct MessageBubble: View {
    var text: String
    var isUser: Bool

    var body: some View {
        Text(text)
            .font(AppTheme.font(.medium, size: 18))
            .lineSpacing(4)
            .foregroundStyle(AppTheme.textPrimary)
            .padding(.vertical, 14)
            .padding(.horizontal, 18)
            .background(isUser ? AppTheme.userBubbleLight : AppTheme.aiBubbleLight)
            .overlay(
                bubbleShape
                    .stroke(
                        isUser ? AppTheme.userBubble.opacity(0.35)
                               : AppTheme.aiBubbleDark.opacity(0.25),
                        lineWidth: 1
                    )
            )
            .clipShape(bubbleShape)
            .shadow(color: Color.black.opacity(0.04), radius: 4, x: 0, y: 2)
            .frame(maxWidth: 280, alignment: isUser ? .trailing : .leading)
    }

    private var bubbleShape: some Shape {
        UnevenRoundedRectangle(
            topLeadingRadius: 20,
            bottomLeadingRadius: isUser ? 20 : 6,
            bottomTrailingRadius: isUser ? 6 : 20,
            topTrailingRadius: 20,
            style: .continuous
        )
    }
}


#Preview {
    ChatBotScreen()
}
