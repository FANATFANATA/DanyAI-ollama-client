import "dart:convert";
import "package:flutter/material.dart";
import "package:image_picker/image_picker.dart";
import "models/models.dart";
import "services/services.dart";
import "widgets/widgets.dart";

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final settings = await Settings.load();
  runApp(DanyAIApp(settings: settings));
}

class DanyAIApp extends StatelessWidget {
  const DanyAIApp({required this.settings, super.key});
  final Settings settings;

  ThemeData _getTheme(String name) {
    final isDark = name.contains("dark") || name.contains("black");
    return ThemeData(
      useMaterial3: true,
      brightness: isDark ? Brightness.dark : Brightness.light,
      scaffoldBackgroundColor: name == "black" ? Colors.black : null,
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.blue,
        brightness: isDark ? Brightness.dark : Brightness.light,
        surface: name == "black" ? Colors.black : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: settings,
      builder: (context, _) => MaterialApp(
        title: "DanyAI",
        debugShowCheckedModeBanner: false,
        theme: _getTheme(settings.theme),
        home: ChatScreen(settings: settings),
      ),
    );
  }
}

class ChatScreen extends StatefulWidget {
  const ChatScreen({required this.settings, super.key});
  final Settings settings;
  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ChatService _chatService = ChatService();
  final ImagePicker _picker = ImagePicker();
  final List<String> _selectedImages = [];
  bool _isLoading = false;
  OllamaService? _ollama;
  bool _isSidebarVisible = true;
  List<String> _availableModels = <String>[];

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await _chatService.load();
    _chatService.addListener(_onChatUpdate);
    widget.settings.addListener(_initOllama);
    _initOllama();
  }

  void _onChatUpdate() => setState(() {});

  void _initOllama() {
    _ollama?.dispose();
    _ollama = OllamaService(widget.settings);
    _loadModels();
  }

  Future<void> _loadModels() async {
    final models = await _ollama?.getLocalModels();
    if (mounted && models != null) {
      setState(() => _availableModels = models.map((m) => m["name"] as String).toList());
    }
  }

  void _scrollToBottom() {
    if (!_scrollController.hasClients) return;
    final pos = _scrollController.position;
    if (pos.maxScrollExtent - pos.pixels < 200) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      });
    }
  }

  Future<void> _pickImage() async {
    try {
      final images = await _picker.pickMultiImage();
      if (images.isNotEmpty) {
        for (var img in images) {
          final bytes = await img.readAsBytes();
          setState(() => _selectedImages.add(base64Encode(bytes)));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Ошибка выбора изображений: $e")));
      }
    }
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if ((text.isEmpty && _selectedImages.isEmpty) || _isLoading || _ollama == null) return;
    if (_chatService.currentChat == null) await _chatService.createChat();
    final chat = _chatService.currentChat!;

    final userMsg = Message(role: "user", content: text, images: List.from(_selectedImages));

    setState(() {
      _controller.clear();
      _selectedImages.clear();
      _isLoading = true;
    });

    await _chatService.addMessage(chat, userMsg);
    _scrollToBottom();

    final assistantMsg = Message(role: "assistant", content: "", thinking: "");
    await _chatService.addMessage(chat, assistantMsg);

    try {
      await for (final update in _ollama!.chat(_chatService.currentChat!.messages)) {
        await _chatService.updateLastMessage(chat, update);
        _scrollToBottom();
      }
      await _chatService.save();
    } catch (e) {
      await _chatService.updateLastMessage(chat, assistantMsg.copyWith(content: "Ошибка: $e"));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _showSettings() async {
    final sysCtrl = TextEditingController(text: widget.settings.systemPrompt);
    final urlCtrl = TextEditingController(text: widget.settings.baseUrl);
    return showDialog<void>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text("Настройки"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: urlCtrl,
                  decoration: const InputDecoration(labelText: "Ollama URL"),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: sysCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: "System Prompt",
                    border: OutlineInputBorder(),
                  ),
                ),
                const Divider(),
                _slider(
                  setDialogState,
                  "Temperature",
                  widget.settings.temperature,
                  0,
                  2,
                  (v) => widget.settings.temperature = v,
                ),
                _slider(
                  setDialogState,
                  "Top P",
                  widget.settings.topP,
                  0,
                  1,
                  (v) => widget.settings.topP = v,
                ),
                _slider(
                  setDialogState,
                  "Top K",
                  widget.settings.topK.toDouble(),
                  1,
                  100,
                  (v) => widget.settings.topK = v.toInt(),
                ),
                _slider(
                  setDialogState,
                  "Repeat Penalty",
                  widget.settings.repeatPenalty,
                  0,
                  2,
                  (v) => widget.settings.repeatPenalty = v,
                ),
                ListTile(
                  title: const Text("Context Length"),
                  trailing: DropdownButton<int>(
                    value: widget.settings.numCtx,
                    items: [
                      2048,
                      4096,
                      8192,
                      16384,
                      32768,
                      65536,
                      131072,
                    ].map((e) => DropdownMenuItem(value: e, child: Text("$e"))).toList(),
                    onChanged: (v) => setDialogState(() => widget.settings.numCtx = v!),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Отмена")),
            ElevatedButton(
              onPressed: () async {
                widget.settings.baseUrl = urlCtrl.text;
                widget.settings.systemPrompt = sysCtrl.text;
                await widget.settings.save();
                if (context.mounted) Navigator.pop(context);
              },
              child: const Text("Сохранить"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _slider(
    StateSetter setState,
    String label,
    double val,
    double min,
    double max,
    void Function(double) onCh,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("$label: ${val.toStringAsFixed(2)}"),
        Slider(value: val, min: min, max: max, onChanged: (v) => setState(() => onCh(v))),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentChat = _chatService.currentChat;
    return Scaffold(
      body: Row(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            width: _isSidebarVisible ? 280 : 0,
            child: ClipRect(
              child: OverflowBox(
                minWidth: 280,
                maxWidth: 280,
                alignment: Alignment.centerLeft,
                child: ChatSidebar(
                  chats: _chatService.chats,
                  currentChat: currentChat,
                  settings: widget.settings,
                  onSelectChat: _chatService.selectChat,
                  onNewChat: _chatService.createChat,
                  onDeleteChat: _chatService.deleteChat,
                  onRenameChat: _chatService.renameChat,
                  onToggleSidebar: () => setState(() => _isSidebarVisible = false),
                  onSettingsPressed: _showSettings,
                ),
              ),
            ),
          ),
          Expanded(
            child: Column(
              children: [
                AppBar(
                  leading: !_isSidebarVisible
                      ? IconButton(
                          icon: const Icon(Icons.menu),
                          onPressed: () => setState(() => _isSidebarVisible = true),
                        )
                      : null,
                  title: const Text("DanyAI"),
                  actions: [
                    if (_availableModels.isNotEmpty)
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.smart_toy),
                        tooltip: "Выбрать модель",
                        onSelected: (m) {
                          widget.settings.model = m;
                          widget.settings.save();
                        },
                        itemBuilder: (context) => _availableModels
                            .map(
                              (m) => PopupMenuItem(
                                value: m,
                                child: Text(
                                  m,
                                  style: TextStyle(
                                    fontWeight: widget.settings.model == m ? FontWeight.bold : null,
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    IconButton(
                      icon: const Icon(Icons.delete_sweep),
                      tooltip: "Очистить чат",
                      onPressed: _chatService.clearCurrentChat,
                    ),
                  ],
                ),
                Expanded(
                  child: currentChat == null || currentChat.messages.isEmpty
                      ? const EmptyChatView()
                      : ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          itemCount: currentChat.messages.length,
                          itemBuilder: (context, i) => MessageBubble(
                            key: ValueKey<String>(
                              "${currentChat.id}_${i}_${currentChat.messages[i].content.hashCode}",
                            ),
                            isUser: currentChat.messages[i].role == "user",
                            message: currentChat.messages[i],
                            onEdit: (c) => _chatService.editMessage(currentChat, i, c),
                            onDelete: () => _chatService.deleteMessage(currentChat, i),
                          ),
                        ),
                ),
                if (_selectedImages.isNotEmpty)
                  Container(
                    height: 80,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _selectedImages.length,
                      itemBuilder: (context, i) => Stack(
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.memory(
                                base64Decode(_selectedImages[i]),
                                width: 70,
                                height: 70,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          Positioned(
                            right: 0,
                            top: 0,
                            child: GestureDetector(
                              onTap: () => setState(() => _selectedImages.removeAt(i)),
                              child: const CircleAvatar(
                                radius: 10,
                                backgroundColor: Colors.red,
                                child: Icon(Icons.close, size: 12, color: Colors.white),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                if (_isLoading) const LinearProgressIndicator(minHeight: 2),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    children: [
                      IconButton(icon: const Icon(Icons.image), onPressed: _pickImage),
                      Expanded(
                        child: MessageInput(
                          controller: _controller,
                          isLoading: _isLoading,
                          hintText: "Спроси DanyAI...",
                          onSend: _sendMessage,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _ollama?.dispose();
    _chatService.removeListener(_onChatUpdate);
    widget.settings.removeListener(_initOllama);
    super.dispose();
  }
}
