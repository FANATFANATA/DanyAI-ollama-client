import "package:flutter/material.dart";
import "../models/chat.dart";
import "../services/settings.dart";
import "../services/ollama_service.dart";
import "model_manager.dart";
import "glass_container.dart";

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
        title: const Text("Переименовать"),
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
    return GlassContainer(
      blur: 25,
      color: theme.colorScheme.surfaceContainerLow.withValues(alpha: 0.8),
      border: Border(right: BorderSide(color: theme.dividerColor.withValues(alpha: 0.1))),
      child: Column(
        children: [
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Hero(
                    tag: "logo",
                    child: Icon(Icons.auto_awesome, color: theme.colorScheme.primary, size: 28),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      "DanyAI",
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                  IconButton(icon: const Icon(Icons.menu_open), onPressed: onToggleSidebar),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: FilledButton.icon(
              onPressed: onNewChat,
              icon: const Icon(Icons.add_rounded),
              label: const Text("Новый чат"),
              style: FilledButton.styleFrom(
                minimumSize: const Size(double.infinity, 54),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              itemCount: chats.length,
              itemBuilder: (context, i) {
                final chat = chats[i];
                final isSel = currentChat?.id == chat.id;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.only(bottom: 4),
                  child: ListTile(
                    selected: isSel,
                    dense: true,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    selectedTileColor: theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
                    title: Text(
                      chat.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: isSel ? FontWeight.bold : FontWeight.w500,
                        color: isSel
                            ? theme.colorScheme.onPrimaryContainer
                            : theme.colorScheme.onSurface,
                      ),
                    ),
                    onTap: () => onSelectChat(chat),
                    onLongPress: () => _showRenameDialog(context, chat),
                    trailing: isSel
                        ? Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit_outlined, size: 16),
                                onPressed: () => _showRenameDialog(context, chat),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline_rounded, size: 16),
                                onPressed: () => onDeleteChat(chat),
                              ),
                            ],
                          )
                        : null,
                  ),
                );
              },
            ),
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          _SidebarAction(
            icon: Icons.layers_outlined,
            label: "Менеджер моделей",
            onTap: () => Navigator.push<void>(
              context,
              MaterialPageRoute<void>(
                builder: (_) => ModelManager(ollama: OllamaService(settings)),
              ),
            ),
          ),
          _SidebarAction(
            icon: Icons.settings_rounded,
            label: "Настройки",
            onTap: onSettingsPressed,
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: _ThemeSelector(settings: settings),
          ),
        ],
      ),
    );
  }
}

class _SidebarAction extends StatelessWidget {
  const _SidebarAction({required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, size: 20),
      title: Text(
        label,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
      ),
      onTap: onTap,
      dense: true,
      visualDensity: VisualDensity.compact,
    );
  }
}

class _ThemeSelector extends StatelessWidget {
  const _ThemeSelector({required this.settings});
  final Settings settings;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themes = [
      {"id": "light", "icon": Icons.light_mode_rounded},
      {"id": "dark", "icon": Icons.dark_mode_rounded},
      {"id": "black", "icon": Icons.nightlight_round},
    ];
    return GlassContainer(
      borderRadius: BorderRadius.circular(16),
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: themes.map((t) {
          final isSel = settings.theme == t["id"];
          return IconButton(
            icon: Icon(t["icon"] as IconData, size: 20),
            color: isSel ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
            style: isSel ? IconButton.styleFrom(backgroundColor: theme.colorScheme.surface) : null,
            onPressed: () => settings.theme = t["id"] as String,
          );
        }).toList(),
      ),
    );
  }
}
