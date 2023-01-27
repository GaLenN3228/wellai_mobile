part of 'assistant_bloc.dart';

@immutable
abstract class AssistantState {}

class LoadingState extends AssistantState {}

class DataState extends AssistantState {
  final bool isSlowAnimation;
  final List<ChatMsgBase> messages;

  DataState(this.messages, {this.isSlowAnimation = false});
}

class InitialDataState extends AssistantState {}

class OpenAttachToClinicScreenState extends AssistantState {}

class NavigateToPaymentsState extends AssistantState {}

class RestartAssistantState extends AssistantState {}



