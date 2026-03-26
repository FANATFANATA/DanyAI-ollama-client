import "package:flutter/material.dart";

class MessageInput extends StatelessWidget {
  const MessageInput({
    required this.controller,
    required this.isLoading,
    required this.hintText,
    required this.onSend,
    required this.onStop,
    super.key,
  });
  final TextEditingController controller;
  final bool isLoading;
  final String hintText;
  final VoidCallback onSend;
  final VoidCallback onStop;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [theme.colorScheme.surface.withValues(alpha: 0), theme.colorScheme.surface],
        ),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: controller,
                maxLines: 10,
                minLines: 1,
                style: const TextStyle(fontSize: 15),
                decoration: InputDecoration(
                  hintText: hintText,
                  hintStyle: TextStyle(
                    color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 4, right: 4),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: isLoading
                    ? IconButton.filled(
                        key: const ValueKey("stop"),
                        onPressed: onStop,
                        icon: const Icon(Icons.stop_rounded),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.redAccent,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(44, 44),
                        ),
                      )
                    : IconButton.filled(
                        key: const ValueKey("send"),
                        onPressed: onSend,
                        icon: const Icon(Icons.arrow_upward_rounded),
                        style: IconButton.styleFrom(
                          backgroundColor: theme.colorScheme.primary,
                          foregroundColor: theme.colorScheme.onPrimary,
                          minimumSize: const Size(44, 44),
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
