import 'package:bloc/bloc.dart';
import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:wellai_flutter/managers/error_handler/error_handler.dart';
import 'package:wellai_flutter/network/models/dto_models/request/dto_doc_schedule_request.dart';
import 'package:wellai_flutter/network/models/dto_models/response/dto_doc_schedule_response.dart';
import 'package:wellai_flutter/network/repository/global_repository.dart';
import 'package:wellai_flutter/screens/telehealth_schedule_screen/models/telehealth_schedule_model.dart';

import '../../../managers/user_store.dart';

part 'telehealth_schedule_event.dart';
part 'telehealth_schedule_state.dart';

class TelehealthScheduleBloc
    extends Bloc<TelehealthScheduleEvent, TelehealthScheduleState> {
  final GlobalRepository _repository;
  late final UserStore _userStore;

  static const int daysForSchedule = 14;

  TelehealthScheduleBloc(this._repository, this._userStore)
      : super(LoadingTelehealthScheduleState()) {
    on<InitialTelehealthScheduleEvent>(_onInitialTelehealthScheduleEvent);
  }

  _onInitialTelehealthScheduleEvent(InitialTelehealthScheduleEvent event,
      Emitter<TelehealthScheduleState> emit) async {
    try {
      final List<ScheduleDayModel> scheduleTime = [];

      final response = await _repository.getDocSchedule(
          DtoDocScheduleTelehealthRequest(
            start: tz.TZDateTime.now(_userStore.getCurrentTimeZone()),
            end: tz.TZDateTime.now(_userStore.getCurrentTimeZone()).add(
              const Duration(days: daysForSchedule),
            ),
          ),
      );

      scheduleTime.addAll(List.generate(daysForSchedule, (index) {
        final nowDate = DateTime.now();
        return ScheduleDayModel(
            DateTime(nowDate.year, nowDate.month, nowDate.day)
                .add(Duration(days: index)),
            []);
      }));

      final localizedWorkTime = <Worktime>[];

      for (var workTime in response.worktime) {
        final localizedTime = tz.TZDateTime(
          _userStore.getCurrentTimeZone(),
          workTime.work.date.year,
          workTime.work.date.month,
          workTime.work.date.day,
          workTime.time.hour,
          workTime.time.minute,
        ).toLocal();

        final localizedWork = workTime.work.copyWith(date: DateTime(localizedTime.year, localizedTime.month, localizedTime.day));
        localizedWorkTime.add(workTime.copyWith(time: localizedTime, work: localizedWork));
      }

      final groupedByDate = localizedWorkTime.groupListsBy(
            (element) => element.work.date,
      );
      groupedByDate.forEach((key, value) {
        scheduleTime.removeWhere((element) {
          return element.date.isAtSameMomentAs(key);
        });
        final groupedByTime = value.groupListsBy(
                (element) => element.time);
        final List<ScheduleTimeModel> times = [];
        groupedByTime.forEach((key, value) {
          times.add(ScheduleTimeModel(
              key,
              value
                  .map((e) => DoctorModel(
                      e.work.user.profile?.image?.name,
                      e.work.user.profile?.getFullName,
                      e.id,
                      e.work.date,
                      e.work.user.profile?.image?.blur))
                  .toList(),
              key.add(Duration(minutes: value.first.work.stepWorkTime))));
        });
        times.sort((a, b) => a.time.compareTo(b.time));
        scheduleTime.add(ScheduleDayModel(key, times));
      });
      scheduleTime.sort((a, b) => a.date.compareTo(b.date));
      emit(DataTelehealthScheduleState(
          scheduleTime, response.worktime.firstOrNull?.work.stepWorkTime ?? 0));
    } catch (e, stackTrace) {
      if (kDebugMode) {
        rethrow;
      }
      emit(ErrorTelehealthScheduleState(e, stackTrace));
    }
  }

// DateTime generateCustomDate(int index) {
//   return DateTime.now().add(Duration(days: index));
// }
//
// List<ScheduleTimeModel> generateCustomTime(List<DoctorModel> doctors) {
//   return [
//     ScheduleTimeModel(
//         DateTime.now().add(Duration(hours: Random().nextInt(8))), doctors),
//     ScheduleTimeModel(
//         DateTime.now().add(Duration(hours: Random().nextInt(8))), doctors),
//     ScheduleTimeModel(
//         DateTime.now().add(Duration(hours: Random().nextInt(8))), doctors),
//   ];
// }
}
