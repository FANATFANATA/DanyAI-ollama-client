import "dart:convert";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_markdown/flutter_markdown.dart";
import "../models/message.dart";
import "thinking_block.dart";

class MessageBubble extends StatelessWidget {
  const MessageBubble({
    required this.isUser,
    required this.message,
    required this.onEdit,
    required this.onDelete,
    super.key,
  });
  final bool isUser;
  final Message message;
  final void Function(String) onEdit;
  final VoidCallback onDelete;

  void _showEditDialog(BuildContext context) {
    final ctrl = TextEditingController(text: message.content);
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Редактировать"),
        content: TextField(controller: ctrl, maxLines: null, autofocus: true),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Отмена")),
          ElevatedButton(
            onPressed: () {
              onEdit(ctrl.text);
              Navigator.pop(context);
            },
            child: const Text("Сохранить"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          if (!isUser && message.thinking != null && message.thinking!.isNotEmpty)
            ThinkingBlock(text: message.thinking!),
          Row(
            mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!isUser)
                CircleAvatar(
                  radius: 16,
                  backgroundColor: theme.colorScheme.primaryContainer,
                  child: Icon(Icons.auto_awesome, size: 16, color: theme.colorScheme.primary),
                ),
              if (!isUser) const SizedBox(width: 12),
              Flexible(
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isUser
                        ? theme.colorScheme.primary
                        : theme.colorScheme.surfaceContainerLow,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: Radius.circular(isUser ? 16 : 4),
                      bottomRight: Radius.circular(isUser ? 4 : 16),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (message.images != null && message.images!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: message.images!.map((img) {
                              return ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.memory(
                                  base64Decode(img),
                                  width: 160,
                                  fit: BoxFit.cover,
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      MarkdownBody(
                        data: message.content.isEmpty ? "..." : message.content,
                        selectable: true,
                        styleSheet: MarkdownStyleSheet.fromTheme(theme).copyWith(
                          p: theme.textTheme.bodyLarge?.copyWith(
                            color: isUser
                                ? theme.colorScheme.onPrimary
                                : theme.colorScheme.onSurface,
                            fontSize: 15,
                            height: 1.5,
                          ),
                          code: TextStyle(
                            backgroundColor: isUser
                                ? Colors.black.withValues(alpha: 0.2)
                                : theme.colorScheme.surfaceContainerHighest,
                            color: isUser ? Colors.white : theme.colorScheme.primary,
                            fontSize: 14,
                            fontFamily: "monospace",
                          ),
                          codeblockDecoration: BoxDecoration(
                            color: isUser
                                ? Colors.black.withValues(alpha: 0.3)
                                : theme.colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (isUser) const SizedBox(width: 12),
              if (isUser)
                CircleAvatar(
                  radius: 16,
                  backgroundColor: theme.colorScheme.secondaryContainer,
                  child: Icon(Icons.person, size: 16, color: theme.colorScheme.secondary),
                ),
            ],
          ),
          Padding(
            padding: EdgeInsets.only(left: isUser ? 0 : 44, right: isUser ? 44 : 0, top: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _BubbleAction(
                  icon: Icons.copy_rounded,
                  onTap: () => Clipboard.setData(ClipboardData(text: message.content)),
                ),
                if (isUser) ...[
                  const SizedBox(width: 8),
                  _BubbleAction(icon: Icons.edit_rounded, onTap: () => _showEditDialog(context)),
                ],
                const SizedBox(width: 8),
                _BubbleAction(icon: Icons.delete_outline_rounded, onTap: onDelete),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BubbleAction extends StatelessWidget {
  const _BubbleAction({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Icon(
          icon,
          size: 16,
          color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
        ),
      ),
    );
  }
}
