enum ChatMessageRole { coach, user }

enum ChatMessageType { text, generatedImage }

class ChatMessage {
  const ChatMessage({
    required this.role,
    required this.text,
    this.type = ChatMessageType.text,
    this.imageUrl,
  });

  final ChatMessageRole role;
  final ChatMessageType type;
  final String text;
  final String? imageUrl;

  bool get hasImage => imageUrl != null && imageUrl!.isNotEmpty;

  bool get isGeneratedImage =>
      type == ChatMessageType.generatedImage && hasImage;
}
