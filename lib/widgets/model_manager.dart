import "package:flutter/material.dart";
import "../services/ollama_service.dart";

class ModelManager extends StatefulWidget {
  const ModelManager({required this.ollama, super.key});
  final OllamaService ollama;
  @override
  State<ModelManager> createState() => _ModelManagerState();
}

class _ModelManagerState extends State<ModelManager> {
  List<Map<String, dynamic>> _models = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    setState(() => _loading = true);
    final models = await widget.ollama.getLocalModels();
    if (mounted) {
      setState(() {
        _models = models;
        _loading = false;
      });
    }
  }

  void _pullModel() {
    final ctrl = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Скачать модель"),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(hintText: "llama3.2"),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Отмена")),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _startPull(ctrl.text);
            },
            child: const Text("Скачать"),
          ),
        ],
      ),
    );
  }

  void _startPull(String name) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => StreamBuilder<Map<String, dynamic>>(
        stream: widget.ollama.pullModel(name),
        builder: (context, snap) {
          final data = snap.data;
          final status = data?["status"] as String? ?? "Инициализация...";
          final total = data?["total"] as int?;
          final completed = data?["completed"] as int?;
          double? progress;
          if (total != null && completed != null && total > 0) {
            progress = completed / total;
          }

          if (data?["status"] == "success") {
            Future.delayed(Duration.zero, () {
              if (context.mounted) {
                Navigator.pop(context);
                _refresh();
              }
            });
          }

          return AlertDialog(
            title: Text("Загрузка $name"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(status),
                const SizedBox(height: 16),
                LinearProgressIndicator(value: progress),
              ],
            ),
            actions: data?["error"] != null
                ? [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("Закрыть"),
                    ),
                  ]
                : [],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Управление моделями"),
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _refresh)],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _models.length,
              itemBuilder: (context, i) {
                final m = _models[i];
                final name = m["name"] as String? ?? "Unknown";
                final size = m["size"] as int? ?? 0;
                return ListTile(
                  title: Text(name),
                  subtitle: Text("${(size / 1e9).toStringAsFixed(2)} GB"),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () async {
                      if (await widget.ollama.deleteModel(name)) {
                        _refresh();
                      }
                    },
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _pullModel,
        child: const Icon(Icons.download),
      ),
    );
  }
}
