import "package:flutter/foundation.dart";
import "message.dart";

@immutable
class Chat {
  const Chat({
    required this.id,
    required this.title,
    required this.messages,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Chat.fromJson(Map<String, dynamic> json) => Chat(
    id: json["id"] as String,
    title: json["title"] as String,
    messages: (json["messages"] as List<dynamic>)
        .map((dynamic m) => Message.fromJson(m as Map<String, dynamic>))
        .toList(),
    createdAt: DateTime.parse(json["createdAt"] as String),
    updatedAt: DateTime.parse(json["updatedAt"] as String),
  );

  final String id;
  final String title;
  final List<Message> messages;
  final DateTime createdAt;
  final DateTime updatedAt;

  Chat copyWith({
    String? id,
    String? title,
    List<Message>? messages,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => Chat(
    id: id ?? this.id,
    title: title ?? this.title,
    messages: messages ?? this.messages,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );

  Map<String, dynamic> toJson() => <String, dynamic>{
    "id": id,
    "title": title,
    "messages": messages.map((Message m) => m.toJson()).toList(),
    "createdAt": createdAt.toIso8601String(),
    "updatedAt": updatedAt.toIso8601String(),
  };
}
