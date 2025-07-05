// lib/view/Screens/chat_ai_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_pharma_net/models/chat_message_model.dart'; //
import 'package:smart_pharma_net/viewmodels/chat_ai_viewmodel.dart'; //
// Import the new common UI elements file
import 'package:smart_pharma_net/view/Widgets/common_ui_elements.dart'; //


class ChatAiScreen extends StatefulWidget {
  const ChatAiScreen({Key? key}) : super(key: key);

  @override
  State<ChatAiScreen> createState() => _ChatAiScreenState();
}

class _ChatAiScreenState extends State<ChatAiScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final viewModel = Provider.of<ChatAiViewModel>(context, listen: false);
      viewModel.addListener(_scrollToBottom);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    Provider.of<ChatAiViewModel>(context, listen: false)
        .removeListener(_scrollToBottom);
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _sendMessage() {
    if (_controller.text.isNotEmpty) {
      context.read<ChatAiViewModel>().sendMessage(_controller.text);
      _controller.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true, // Extend body behind custom app bar
      appBar: AppBar(
        backgroundColor: Colors.transparent, // Transparent AppBar
        elevation: 0, // No shadow
        leading: IconButton( // Added leading back button
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 28),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Pharmacy Assistant',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            shadows: [Shadow(blurRadius: 10.0, color: Color(0xFF636AE8))], // Glowing effect
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.white, size: 28), // Larger, white icon
            onPressed: () => context.read<ChatAiViewModel>().clearMessages(),
            tooltip: 'Clear Chat',
          ),
        ],
      ),
      body: InteractiveParticleBackground( // Using InteractiveParticleBackground
        child: Column(
          children: [
            Expanded(
              child: Consumer<ChatAiViewModel>(
                builder: (context, viewModel, child) {
                  WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

                  return ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.only(top: 80.0, left: 16.0, right: 16.0, bottom: 16.0), // Changed padding here
                    itemCount: viewModel.messages.length + (viewModel.isLoading ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (viewModel.isLoading && index == viewModel.messages.length) {
                        return const _MessageBubble(
                          message: ChatMessageModel(text: '...', sender: MessageSender.ai),
                          isTyping: true,
                        );
                      }
                      final message = viewModel.messages[index];
                      return _MessageBubble(message: message);
                    },
                  );
                },
              ),
            ),
            _buildMessageInput(),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: const Color(0xFF0F0F1A), // Darker background for input area
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF636AE8).withOpacity(0.2), // Subtle glow
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
        border: Border(top: BorderSide(color: const Color(0xFF636AE8).withOpacity(0.3))), // Top border
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: GlowingTextField( // Using GlowingTextField for input
                controller: _controller,
                hintText: 'Type your message here...',
                icon: Icons.chat_bubble_outline, // Custom icon for GlowingTextField
                keyboardType: TextInputType.text, // Explicitly define keyboard type
                onChanged: (value) { /* No specific action needed here beyond what controller handles */ },
              ),
            ),
            const SizedBox(width: 12), // Increased spacing
            FloatingActionButton(
              onPressed: _sendMessage,
              backgroundColor: const Color(0xFF636AE8), // Consistent color for send button
              elevation: 8, // Elevated for glow
              mini: false, // Standard size
              child: const Icon(Icons.send, color: Colors.white, size: 28), // Larger, white icon
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)), // More rounded
            ),
          ],
        ),
      ),
    );
  }
}


class _MessageBubble extends StatelessWidget {
  final ChatMessageModel message;
  final bool isTyping;

  const _MessageBubble({Key? key, required this.message, this.isTyping = false})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isUser = message.sender == MessageSender.user;
    return Row(
      mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
      children: [
        Container(
          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 18), // Increased padding
          margin: const EdgeInsets.symmetric(vertical: 8), // Increased margin
          decoration: BoxDecoration(
            color: isUser ? const Color(0xFF636AE8).withOpacity(0.8) : const Color(0xFF0F0F1A), // User: glowing blue, AI: dark background
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(20),
              topRight: const Radius.circular(20),
              bottomLeft: isUser ? const Radius.circular(20) : const Radius.circular(5), // More distinction
              bottomRight: isUser ? const Radius.circular(5) : const Radius.circular(20), // More distinction
            ),
            border: isUser ? null : Border.all(color: const Color(0xFF636AE8).withOpacity(0.3)), // Border for AI
            boxShadow: [ // Add subtle glow for user message
              if (isUser) BoxShadow(
                color: const Color(0xFF636AE8).withOpacity(0.3),
                blurRadius: 10,
                spreadRadius: 2,
              ),
            ],
          ),
          child: isTyping
              ? const SizedBox(width: 25, height: 25, child: CircularProgressIndicator(strokeWidth: 3, color: Colors.white54,)) // Larger, white indicator
              : Text(
            message.text,
            style: TextStyle(color: Colors.white, fontSize: 16), // White text, slightly larger
          ),
        ),
      ],
    );
  }
}