import 'package:assetarchiverflutter/models/employee_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
// --- NEW: IMPORTED THE SOCKET.IO CLIENT LIBRARY ---
import 'package:socket_io_client/socket_io_client.dart' as IO;

// A model for a chat message, now with a role
class _ChatMessage {
  final String text;
  final String role; // 'user' or 'assistant'
  _ChatMessage({required this.text, required this.role});
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
  
  // --- NEW: STATE VARIABLES FOR SOCKET CONNECTION ---
  late IO.Socket _socket;
  bool _isConnected = false;
  bool _isLoading = false; // For the "typing" indicator

  @override
  void initState() {
    super.initState();
    _connectToSocket();
  }

  // --- UPDATED: THIS FUNCTION NOW INCLUDES THE CORRECT CONNECTION PATH ---
  void _connectToSocket() {
    const socketUrl = 'https://python-ai-agent.onrender.com';

    // FIXED: Removed the custom 'Origin' header, which was causing the 400 Bad Request error.
    // The client will now use its default headers, which should be accepted by the server.
    _socket = IO.io(socketUrl, <String, dynamic>{
      'path': '/socket.io',
      'transports': ['websocket', 'polling'], 
      'autoConnect': false, // We will connect manually
      'reconnection': true,
      'reconnectionAttempts': 0, // 0 = infinite
      'reconnectionDelay': 500,
      'reconnectionDelayMax': 5000,
      'timeout': 20000,
      'pingInterval': 25000,
      'pingTimeout': 60000,
    });


    // Manually connect to the server.
    _socket.connect();

    _socket.onConnect((_) {
      debugPrint('Socket connected');
      setState(() => _isConnected = true);
    });

    _socket.onDisconnect((_) {
      debugPrint('Socket disconnected');
      setState(() => _isConnected = false);
    });

    _socket.on('connect_error', (data) => debugPrint('Connect Error: $data'));
    _socket.on('error', (data) => debugPrint('Socket Error: $data'));
    
    // Listen for the welcome message
    _socket.on('ready', (_) {
       if (_messages.isEmpty) {
         _addBotMessage("Hello ${widget.employee.firstName}! I'm CemTemBot, ready to assist with your sales order. What can I get for you?");
       }
    });

    // Listen for the bot's "typing" status
    _socket.on('status', (data) {
      if (data is Map && data['typing'] is bool) {
        setState(() => _isLoading = data['typing']);
      }
    });
    
    // The main event for receiving messages from the bot
    _socket.on('bot_message', (data) {
      if (data is Map && data['text'] is String) {
        _addBotMessage(data['text']);
      }
       setState(() => _isLoading = false); // Stop loading when message arrives
    });
  }

  void _addBotMessage(String text) {
    setState(() {
      _messages.insert(0, _ChatMessage(text: text, role: 'assistant'));
    });
    _scrollToBottom();
  }
  
  // --- UPDATED: THIS NOW EMITS A MESSAGE TO THE SOCKET SERVER ---
  void _handleSubmitted(String text) {
    if (text.trim().isEmpty || !_isConnected) return;
    _textController.clear();

    setState(() {
      _messages.insert(0, _ChatMessage(text: text, role: 'user'));
      _isLoading = true; // Show typing indicator immediately
    });
    _scrollToBottom();
    
    // Send the user's message to the server
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
              // --- NEW: CONNECTION STATUS INDICATOR ---
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
               // --- NEW: TYPING INDICATOR ---
              if (_isLoading) const _TypingIndicator(),
              _buildTextComposer(),
            ],
          ),
        ),
      ),
    );
  }

  // --- NEW: WIDGET FOR THE STATUS BANNER AT THE TOP ---
  Widget _buildStatusBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      color: Colors.black.withOpacity(0.2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.support_agent, color: Colors.white, size: 16),
          const SizedBox(width: 8),
          Text(
            "CemTemBot Status:",
            style: const TextStyle(color: Colors.white70, fontSize: 12),
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
    _socket.dispose(); // Disconnect the socket when the screen is closed
    super.dispose();
  }
}

class _ChatMessageBubble extends StatelessWidget {
  final _ChatMessage message;
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
          if (!isUser)
            const CircleAvatar(child: Icon(Icons.support_agent)),
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

// --- NEW: WIDGET FOR THE "BOT IS TYPING" INDICATOR ---
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

