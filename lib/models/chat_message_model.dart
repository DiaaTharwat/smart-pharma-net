// lib/models/chat_message_model.dart
enum MessageSender { user, ai }

class ChatMessageModel {
  final String text;
  final MessageSender sender;

  const ChatMessageModel({required this.text, required this.sender});
}
