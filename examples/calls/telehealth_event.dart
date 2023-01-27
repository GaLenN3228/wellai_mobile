part of 'telehealth_bloc.dart';

@immutable
abstract class TelehealthEvent {}

class InitialTelehealthEvent extends TelehealthEvent {}

class ChangeCallStateTelehealthEvent extends TelehealthEvent {
  final CallModel callModel;

  ChangeCallStateTelehealthEvent(this.callModel);
}

class CallToPatientTelehealthEvent extends TelehealthEvent {
  final int id;

  CallToPatientTelehealthEvent(this.id);
}

class CallActionEvent extends TelehealthEvent {
  final CallActions action;

  CallActionEvent(this.action);
}
