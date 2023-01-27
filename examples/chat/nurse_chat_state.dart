part of 'nurse_chat_bloc.dart';

@immutable
abstract class NurseChatState {}

class LoadingNurseChatState extends NurseChatState {}

class DataNurseChatState extends NurseChatState {
  final List<ChatMsgBase> messages;
  final int sessionId;

  DataNurseChatState({
    required this.messages,
    required this.sessionId,
  });

  DataNurseChatState copyWith({
    List<ChatMsgBase>? messages,
    int? sessionId,
  }) {
    return DataNurseChatState(
      messages: messages ?? this.messages,
      sessionId: sessionId ?? this.sessionId,
    );
  }
}

class SuccessDialogState extends NurseChatState {}

class ErrorNurseChatState extends BaseBlocError implements NurseChatState {
  ErrorNurseChatState(Object e, StackTrace stackTrace) : super(e, stackTrace);
}
