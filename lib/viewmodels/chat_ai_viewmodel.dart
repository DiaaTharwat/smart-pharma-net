// lib/viewmodels/chat_ai_viewmodel.dart
import 'package:flutter/material.dart';
import 'package:smart_pharma_net/models/chat_message_model.dart';
import 'package:smart_pharma_net/repositories/chat_ai_repository.dart';

class ChatAiViewModel extends ChangeNotifier {
  final ChatAiRepository _chatAiRepository;
  List<ChatMessageModel> _messages = [];
  bool _isLoading = false;

  ChatAiViewModel(this._chatAiRepository) {
    // Add initial welcome message
    _messages.add(ChatMessageModel(
        text: "Hello! I'm your pharmacy assistant. How can I help you today?",
        sender: MessageSender.ai));
  }

  List<ChatMessageModel> get messages => _messages;
  bool get isLoading => _isLoading;

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    // Add user message to the list
    _messages.add(ChatMessageModel(text: text, sender: MessageSender.user));
    _isLoading = true;
    notifyListeners();

    try {
      final aiReply = await _chatAiRepository.sendMessageToAI(text);
      _messages.add(ChatMessageModel(text: aiReply, sender: MessageSender.ai));
    } catch (e) {
      _messages.add(ChatMessageModel(
          text: "Sorry, I'm having trouble connecting. Please try again later.",
          sender: MessageSender.ai));
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  void clearMessages() {
    _messages = [ChatMessageModel(
        text: "Hello! I'm your pharmacy assistant. How can I help you today?",
        sender: MessageSender.ai)];
    notifyListeners();
  }
}