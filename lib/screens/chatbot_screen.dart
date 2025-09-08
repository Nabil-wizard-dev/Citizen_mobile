import 'package:flutter/material.dart';
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:uuid/uuid.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math';
import 'package:flutter/scheduler.dart';

class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({Key? key}) : super(key: key);

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> with SingleTickerProviderStateMixin {
  final List<types.Message> _messages = [];
  final types.User _user = const types.User(id: 'user');
  final types.User _bot = const types.User(id: 'bot', firstName: 'Bot');
  bool _isLoading = false;
  String? _openRouterApiKey;
  String _model = 'openrouter/auto';
  List<Map<String, String>> _chatHistory = [];
  bool _botTyping = false;
  late AnimationController _bgController;
  final TextEditingController _textController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadApiKey();
    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _bgController.dispose();
    _textController.dispose();
    super.dispose();
  }

  Future<void> _loadApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _openRouterApiKey = prefs.getString('openrouter_api_key');
      _model = prefs.getString('openrouter_model') ?? 'openrouter/auto';
    });
  }

  Future<void> _saveApiKey(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('openrouter_api_key', key);
    setState(() {
      _openRouterApiKey = key;
    });
  }

  Future<void> _saveModel(String model) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('openrouter_model', model);
    setState(() {
      _model = model;
    });
  }

  Future<void> _sendMessage(String text) async {
    final userMessage = types.TextMessage(
      author: _user,
      createdAt: DateTime.now().millisecondsSinceEpoch,
      id: const Uuid().v4(),
      text: text,
    );
    setState(() {
      _messages.insert(0, userMessage);
      _isLoading = true;
      _botTyping = true;
    });
    _chatHistory.add({"role": "user", "content": text});
    try {
      await Future.delayed(const Duration(milliseconds: 800)); // Effet typing
      final botReply = await _fetchBotReply();
      final botMessage = types.TextMessage(
        author: _bot,
        createdAt: DateTime.now().millisecondsSinceEpoch,
        id: const Uuid().v4(),
        text: botReply,
      );
      setState(() {
        _messages.insert(0, botMessage);
      });
      _chatHistory.add({"role": "assistant", "content": botReply});
    } catch (e) {
      final errorMessage = types.TextMessage(
        author: _bot,
        createdAt: DateTime.now().millisecondsSinceEpoch,
        id: const Uuid().v4(),
        text: "Erreur lors de la connexion au chatbot : $e",
      );
      setState(() {
        _messages.insert(0, errorMessage);
      });
    } finally {
      setState(() {
        _isLoading = false;
        _botTyping = false;
      });
    }
  }

  Future<String> _fetchBotReply() async {
    if (_openRouterApiKey == null) throw Exception('Aucune clé API OpenRouter.');
    const apiUrl = 'https://openrouter.ai/api/v1/chat/completions';
    final body = {
      "model": _model,
      "messages": _chatHistory,
      "max_tokens": 256,
      "temperature": 0.7
    };
    final response = await http.post(
      Uri.parse(apiUrl),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $_openRouterApiKey",
        "HTTP-Referer": "https://tonapp.com/",
        "X-Title": "PPE Mobile Chatbot"
      },
      body: jsonEncode(body),
    );
    if (response.statusCode == 200) {
      // Correction encodage UTF-8
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      return data['choices'][0]['message']['content']?.trim() ?? "(Pas de réponse)";
    } else if (response.statusCode == 401) {
      throw Exception('Clé API OpenRouter invalide.');
    } else {
      throw Exception('Erreur API: ${response.statusCode}');
    }
  }

  void _handleSendPressed(types.PartialText message) {
    _sendMessage(message.text);
  }

  void _showApiKeyDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Entrer votre clé API OpenRouter'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'sk-or-...'),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              _saveApiKey(controller.text.trim());
              Navigator.of(context).pop();
            },
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );
  }

  void _showModelDialog() {
    final controller = TextEditingController(text: _model);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Choisir le modèle OpenRouter'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'openrouter/auto'),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              _saveModel(controller.text.trim());
              Navigator.of(context).pop();
            },
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Row(
      children: [
        Container(
          margin: const EdgeInsets.only(left: 12, bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.deepPurple.withOpacity(0.15),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 400),
                width: 8,
                height: 8,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  color: Colors.deepPurple,
                  shape: BoxShape.circle,
                ),
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 600),
                width: 8,
                height: 8,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  color: Colors.deepPurple.withOpacity(0.7),
                  shape: BoxShape.circle,
                ),
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 800),
                width: 8,
                height: 8,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  color: Colors.deepPurple.withOpacity(0.4),
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(80),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDark
                  ? [Colors.black87, Colors.deepPurple.shade900]
                  : [const Color(0xFF6D5DF6), const Color(0xFF4FC3F7)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: SafeArea(
            child: Row(
              children: [
                const SizedBox(width: 16),
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: Colors.white,
                      child: CircleAvatar(
                        radius: 25,
                        backgroundColor: Colors.deepPurple,
                        child: Icon(Icons.smart_toy, color: Colors.white, size: 32),
                      ),
                    ),
                    Positioned(
                      bottom: 6,
                      right: 6,
                      child: Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          color: Colors.greenAccent,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Chatbot IA', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                    AnimatedOpacity(
                      opacity: _botTyping ? 1 : 0.7,
                      duration: const Duration(milliseconds: 400),
                      child: Text(
                        _botTyping ? 'Le bot réfléchit...' : 'En ligne',
                        style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 14),
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.vpn_key, color: Colors.white),
                  tooltip: 'Configurer la clé OpenRouter',
                  onPressed: _showApiKeyDialog,
                ),
                IconButton(
                  icon: const Icon(Icons.settings, color: Colors.white),
                  tooltip: 'Choisir le modèle',
                  onPressed: _showModelDialog,
                ),
                const SizedBox(width: 8),
              ],
            ),
          ),
        ),
      ),
      body: AnimatedBuilder(
        animation: _bgController,
        builder: (context, child) {
          final t = _bgController.value;
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? [Colors.black, Colors.deepPurple.shade900]
                    : [
                        Color.lerp(const Color(0xFF6D5DF6), const Color(0xFF4FC3F7), t)!,
                        Color.lerp(const Color(0xFF4FC3F7), const Color(0xFF6D5DF6), t)!,
                      ],
              ),
            ),
            child: SafeArea(
              child: _openRouterApiKey == null
                  ? Center(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.vpn_key),
                        label: const Text('Entrer la clé API OpenRouter'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurple,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        onPressed: _showApiKeyDialog,
                      ),
                    )
                  : Stack(
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: ListView.builder(
                            reverse: true,
                            padding: const EdgeInsets.only(top: 12, bottom: 70),
                            itemCount: _messages.length + (_botTyping ? 1 : 0),
                            itemBuilder: (context, index) {
                              if (_botTyping && index == 0) {
                                return _buildTypingIndicator();
                              }
                              final msg = _messages[_botTyping ? index - 1 : index];
                              final isBot = msg.author.id == 'bot';
                              return AnimatedContainer(
                                duration: const Duration(milliseconds: 400),
                                curve: Curves.easeOut,
                                margin: EdgeInsets.only(
                                  left: isBot ? 8 : 60,
                                  right: isBot ? 60 : 8,
                                  top: 8,
                                  bottom: 2,
                                ),
                                child: Align(
                                  alignment: isBot ? Alignment.centerLeft : Alignment.centerRight,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                                    decoration: BoxDecoration(
                                      color: isBot ? Colors.white : const Color(0xFF6D5DF6),
                                      borderRadius: BorderRadius.only(
                                        topLeft: const Radius.circular(20),
                                        topRight: const Radius.circular(20),
                                        bottomLeft: isBot ? const Radius.circular(8) : const Radius.circular(20),
                                        bottomRight: isBot ? const Radius.circular(20) : const Radius.circular(8),
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: isBot ? Colors.deepPurple.withOpacity(0.08) : Colors.deepPurple.withOpacity(0.18),
                                          blurRadius: 16,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: Text(
                                      msg is types.TextMessage ? msg.text : '',
                                      style: TextStyle(
                                        color: isBot ? Colors.black87 : Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: 0,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: isDark ? Colors.black.withOpacity(0.85) : Colors.white.withOpacity(0.95),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.08),
                                  blurRadius: 8,
                                  offset: const Offset(0, -2),
                                ),
                              ],
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(24),
                                topRight: Radius.circular(24),
                              ),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: _textController,
                                    onSubmitted: (txt) {
                                      if (txt.trim().isNotEmpty) {
                                        _handleSendPressed(types.PartialText(text: txt.trim()));
                                        _textController.clear();
                                      }
                                    },
                                    style: const TextStyle(fontSize: 16),
                                    decoration: InputDecoration(
                                      hintText: 'Écrivez votre message... ',
                                      border: InputBorder.none,
                                    ),
                                    cursorColor: const Color(0xFF6D5DF6),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                GestureDetector(
                                  onTap: () {
                                    final txt = _textController.text.trim();
                                    if (txt.isNotEmpty) {
                                      _handleSendPressed(types.PartialText(text: txt));
                                      _textController.clear();
                                    }
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF6D5DF6),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.send, color: Colors.white, size: 22),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        if (_isLoading)
                          Positioned(
                            left: 0,
                            right: 0,
                            bottom: 70,
                            child: Center(
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.7),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                    ),
                                    SizedBox(width: 12),
                                    Text('Le bot réfléchit...', style: TextStyle(color: Colors.white)),
                                  ],
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
            ),
          );
        },
      ),
    );
  }
} 