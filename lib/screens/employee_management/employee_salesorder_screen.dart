import 'dart:async';
import 'package:assetarchiverflutter/models/employee_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

// A simple model for a chat message
class _ChatMessage {
  final String text;
  final bool isUser;
  _ChatMessage({required this.text, required this.isUser});
}

class SalesOrderScreen extends StatefulWidget {
  final Employee employee;
  const SalesOrderScreen({super.key, required this.employee});

  @override
  State<SalesOrderScreen> createState() => _SalesOrderScreenState();
}

class _SalesOrderScreenState extends State<SalesOrderScreen> {
  final TextEditingController _textController = TextEditingController();
  final List<_ChatMessage> _messages = [];
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Start with a greeting from the bot
    _addBotMessage(
        "Hello ${widget.employee.firstName}! I'm here to help you create a sales order. What product would you like to order?");
  }

  void _addBotMessage(String text) {
    setState(() {
      _messages.insert(0, _ChatMessage(text: text, isUser: false));
    });
    _scrollToBottom();
  }

  void _handleSubmitted(String text) {
    if (text.trim().isEmpty) return;
    _textController.clear();

    setState(() {
      _messages.insert(0, _ChatMessage(text: text, isUser: true));
    });
    _scrollToBottom();

    // Simulate bot thinking
    Timer(const Duration(milliseconds: 800), () => _getBotResponse(text));
  }

  void _getBotResponse(String userMessage) {
    String response;
    if (userMessage.toLowerCase().contains('cement')) {
      response = "Great choice! How many tons of cement would you like to order?";
    } else if (userMessage.toLowerCase().contains('tons') || _isNumeric(userMessage)) {
      response = "Excellent. I've created a draft sales order for ${userMessage.toLowerCase()}. Is there anything else?";
    } else {
      response = "I'm sorry, I can only process cement orders right now. Please specify the product.";
    }
    _addBotMessage(response);
  }

  bool _isNumeric(String s) => double.tryParse(s) != null;

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0.0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0D47A1), Color.fromARGB(255, 2, 10, 103)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  reverse: true,
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  itemCount: _messages.length,
                  itemBuilder: (_, int index) => _ChatMessageBubble(message: _messages[index]),
                ),
              ),
              _buildTextComposer(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextComposer() {
    return Container(
      color: Colors.transparent,
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.2),
          borderRadius: BorderRadius.circular(30.0),
        ),
        child: Row(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(left: 20.0),
                // FIXED: Using a more specific InputDecoration to remove the "weird outline".
                child: TextField(
                  controller: _textController,
                  onSubmitted: _handleSubmitted,
                  decoration: const InputDecoration(
                    hintText: 'Type your order...',
                    hintStyle: TextStyle(color: Colors.white70),
                    border: InputBorder.none, // This removes all borders/outlines
                  ),
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ),
            IconButton(
              icon: Icon(Icons.send, color: Theme.of(context).colorScheme.primary),
              onPressed: () => _handleSubmitted(_textController.text),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}

// --- Helper Widget for Animated Chat Bubbles ---
class _ChatMessageBubble extends StatelessWidget {
  final _ChatMessage message;
  const _ChatMessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // FIXED: The chat bubble is now wrapped in a Row with an Avatar for the bot.
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5.0),
      child: Row(
        mainAxisAlignment: message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // ADDED: Show an avatar for the bot's messages.
          if (!message.isUser)
            const CircleAvatar(
              child: Icon(Icons.support_agent),
            ),
          const SizedBox(width: 8),

          // FIXED: ConstrainedBox limits the max width of the bubble for better readability.
          Flexible(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
                decoration: BoxDecoration(
                  color: message.isUser
                      ? theme.colorScheme.primary
                      : Colors.white.withOpacity(0.15),
                  borderRadius: message.isUser
                      ? const BorderRadius.only(
                          topLeft: Radius.circular(20.0),
                          bottomLeft: Radius.circular(20.0),
                          topRight: Radius.circular(20.0),
                        )
                      : const BorderRadius.only(
                          topRight: Radius.circular(20.0),
                          bottomRight: Radius.circular(20.0),
                          topLeft: Radius.circular(20.0),
                        ),
                ),
                child: Text(
                  message.text,
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.5, end: 0);
  }
}

