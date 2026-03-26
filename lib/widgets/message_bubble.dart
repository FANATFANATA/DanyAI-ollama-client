import "dart:convert";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "../models/message.dart";

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
        content: TextField(controller: ctrl, maxLines: null),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Отмена")),
          TextButton(
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
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isUser ? theme.colorScheme.primary : theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16).copyWith(
            bottomRight: isUser ? const Radius.circular(2) : null,
            bottomLeft: !isUser ? const Radius.circular(2) : null,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (message.images != null && message.images!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: message.images!
                      .map(
                        (img) => ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.memory(
                            base64Decode(img),
                            width: 100,
                            height: 100,
                            fit: BoxFit.cover,
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
            if (!isUser && message.thinking != null && message.thinking!.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainer,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: theme.dividerColor.withValues(alpha: 0.1)),
                ),
                child: Text(
                  message.thinking!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            SelectionArea(
              child: Text(
                message.content.isEmpty ? "..." : message.content,
                style: TextStyle(
                  color: isUser ? theme.colorScheme.onPrimary : theme.colorScheme.onSurface,
                  fontSize: 15,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _ActionButton(
                  icon: Icons.copy,
                  onTap: () => Clipboard.setData(ClipboardData(text: message.content)),
                ),
                if (isUser) ...[
                  const SizedBox(width: 8),
                  _ActionButton(icon: Icons.edit, onTap: () => _showEditDialog(context)),
                ],
                const SizedBox(width: 8),
                _ActionButton(icon: Icons.delete, onTap: onDelete),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.all(2),
        child: Icon(
          icon,
          size: 14,
          color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
        ),
      ),
    );
  }
}
