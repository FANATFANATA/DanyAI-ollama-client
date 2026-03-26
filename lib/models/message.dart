import "package:flutter/foundation.dart";

@immutable
class Message {
  const Message({required this.content, required this.role, this.images, this.thinking});

  factory Message.fromJson(Map<String, dynamic> json) => Message(
    content: json["content"] as String,
    role: json["role"] as String,
    images: (json["images"] as List<dynamic>?)?.cast<String>(),
    thinking: json["thinking"] as String?,
  );

  final String content;
  final String role;
  final List<String>? images;
  final String? thinking;

  Message copyWith({String? content, List<String>? images, String? thinking}) => Message(
    content: content ?? this.content,
    role: role,
    images: images ?? this.images,
    thinking: thinking ?? this.thinking,
  );

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{"role": role, "content": content};
    if (images != null && images!.isNotEmpty) map["images"] = images;
    return map;
  }
}
