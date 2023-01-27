part of 'nurse_chat_bloc.dart';

@immutable
abstract class NurseChatEvent {}

class SendMessageEvent extends NurseChatEvent {
  final String message;
  final List<String>? images;
  final ChatMessageType type;
  final bool stopChat;

  SendMessageEvent(
    this.message, {
    this.type = ChatMessageType.common,
    this.stopChat = false,
    this.images,
  });
}

class GetMessageEvent extends NurseChatEvent {
  final WsChatMessageResponse response;

  GetMessageEvent(this.response);
}

class InitialNurseChatEvent extends NurseChatEvent {
  final int? chatId;
  final int? userId;
  final int? sessionId;

  InitialNurseChatEvent({
    this.chatId,
    this.userId,
    this.sessionId,
  });
}

class ReconnectNurseChatEvent extends NurseChatEvent {}
