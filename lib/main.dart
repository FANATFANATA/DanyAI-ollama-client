import "dart:convert";
import "dart:async";
import "package:flutter/material.dart";
import "package:image_picker/image_picker.dart";
import "models/models.dart";
import "services/services.dart";
import "widgets/widgets.dart";

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  FlutterError.onError = (details) => debugPrint("Flutter Error: ${details.exception}");
  final settings = await Settings.load();
  runApp(DanyAIApp(settings: settings));
}

class DanyAIApp extends StatelessWidget {
  const DanyAIApp({required this.settings, super.key});
  final Settings settings;

  ThemeData _getTheme(String name) {
    final isDark = name.contains("dark") || name.contains("black");
    final isBlack = name == "black";
    return ThemeData(
      useMaterial3: true,
      brightness: isDark ? Brightness.dark : Brightness.light,
      scaffoldBackgroundColor: isBlack
          ? Colors.black
          : (isDark ? const Color(0xFF0F1114) : const Color(0xFFF8FAFC)),
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF3B82F6),
        brightness: isDark ? Brightness.dark : Brightness.light,
        surface: isBlack ? Colors.black : (isDark ? const Color(0xFF16191D) : Colors.white),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: isDark ? Colors.white : Colors.black,
          fontSize: 20,
          fontWeight: FontWeight.w900,
        ),
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
  StreamSubscription<Message>? _chatSub;

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
    try {
      final models = await _ollama?.getLocalModels();
      if (mounted && models != null) {
        setState(() => _availableModels = models.map((m) => m["name"] as String).toList());
      }
    } catch (e) {
      debugPrint("Model load error: $e");
    }
  }

  void _scrollToBottom() {
    if (!_scrollController.hasClients) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 500),
        curve: Curves.fastLinearToSlowEaseIn,
      );
    });
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
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Ошибка: $e")));
      }
    }
  }

  void _stopGeneration() {
    _chatSub?.cancel();
    setState(() => _isLoading = false);
    _chatService.save();
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
      _chatSub = _ollama!
          .chat(_chatService.currentChat!.messages)
          .listen(
            (update) {
              _chatService.updateLastMessage(chat, update);
              _scrollToBottom();
            },
            onDone: () {
              setState(() => _isLoading = false);
              _chatService.save();
            },
            onError: (Object e) {
              _chatService.updateLastMessage(chat, assistantMsg.copyWith(content: "Ошибка: $e"));
              setState(() => _isLoading = false);
            },
          );
    } catch (e) {
      _chatService.updateLastMessage(chat, assistantMsg.copyWith(content: "Ошибка: $e"));
      setState(() => _isLoading = false);
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
                  decoration: const InputDecoration(
                    labelText: "Ollama URL",
                    prefixIcon: Icon(Icons.link_rounded),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: sysCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: "System Prompt",
                    border: OutlineInputBorder(),
                    alignLabelWithHint: true,
                  ),
                ),
                const Divider(height: 32),
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
                  contentPadding: EdgeInsets.zero,
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
            FilledButton(
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
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            Text(
              val.toStringAsFixed(2),
              style: const TextStyle(fontFamily: "monospace", fontSize: 12),
            ),
          ],
        ),
        Slider(value: val, min: min, max: max, onChanged: (v) => setState(() => onCh(v))),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentChat = _chatService.currentChat;
    final theme = Theme.of(context);
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: theme.brightness == Brightness.dark
                      ? [const Color(0xFF0F172A), const Color(0xFF020617)]
                      : [const Color(0xFFF1F5F9), const Color(0xFFE2E8F0)],
                ),
              ),
            ),
          ),
          Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeInOutCubic,
                width: _isSidebarVisible ? 300 : 0,
                child: ClipRect(
                  child: OverflowBox(
                    minWidth: 300,
                    maxWidth: 300,
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
                              icon: const Icon(Icons.menu_rounded),
                              onPressed: () => setState(() => _isSidebarVisible = true),
                            )
                          : null,
                      title: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text("DanyAI", style: TextStyle(fontWeight: FontWeight.w900)),
                          if (widget.settings.model.isNotEmpty) ...[
                            const SizedBox(width: 12),
                            Flexible(
                              child: GlassContainer(
                                borderRadius: BorderRadius.circular(20),
                                blur: 10,
                                color: theme.colorScheme.primary.withValues(alpha: 0.15),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.auto_awesome,
                                        size: 14,
                                        color: theme.colorScheme.primary,
                                      ),
                                      const SizedBox(width: 6),
                                      Flexible(
                                        child: Text(
                                          widget.settings.model,
                                          overflow: TextOverflow.ellipsis,
                                          style: theme.textTheme.labelMedium?.copyWith(
                                            color: theme.colorScheme.primary,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      actions: [
                        if (_availableModels.isNotEmpty)
                          PopupMenuButton<String>(
                            icon: const Icon(Icons.tune_rounded),
                            tooltip: "Выбор модели",
                            offset: const Offset(0, 50),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            onSelected: (m) {
                              widget.settings.model = m;
                            },
                            itemBuilder: (context) => _availableModels
                                .map(
                                  (m) => PopupMenuItem(
                                    value: m,
                                    child: Row(
                                      children: [
                                        Icon(
                                          widget.settings.model == m
                                              ? Icons.check_circle_rounded
                                              : Icons.circle_outlined,
                                          size: 18,
                                          color: widget.settings.model == m
                                              ? theme.colorScheme.primary
                                              : theme.hintColor,
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            m,
                                            style: TextStyle(
                                              fontWeight: widget.settings.model == m
                                                  ? FontWeight.bold
                                                  : null,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                        IconButton(
                          icon: const Icon(Icons.cleaning_services_rounded),
                          tooltip: "Очистить",
                          onPressed: _chatService.clearCurrentChat,
                        ),
                        const SizedBox(width: 8),
                      ],
                    ),
                    Expanded(
                      child: currentChat == null || currentChat.messages.isEmpty
                          ? const EmptyChatView()
                          : ListView.builder(
                              controller: _scrollController,
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                              itemCount: currentChat.messages.length,
                              itemBuilder: (context, i) => MessageBubble(
                                key: ValueKey("${currentChat.id}_$i"),
                                isUser: currentChat.messages[i].role == "user",
                                message: currentChat.messages[i],
                                onEdit: (c) => _chatService.editMessage(currentChat, i, c),
                                onDelete: () => _chatService.deleteMessage(currentChat, i),
                              ),
                            ),
                    ),
                    if (_selectedImages.isNotEmpty)
                      Container(
                        height: 100,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _selectedImages.length,
                          itemBuilder: (context, i) => Padding(
                            padding: const EdgeInsets.only(right: 12, top: 8, bottom: 8),
                            child: Hero(
                              tag: "img_$i",
                              child: Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(16),
                                    child: Image.memory(
                                      base64Decode(_selectedImages[i]),
                                      width: 80,
                                      height: 80,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  Positioned(
                                    right: -8,
                                    top: -8,
                                    child: GestureDetector(
                                      onTap: () => setState(() => _selectedImages.removeAt(i)),
                                      child: GlassContainer(
                                        borderRadius: BorderRadius.circular(12),
                                        color: theme.colorScheme.error.withValues(alpha: 0.9),
                                        child: const Padding(
                                          padding: EdgeInsets.all(4),
                                          child: Icon(
                                            Icons.close_rounded,
                                            size: 14,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    if (_isLoading) const LinearProgressIndicator(minHeight: 2),
                    Row(
                      children: [
                        const SizedBox(width: 12),
                        IconButton(
                          icon: const Icon(Icons.add_circle_outline_rounded, size: 28),
                          onPressed: _pickImage,
                          tooltip: "Изображения",
                          color: theme.colorScheme.primary,
                        ),
                        Expanded(
                          child: MessageInput(
                            controller: _controller,
                            isLoading: _isLoading,
                            hintText: "Спроси DanyAI...",
                            onSend: _sendMessage,
                            onStop: _stopGeneration,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _chatSub?.cancel();
    _controller.dispose();
    _scrollController.dispose();
    _ollama?.dispose();
    _chatService.removeListener(_onChatUpdate);
    widget.settings.removeListener(_initOllama);
    super.dispose();
  }
}
