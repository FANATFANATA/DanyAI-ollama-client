import "package:flutter/material.dart";
import "../models/chat.dart";
import "../services/settings.dart";
import "../services/ollama_service.dart";
import "model_manager.dart";

class ChatSidebar extends StatelessWidget {
  const ChatSidebar({
    required this.chats,
    required this.currentChat,
    required this.settings,
    required this.onSelectChat,
    required this.onNewChat,
    required this.onDeleteChat,
    required this.onRenameChat,
    required this.onToggleSidebar,
    required this.onSettingsPressed,
    super.key,
  });

  final List<Chat> chats;
  final Chat? currentChat;
  final Settings settings;
  final void Function(Chat) onSelectChat;
  final VoidCallback onNewChat;
  final void Function(Chat) onDeleteChat;
  final void Function(Chat, String) onRenameChat;
  final VoidCallback onToggleSidebar;
  final VoidCallback onSettingsPressed;

  void _showRenameDialog(BuildContext context, Chat chat) {
    final ctrl = TextEditingController(text: chat.title);
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Переименовать чат"),
        content: TextField(controller: ctrl, autofocus: true),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Отмена")),
          TextButton(
            onPressed: () {
              onRenameChat(chat, ctrl.text);
              Navigator.pop(context);
            },
            child: const Text("ОК"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: 280,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        border: Border(right: BorderSide(color: theme.dividerColor, width: 0.5)),
      ),
      child: Column(
        children: [
          SafeArea(
            child: ListTile(
              title: const Text("DanyAI", style: TextStyle(fontWeight: FontWeight.bold)),
              leading: const Icon(Icons.auto_awesome),
              trailing: IconButton(icon: const Icon(Icons.menu_open), onPressed: onToggleSidebar),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: ElevatedButton.icon(
              onPressed: onNewChat,
              icon: const Icon(Icons.add),
              label: const Text("Новый чат"),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: chats.length,
              itemBuilder: (context, i) {
                final chat = chats[i];
                final isSel = currentChat?.id == chat.id;
                return ListTile(
                  selected: isSel,
                  title: Text(chat.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                  onTap: () => onSelectChat(chat),
                  onLongPress: () => _showRenameDialog(context, chat),
                  trailing: isSel
                      ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit_outlined, size: 18),
                              onPressed: () => _showRenameDialog(context, chat),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, size: 18),
                              onPressed: () => onDeleteChat(chat),
                            ),
                          ],
                        )
                      : null,
                );
              },
            ),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.layers),
            title: const Text("Модели"),
            onTap: () => Navigator.push<void>(
              context,
              MaterialPageRoute<void>(
                builder: (_) => ModelManager(ollama: OllamaService(settings)),
              ),
            ),
          ),
          _ThemeSelector(settings: settings),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text("Настройки"),
            onTap: onSettingsPressed,
          ),
        ],
      ),
    );
  }
}

class _ThemeSelector extends StatelessWidget {
  const _ThemeSelector({required this.settings});
  final Settings settings;
  @override
  Widget build(BuildContext context) {
    final themes = [
      {"id": "light", "icon": Icons.light_mode},
      {"id": "dark", "icon": Icons.dark_mode},
      {"id": "black", "icon": Icons.brightness_3},
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: themes.map((t) {
          final isSel = settings.theme == t["id"];
          return IconButton(
            icon: Icon(t["icon"] as IconData),
            color: isSel ? Theme.of(context).colorScheme.primary : null,
            onPressed: () => settings.theme = t["id"] as String,
          );
        }).toList(),
      ),
    );
  }
}
