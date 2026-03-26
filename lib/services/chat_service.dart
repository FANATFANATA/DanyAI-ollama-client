import "dart:convert";
import "package:flutter/foundation.dart";
import "package:shared_preferences/shared_preferences.dart";
import "../models/chat.dart";
import "../models/message.dart";

class ChatService extends ChangeNotifier {
  ChatService() : _chats = <Chat>[];
  final List<Chat> _chats;
  Chat? _currentChat;
  List<Chat> get chats => List<Chat>.unmodifiable(_chats);
  Chat? get currentChat => _currentChat;

  Future<void> load() async {
    try {
      final p = await SharedPreferences.getInstance();
      final json = p.getString("chats");
      if (json != null) {
        final d = jsonDecode(json) as List<dynamic>;
        _chats
          ..clear()
          ..addAll(d.map((dynamic e) => Chat.fromJson(e as Map<String, dynamic>)).toList())
          ..sort((Chat a, Chat b) => b.updatedAt.compareTo(a.updatedAt));
      }
      final id = p.getString("cur_id");
      if (id != null && _chats.isNotEmpty) {
        _currentChat = _chats.firstWhere((Chat c) => c.id == id, orElse: () => _chats.first);
      }
      notifyListeners();
    } catch (e) {
      debugPrint("Load error: $e");
    }
  }

  Future<void> save() async {
    try {
      final p = await SharedPreferences.getInstance();
      await p.setString("chats", jsonEncode(_chats.map((Chat e) => e.toJson()).toList()));
      if (_currentChat != null) await p.setString("cur_id", _currentChat!.id);
    } catch (e) {
      debugPrint("Save error: $e");
    }
  }

  Future<void> createChat() async {
    final c = Chat(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: "Новый чат",
      messages: const <Message>[],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    _chats.insert(0, c);
    _currentChat = c;
    notifyListeners();
    await save();
  }

  Future<void> selectChat(Chat c) async {
    _currentChat = c;
    notifyListeners();
    await save();
  }

  Future<void> deleteChat(Chat c) async {
    _chats.removeWhere((Chat i) => i.id == c.id);
    if (_currentChat?.id == c.id) _currentChat = _chats.isNotEmpty ? _chats.first : null;
    notifyListeners();
    await save();
  }

  Future<void> renameChat(Chat c, String t) async {
    final i = _chats.indexWhere((Chat x) => x.id == c.id);
    if (i != -1) {
      _chats[i] = c.copyWith(title: t, updatedAt: DateTime.now());
      if (_currentChat?.id == c.id) _currentChat = _chats[i];
      notifyListeners();
      await save();
    }
  }

  Future<void> addMessage(Chat c, Message m) async {
    final i = _chats.indexWhere((Chat x) => x.id == c.id);
    if (i != -1) {
      final msgs = List<Message>.from(_chats[i].messages)..add(m);
      String t = _chats[i].title;
      if (_chats[i].messages.isEmpty && m.role == "user") {
        t = m.content.length > 40 ? "${m.content.substring(0, 40)}..." : m.content;
      }
      _chats[i] = _chats[i].copyWith(messages: msgs, title: t, updatedAt: DateTime.now());
      if (_currentChat?.id == c.id) _currentChat = _chats[i];
      _chats.sort((Chat a, Chat b) => b.updatedAt.compareTo(a.updatedAt));
      notifyListeners();
    }
  }

  Future<void> updateLastMessage(Chat c, Message m) async {
    final i = _chats.indexWhere((Chat x) => x.id == c.id);
    if (i != -1 && _chats[i].messages.isNotEmpty) {
      final msgs = List<Message>.from(_chats[i].messages);
      msgs[msgs.length - 1] = m;
      _chats[i] = _chats[i].copyWith(messages: msgs, updatedAt: DateTime.now());
      if (_currentChat?.id == c.id) _currentChat = _chats[i];
      notifyListeners();
    }
  }

  Future<void> editMessage(Chat c, int index, String content) async {
    final i = _chats.indexWhere((Chat x) => x.id == c.id);
    if (i != -1 && index < _chats[i].messages.length) {
      final msgs = List<Message>.from(_chats[i].messages);
      msgs[index] = msgs[index].copyWith(content: content);
      _chats[i] = _chats[i].copyWith(messages: msgs, updatedAt: DateTime.now());
      if (_currentChat?.id == c.id) _currentChat = _chats[i];
      notifyListeners();
      await save();
    }
  }

  Future<void> deleteMessage(Chat c, int index) async {
    final i = _chats.indexWhere((Chat x) => x.id == c.id);
    if (i != -1 && index < _chats[i].messages.length) {
      final msgs = List<Message>.from(_chats[i].messages)..removeAt(index);
      _chats[i] = _chats[i].copyWith(messages: msgs, updatedAt: DateTime.now());
      if (_currentChat?.id == c.id) _currentChat = _chats[i];
      notifyListeners();
      await save();
    }
  }

  Future<void> clearCurrentChat() async {
    if (_currentChat != null) {
      final i = _chats.indexWhere((Chat x) => x.id == _currentChat!.id);
      if (i != -1) {
        _chats[i] = _currentChat!.copyWith(messages: const <Message>[], updatedAt: DateTime.now());
        _currentChat = _chats[i];
        notifyListeners();
        await save();
      }
    }
  }
}
