part of 'telehealth_schedule_bloc.dart';

@immutable
abstract class TelehealthScheduleState {}

class LoadingTelehealthScheduleState extends TelehealthScheduleState {}

class ErrorTelehealthScheduleState extends BaseBlocError
    implements TelehealthScheduleState {
  ErrorTelehealthScheduleState(Object e, StackTrace stackTrace)
      : super(e, stackTrace);
}

class DataTelehealthScheduleState extends TelehealthScheduleState {
  final List<ScheduleDayModel> schedulesDays;
  final int stepWorkTime;

  DataTelehealthScheduleState(this.schedulesDays, this.stepWorkTime);
}
