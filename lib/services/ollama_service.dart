import "dart:async";
import "dart:convert";
import "package:http/http.dart" as http;
import "../models/message.dart";
import "settings.dart";

class OllamaService {
  OllamaService(this.s) : _client = http.Client();
  final Settings s;
  final http.Client _client;

  Future<List<Map<String, dynamic>>> getLocalModels() async {
    try {
      final r = await _client
          .get(Uri.parse("${s.baseUrl}/api/tags"))
          .timeout(const Duration(seconds: 5));
      if (r.statusCode != 200) return [];
      final d = jsonDecode(r.body) as Map<String, dynamic>;
      return (d["models"] as List<dynamic>).cast<Map<String, dynamic>>();
    } catch (_) {
      return [];
    }
  }

  Future<bool> deleteModel(String name) async {
    try {
      final r = await _client.delete(
        Uri.parse("${s.baseUrl}/api/delete"),
        body: jsonEncode({"model": name}),
      );
      return r.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Stream<Map<String, dynamic>> pullModel(String name) async* {
    final req = http.Request("POST", Uri.parse("${s.baseUrl}/api/pull"))
      ..body = jsonEncode({"model": name, "stream": true});
    try {
      final res = await _client.send(req);
      await for (final line in res.stream.transform(utf8.decoder).transform(const LineSplitter())) {
        if (line.isEmpty) continue;
        yield jsonDecode(line) as Map<String, dynamic>;
      }
    } catch (e) {
      yield {"error": e.toString()};
    }
  }

  Stream<Message> chat(List<Message> msgs) async* {
    final req = http.Request("POST", Uri.parse("${s.baseUrl}/api/chat"))
      ..headers["Content-Type"] = "application/json"
      ..body = jsonEncode({
        "model": s.model,
        "messages": msgs.map((m) => m.toJson()).toList(),
        "stream": true,
        "options": {
          "temperature": s.temperature,
          "num_ctx": s.numCtx,
          "top_p": s.topP,
          "top_k": s.topK,
          "repeat_penalty": s.repeatPenalty,
        },
      });
    try {
      final res = await _client.send(req);
      String fullContent = "";
      String fullThinking = "";
      await for (final line in res.stream.transform(utf8.decoder).transform(const LineSplitter())) {
        if (line.trim().isEmpty) continue;
        final d = jsonDecode(line) as Map<String, dynamic>;
        if (d.containsKey("error")) throw Exception(d["error"]);
        final msg = d["message"] as Map<String, dynamic>?;
        if (msg != null) {
          final content = msg["content"] as String?;
          final thinking = msg["thinking"] as String?;
          if (thinking != null) fullThinking += thinking;
          if (content != null) fullContent += content;
          yield Message(role: "assistant", content: fullContent, thinking: fullThinking);
        }
        if (d["done"] == true) break;
      }
    } catch (e) {
      yield Message(role: "assistant", content: "Ошибка: $e");
    }
  }

  void dispose() => _client.close();
}
