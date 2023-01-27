part of 'telehealth_bloc.dart';

@immutable
abstract class TelehealthState {}

class LoadingTelehealthState extends TelehealthState {}

class IncomingCallTelehealthState extends TelehealthState {
  final RTCVideoRenderer localRender;
  final String? name;

  IncomingCallTelehealthState(this.localRender, this.name);
}

class OutgoingCallTelehealthState extends TelehealthState {}

class CallProgressTelehealthState extends TelehealthState {
  final String? callerName;
  final RTCVideoRenderer remoteRender;
  final RTCVideoRenderer localRender;

  CallProgressTelehealthState({
    required this.callerName,
    required this.remoteRender,
    required this.localRender,
  });
}

class SelectPatientToCallTelehealthState extends TelehealthState {}

class EndCallTelehealthState extends TelehealthState {}

class TempConnectionChangesState extends TelehealthState {
  final bool isConnected;

  TempConnectionChangesState({required this.isConnected});
}
