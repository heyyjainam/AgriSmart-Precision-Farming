import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:agrismart/core/theme.dart';
import 'package:agrismart/core/api_config.dart';

// ─── Model ───────────────────────────────────────────────────────────────────
class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime time;
  final bool isError;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.time,
    this.isError = false,
  });
}

// ─── Screen ──────────────────────────────────────────────────────────────────
class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({super.key});
  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> with TickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  bool _isLoading = false;

  late AnimationController _dotController;

  final List<ChatMessage> _messages = [
    ChatMessage(
      text: "🌾 Namaste! I'm your **AgriSmart AI Assistant**, powered by Google Gemini.\n\nAap mujhse pooch sakte hain:\n• Crop recommendations\n• Fertilizer advice\n• Disease treatment\n• Soil & weather tips\n\nKaise help karun aaj? 😊",
      isUser: false,
      time: DateTime.now(),
    ),
  ];

  final List<Map<String, dynamic>> _quickQuestions = [
    {'icon': FontAwesomeIcons.wheatAwn, 'text': 'Best crop for sandy soil?'},
    {'icon': FontAwesomeIcons.flaskVial, 'text': 'Fertilizer for wheat in winter?'},
    {'icon': FontAwesomeIcons.bug, 'text': 'How to treat yellowing leaves?'},
    {'icon': FontAwesomeIcons.droplet, 'text': 'Irrigation tips for summer?'},
    {'icon': FontAwesomeIcons.sun, 'text': 'Effect of heat on paddy?'},
  ];

  @override
  void initState() {
    super.initState();
    _dotController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    _dotController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage(String text) async {
    final query = text.trim();
    if (query.isEmpty || _isLoading) return;

    setState(() {
      _messages.add(ChatMessage(text: query, isUser: true, time: DateTime.now()));
      _isLoading = true;
      _controller.clear();
    });
    _scrollToBottom();

    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/v1/chatbot-query'),
        headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
        body: jsonEncode({'query': query}),
      ).timeout(const Duration(seconds: 60));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _messages.add(ChatMessage(
            text: data['answer']?.toString() ?? 'No response received.',
            isUser: false,
            time: DateTime.now(),
          ));
        });
      } else {
        setState(() {
          _messages.add(ChatMessage(
            text: '⚠️ Server error (${response.statusCode}). Please try again.',
            isUser: false,
            time: DateTime.now(),
            isError: true,
          ));
        });
      }
    } catch (e) {
      setState(() {
        _messages.add(ChatMessage(
          text: '🔌 Connection failed. Make sure the backend server is running at port 8000.\n\n`$e`',
          isUser: false,
          time: DateTime.now(),
          isError: true,
        ));
      });
    } finally {
      setState(() => _isLoading = false);
      _scrollToBottom();
      _focusNode.requestFocus();
    }
  }

  void _clearChat() {
    setState(() {
      _messages.clear();
      _messages.add(ChatMessage(
        text: "Chat cleared! 🌿 How can I help you with your farm today?",
        isUser: false,
        time: DateTime.now(),
      ));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Left sidebar (quick questions) ──
          _buildSidebar(),
          const SizedBox(width: 20),
          // ── Main chat window ──
          Expanded(child: _buildChatWindow()),
        ],
      ),
    );
  }

  // ─── Sidebar ─────────────────────────────────────────────────────────────────
  Widget _buildSidebar() {
    return Container(
      width: 240,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Bot info header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppTheme.primaryColor, const Color(0xFF43A047)],
                begin: Alignment.topLeft, end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
                  child: const Icon(FontAwesomeIcons.robot, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 10),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('AgriBot AI', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                  Row(children: [
                    Container(width: 6, height: 6, decoration: const BoxDecoration(color: Color(0xFF69F0AE), shape: BoxShape.circle)),
                    const SizedBox(width: 5),
                    Text('Online · Gemini AI', style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 11)),
                  ]),
                ]),
              ]),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
                child: Text(
                  'Specialized in agriculture, crop science, and smart farming',
                  style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 11, height: 1.4),
                ),
              ),
            ]),
          ),

          // Quick questions label
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text('💡 Quick Questions', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.textPrimary)),
          ),

          // Quick question chips
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              itemCount: _quickQuestions.length,
              itemBuilder: (_, i) {
                final q = _quickQuestions[i];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: InkWell(
                    onTap: _isLoading ? null : () => _sendMessage(q['text']),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.primaryColor.withOpacity(0.12)),
                      ),
                      child: Row(children: [
                        FaIcon(q['icon'] as IconData, size: 12, color: AppTheme.primaryColor),
                        const SizedBox(width: 8),
                        Expanded(child: Text(q['text'] as String, style: TextStyle(fontSize: 12, color: AppTheme.textPrimary, height: 1.3))),
                      ]),
                    ),
                  ),
                );
              },
            ),
          ),

          // Footer capabilities
          Container(
            margin: const EdgeInsets.all(10),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green.shade100),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Capabilities', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.green.shade700)),
              const SizedBox(height: 6),
              ...[
                '🌱 Crop Recommendation',
                '🧪 Fertilizer Advice',
                '🦠 Disease Diagnosis',
                '🌦️ Weather Farming Tips',
              ].map((c) => Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Text(c, style: TextStyle(fontSize: 11, color: Colors.green.shade800)),
              )),
            ]),
          ),
        ],
      ),
    );
  }

  // ─── Chat Window ─────────────────────────────────────────────────────────────
  Widget _buildChatWindow() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(children: [
        _buildChatHeader(),
        Expanded(child: _buildMessageList()),
        _buildInputArea(),
      ]),
    );
  }

  Widget _buildChatHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
      ),
      child: Row(children: [
        // Avatar with pulse
        Stack(children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: AppTheme.primaryColor.withOpacity(0.12),
            child: const FaIcon(FontAwesomeIcons.robot, color: AppTheme.primaryColor, size: 18),
          ),
          Positioned(bottom: 0, right: 0,
            child: Container(width: 10, height: 10,
              decoration: BoxDecoration(color: const Color(0xFF4CAF50), shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1.5)),
            ),
          ),
        ]),
        const SizedBox(width: 12),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Agri Assistant AI', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.textPrimary)),
          Text(_isLoading ? '✍️ Typing...' : 'Powered by Google Gemini',
              style: TextStyle(fontSize: 11, color: _isLoading ? AppTheme.primaryColor : AppTheme.textSecondary,
                  fontWeight: _isLoading ? FontWeight.w600 : FontWeight.normal)),
        ]),
        const Spacer(),
        // Message count badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withOpacity(0.08),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text('${_messages.length} messages', style: TextStyle(fontSize: 11, color: AppTheme.primaryColor, fontWeight: FontWeight.w500)),
        ),
        const SizedBox(width: 8),
        // Clear chat button
        Tooltip(
          message: 'Clear chat',
          child: InkWell(
            onTap: _clearChat,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(8)),
              child: Icon(FontAwesomeIcons.trash, size: 13, color: Colors.red.shade400),
            ),
          ),
        ),
      ]),
    );
  }

  Widget _buildMessageList() {
    return Container(
      color: const Color(0xFFF8FBF8),
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(20),
        itemCount: _messages.length + (_isLoading ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _messages.length) return _buildTypingIndicator();
          return _buildMessageBubble(_messages[index]);
        },
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage msg) {
    final isUser = msg.isUser;
    final timeStr = '${msg.time.hour.toString().padLeft(2, '0')}:${msg.time.minute.toString().padLeft(2, '0')}';

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: AppTheme.primaryColor.withOpacity(0.12),
              child: const FaIcon(FontAwesomeIcons.robot, color: AppTheme.primaryColor, size: 13),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                // Bubble
                GestureDetector(
                  onLongPress: () {
                    Clipboard.setData(ClipboardData(text: msg.text));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Copied to clipboard'), duration: Duration(seconds: 1)),
                    );
                  },
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 520),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      gradient: isUser
                          ? LinearGradient(colors: [AppTheme.primaryColor, const Color(0xFF43A047)])
                          : null,
                      color: isUser
                          ? null
                          : msg.isError
                              ? Colors.red.shade50
                              : Colors.white,
                      borderRadius: BorderRadius.circular(18).copyWith(
                        bottomRight: isUser ? const Radius.circular(4) : const Radius.circular(18),
                        bottomLeft: !isUser ? const Radius.circular(4) : const Radius.circular(18),
                      ),
                      border: isUser
                          ? null
                          : Border.all(
                              color: msg.isError ? Colors.red.shade200 : Colors.grey.shade200,
                            ),
                      boxShadow: [
                        BoxShadow(
                          color: isUser
                              ? AppTheme.primaryColor.withOpacity(0.25)
                              : Colors.black.withOpacity(0.04),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      msg.text,
                      style: TextStyle(
                        color: isUser ? Colors.white : msg.isError ? Colors.red.shade800 : AppTheme.textPrimary,
                        fontSize: 14,
                        height: 1.5,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                // Timestamp + copy hint
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(timeStr, style: TextStyle(fontSize: 10, color: Colors.grey.shade400)),
                    if (!isUser) ...[
                      const SizedBox(width: 4),
                      Text('· hold to copy', style: TextStyle(fontSize: 10, color: Colors.grey.shade400)),
                    ],
                  ],
                ),
              ],
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 16,
              backgroundColor: AppTheme.primaryColor,
              child: const Icon(Icons.person, color: Colors.white, size: 16),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
        CircleAvatar(
          radius: 16,
          backgroundColor: AppTheme.primaryColor.withOpacity(0.12),
          child: const FaIcon(FontAwesomeIcons.robot, color: AppTheme.primaryColor, size: 13),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(18), topRight: Radius.circular(18), bottomRight: Radius.circular(18),
            ),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
          ),
          child: AnimatedBuilder(
            animation: _dotController,
            builder: (_, __) {
              return Row(mainAxisSize: MainAxisSize.min, children: List.generate(3, (i) {
                final offset = ((_dotController.value * 3) - i).clamp(0.0, 1.0);
                final bounce = offset < 0.5 ? offset * 2 : (1 - offset) * 2;
                return Transform.translate(
                  offset: Offset(0, -6 * bounce),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: 8, height: 8,
                    decoration: BoxDecoration(color: AppTheme.primaryColor.withOpacity(0.6 + bounce * 0.4), shape: BoxShape.circle),
                  ),
                );
              }));
            },
          ),
        ),
      ]),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
        border: Border(top: BorderSide(color: Colors.grey.shade100)),
      ),
      child: Column(children: [
        // Scrollable quick-reply chips
        SizedBox(
          height: 34,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: _quickQuestions.map((q) => Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: _isLoading ? null : () => _sendMessage(q['text'] as String),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _isLoading ? Colors.grey.shade100 : AppTheme.primaryColor.withOpacity(0.07),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _isLoading ? Colors.grey.shade200 : AppTheme.primaryColor.withOpacity(0.2)),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    FaIcon(q['icon'] as IconData, size: 11, color: _isLoading ? Colors.grey : AppTheme.primaryColor),
                    const SizedBox(width: 5),
                    Text(q['text'] as String, style: TextStyle(fontSize: 11.5, color: _isLoading ? Colors.grey : AppTheme.primaryColor, fontWeight: FontWeight.w500)),
                  ]),
                ),
              ),
            )).toList(),
          ),
        ),
        const SizedBox(height: 10),

        // Input row
        Row(children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF5F7F5),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppTheme.primaryColor.withOpacity(0.15)),
              ),
              child: Row(children: [
                const SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    controller: _controller,
                    focusNode: _focusNode,
                    enabled: !_isLoading,
                    maxLines: null,
                    keyboardType: TextInputType.multiline,
                    textInputAction: TextInputAction.send,
                    onSubmitted: _sendMessage,
                    style: const TextStyle(fontSize: 14, color: AppTheme.textPrimary),
                    decoration: InputDecoration(
                      hintText: 'Ask about crops, fertilizers, diseases...',
                      hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 13),
                    ),
                  ),
                ),
                // Char counter when typing
                ValueListenableBuilder<TextEditingValue>(
                  valueListenable: _controller,
                  builder: (_, val, __) => val.text.isNotEmpty
                      ? Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: Text('${val.text.length}', style: TextStyle(fontSize: 11, color: Colors.grey.shade400)),
                        )
                      : const SizedBox.shrink(),
                ),
              ]),
            ),
          ),
          const SizedBox(width: 10),
          // Send button
          GestureDetector(
            onTap: _isLoading ? null : () => _sendMessage(_controller.text),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 48, height: 48,
              decoration: BoxDecoration(
                gradient: _isLoading
                    ? null
                    : const LinearGradient(colors: [AppTheme.primaryColor, Color(0xFF43A047)]),
                color: _isLoading ? Colors.grey.shade200 : null,
                shape: BoxShape.circle,
                boxShadow: _isLoading
                    ? []
                    : [BoxShadow(color: AppTheme.primaryColor.withOpacity(0.35), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: _isLoading
                  ? const Padding(
                      padding: EdgeInsets.all(14),
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primaryColor),
                    )
                  : const Icon(FontAwesomeIcons.paperPlane, color: Colors.white, size: 18),
            ),
          ),
        ]),
      ]),
    );
  }
}
