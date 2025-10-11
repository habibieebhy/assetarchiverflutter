// lib/screens/employee_management/employee_salesorder_screen.dart
import 'package:assetarchiverflutter/models/employee_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';

part 'employee_salesorder_screen.g.dart';

// --- CRITICAL FIX: The Hive model class is now PUBLIC (no underscore) ---
@HiveType(typeId: 0)
class ChatMessage extends HiveObject {
  @HiveField(0)
  final String text;

  @HiveField(1)
  final String role;

  ChatMessage({required this.text, required this.role});
}

class SalesOrderScreen extends StatefulWidget {
  final Employee employee;
  const SalesOrderScreen({super.key, required this.employee});

  @override
  State<SalesOrderScreen> createState() => _SalesOrderScreenState();
}

class _SalesOrderScreenState extends State<SalesOrderScreen> {
  // --- UPDATED: All references now use the public ChatMessage class ---
  final TextEditingController _textController = TextEditingController();
  final List<ChatMessage> _messages = [];
  final ScrollController _scrollController = ScrollController();
  
  late IO.Socket _socket;
  bool _isConnected = false;
  bool _isLoading = false;

  late Box<ChatMessage> _chatBox;

  @override
  void initState() {
    super.initState();
    _initializeChat();
  }

  Future<void> _initializeChat() async {
    // --- CRITICAL FIX: Register the now PUBLIC ChatMessageAdapter ---
    if (!Hive.isAdapterRegistered(0)) {
       Hive.registerAdapter(ChatMessageAdapter());
    }
    
    _chatBox = await Hive.openBox<ChatMessage>('sales_order_chat');
    
    if (mounted) {
      setState(() {
        _messages.addAll(_chatBox.values.toList().reversed);
      });
    }

    _connectToSocket();
  }

  void _connectToSocket() {
    const socketUrl = 'https://python-ai-agent.onrender.com';
    _socket = IO.io(socketUrl, <String, dynamic>{
      'path': '/socket.io',
      'transports': ['websocket', 'polling'], 
      'autoConnect': false,
    });

    _socket.connect();

    _socket.onConnect((_) {
      debugPrint('Socket connected');
      if(mounted) setState(() => _isConnected = true);
    });

    _socket.onDisconnect((_) {
      debugPrint('Socket disconnected');
      if(mounted) setState(() => _isConnected = false);
    });

    _socket.on('connect_error', (data) => debugPrint('Connect Error: $data'));
    _socket.on('error', (data) => debugPrint('Socket Error: $data'));
    
    _socket.on('ready', (_) {
       if (_messages.isEmpty) {
         _addMessage(
           text: "Hello ${widget.employee.firstName}! I'm CemTemBot, ready to assist. What can I get for you?",
           role: 'assistant'
         );
       }
    });

    _socket.on('status', (data) {
      if (data is Map && data['typing'] is bool) {
        if(mounted) setState(() => _isLoading = data['typing']);
      }
    });
    
    _socket.on('bot_message', (data) {
      if (data is Map && data['text'] is String) {
        _addMessage(text: data['text'], role: 'assistant');
      }
       if(mounted) setState(() => _isLoading = false);
    });
  }

  void _addMessage({required String text, required String role}) {
    // --- UPDATED: Uses the public ChatMessage class ---
    final message = ChatMessage(text: text, role: role);
    _chatBox.add(message);
    if (mounted) {
      setState(() {
        _messages.insert(0, message);
      });
    }
    _scrollToBottom();
  }
  
  void _handleSubmitted(String text) {
    if (text.trim().isEmpty || !_isConnected) return;
    _textController.clear();
    _addMessage(text: text, role: 'user');
    
    if(mounted) {
      setState(() {
        _isLoading = true;
      });
    }
    _socket.emit('send_message', {'text': text});
  }
  
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
              _buildStatusBanner(),
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  reverse: true,
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  itemCount: _messages.length,
                  itemBuilder: (_, int index) => _ChatMessageBubble(message: _messages[index]),
                ),
              ),
              if (_isLoading) const _TypingIndicator(),
              _buildTextComposer(),
            ],
          ),
        ),
      ),
    );
  }

  // All other widgets below remain unchanged...
  Widget _buildStatusBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      color: Colors.black.withOpacity(0.2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.support_agent, color: Colors.white, size: 16),
          const SizedBox(width: 8),
          const Text(
            "CemTemBot Status:",
            style: TextStyle(color: Colors.white70, fontSize: 12),
          ),
          const SizedBox(width: 8),
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _isConnected ? Colors.greenAccent : Colors.redAccent,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            _isConnected ? "Connected" : "Disconnected",
            style: TextStyle(
                color: _isConnected ? Colors.greenAccent : Colors.redAccent,
                fontSize: 12,
                fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildTextComposer() {
    return Container(
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
                child: TextField(
                  controller: _textController,
                  onSubmitted: _handleSubmitted,
                  decoration: InputDecoration(
                    hintText: _isConnected ? 'Type your order...' : 'Connecting...',
                    hintStyle: const TextStyle(color: Colors.white70),
                    border: InputBorder.none,
                  ),
                  style: const TextStyle(color: Colors.white),
                  enabled: _isConnected,
                ),
              ),
            ),
            IconButton(
              icon: Icon(Icons.send, color: _isConnected ? Theme.of(context).colorScheme.primary : Colors.grey),
              onPressed: _isConnected ? () => _handleSubmitted(_textController.text) : null,
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
    _socket.dispose();
    super.dispose();
  }
}

class _ChatMessageBubble extends StatelessWidget {
  // --- UPDATED: Uses the public ChatMessage class ---
  final ChatMessage message;
  const _ChatMessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isUser = message.role == 'user';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5.0),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) const CircleAvatar(child: Icon(Icons.support_agent)),
          const SizedBox(width: 8),
          Flexible(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
                decoration: BoxDecoration(
                  color: isUser
                      ? theme.colorScheme.primary
                      : Colors.white.withOpacity(0.15),
                  borderRadius: isUser
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
          if (isUser) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              backgroundColor: theme.colorScheme.secondaryContainer,
              child: const Icon(Icons.person),
            ),
          ]
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.5, end: 0);
  }
}

class _TypingIndicator extends StatelessWidget {
  const _TypingIndicator();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 16.0),
      child: Row(
        children: [
          const CircleAvatar(child: Icon(Icons.support_agent)),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(20.0),
                bottomRight: Radius.circular(20.0),
                topLeft: Radius.circular(20.0),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDot(0),
                const SizedBox(width: 5),
                _buildDot(1),
                const SizedBox(width: 5),
                _buildDot(2),
              ],
            ),
          ),
        ],
      ),
    ).animate(onComplete: (c) => c.repeat()).shimmer(duration: 1200.ms);
  }

  Widget _buildDot(int index) {
    return Container(
      width: 8,
      height: 8,
      decoration: const BoxDecoration(
        color: Colors.white70,
        shape: BoxShape.circle,
      ),
    ).animate().scaleY(
      delay: (index * 200).ms,
      duration: 400.ms,
      curve: Curves.easeInOut,
    ).then(delay: 800.ms).scaleY(
      duration: 400.ms,
      curve: Curves.easeInOut,
    );
  }
}