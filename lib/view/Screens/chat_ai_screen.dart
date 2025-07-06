import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_pharma_net/models/chat_message_model.dart';
import 'package:smart_pharma_net/viewmodels/chat_ai_viewmodel.dart';
import 'package:smart_pharma_net/view/Widgets/common_ui_elements.dart';


class ChatAiScreen extends StatefulWidget {
  const ChatAiScreen({Key? key}) : super(key: key);

  @override
  State<ChatAiScreen> createState() => _ChatAiScreenState();
}

class _ChatAiScreenState extends State<ChatAiScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late ChatAiViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    // A safer way to handle listeners with Provider
    _viewModel = Provider.of<ChatAiViewModel>(context, listen: false);
    _viewModel.addListener(_scrollToBottom);
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    // Use the stored _viewModel to remove the listener safely
    _viewModel.removeListener(_scrollToBottom);
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
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 28),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Pharmacy Assistant',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            shadows: [Shadow(blurRadius: 10.0, color: Color(0xFF636AE8))],
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.white, size: 28),
            onPressed: () => context.read<ChatAiViewModel>().clearMessages(),
            tooltip: 'Clear Chat',
          ),
        ],
      ),
      body: InteractiveParticleBackground(
        child: Column(
          children: [
            Expanded(
              child: Consumer<ChatAiViewModel>(
                builder: (context, viewModel, child) {
                  WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

                  return ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.only(top: 100.0, left: 16.0, right: 16.0, bottom: 16.0),
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
        color: const Color(0xFF0F0F1A),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF636AE8).withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
        border: Border(top: BorderSide(color: const Color(0xFF636AE8).withOpacity(0.3))),
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: GlowingTextField(
                controller: _controller,
                hintText: 'Type your message here...',
                prefixIcon: const Icon(Icons.chat_bubble_outline, color: Colors.white70),
                keyboardType: TextInputType.text,
                onChanged: (value) {},
              ),
            ),
            const SizedBox(width: 12),
            FloatingActionButton(
              onPressed: _sendMessage,
              backgroundColor: const Color(0xFF636AE8),
              elevation: 8,
              mini: false,
              child: const Icon(Icons.send, color: Colors.white, size: 28),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
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
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 18),
          margin: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isUser ? const Color(0xFF636AE8).withOpacity(0.8) : const Color(0xFF0F0F1A),
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(20),
              topRight: const Radius.circular(20),
              bottomLeft: isUser ? const Radius.circular(20) : const Radius.circular(5),
              bottomRight: isUser ? const Radius.circular(5) : const Radius.circular(20),
            ),
            border: isUser ? null : Border.all(color: const Color(0xFF636AE8).withOpacity(0.3)),
            boxShadow: [
              if (isUser) BoxShadow(
                color: const Color(0xFF636AE8).withOpacity(0.3),
                blurRadius: 10,
                spreadRadius: 2,
              ),
            ],
          ),
          child: isTyping
              ? const SizedBox(width: 25, height: 25, child: CircularProgressIndicator(strokeWidth: 3, color: Colors.white54,))
              : Text(
            message.text,
            style: const TextStyle(color: Colors.white, fontSize: 16),
          ),
        ),
      ],
    );
  }
}
