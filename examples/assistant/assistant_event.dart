part of 'assistant_bloc.dart';

@immutable
abstract class AssistantEvent {}

class SuccessFillProfileAssistantEvent extends AssistantEvent {}

class StartOverAssisEvent extends AssistantEvent {}

class RetrySessionEvent extends AssistantEvent {}

class StopSessionAssisEvent extends AssistantEvent {}

class SendMessageEvent extends AssistantEvent {
  final String message;

  SendMessageEvent(this.message);
}
