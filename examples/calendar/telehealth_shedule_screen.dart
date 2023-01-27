import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wellai_flutter/generated/assets.gen.dart';
import 'package:wellai_flutter/generated/l10n.dart';
import 'package:wellai_flutter/managers/error_handler/error_handler.dart';
import 'package:wellai_flutter/screens/telehealth_schedule_screen/models/result_shedule_model.dart';
import 'package:wellai_flutter/styles/color_palette.dart';
import 'package:wellai_flutter/styles/formatters.dart';
import 'package:wellai_flutter/styles/text_styles.dart';
import 'package:wellai_flutter/widgets/loading_indicator/loading_indicator.dart';
import 'package:wellai_flutter/widgets/loading_layer/loading_layer.dart';
import 'package:wellai_flutter/widgets/main_avatar/main_avatar.dart';
import 'package:wellai_flutter/widgets/main_button/main_button.dart';
import 'package:wellai_flutter/widgets/snackbar/snackbar.dart';

import 'bloc/telehealth_schedule_bloc.dart';
import 'models/telehealth_schedule_model.dart';

part 'widgets/telehealth_header.dart';
part 'widgets/day_list_item.dart';
part 'widgets/schedule_time_list.dart';
part 'widgets/days_list.dart';
part 'widgets/doctors_in_one_time_item.dart';
part 'widgets/doctor_item.dart';
part 'widgets/empty_schedule_container.dart';

///Screen for select date and time for telehealth
class TelehealthScheduleScreen extends StatelessWidget {
  const TelehealthScheduleScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LoadingLayerProvider(
      child: BlocConsumer<TelehealthScheduleBloc, TelehealthScheduleState>(
        listener: (context, state) {
          if (state is ErrorTelehealthScheduleState) {
            showCustomSnackbar(context, context.read<ErrorHandler>().handleError(state));
          }
        },
        builder: (context, state) {
          if (state is LoadingTelehealthScheduleState) {
            return const LoadingIndicator();
          }
          if (state is DataTelehealthScheduleState) {
            return _DataStateBody(state: state);
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}

class _DataStateBody extends StatefulWidget {
  final DataTelehealthScheduleState state;

  const _DataStateBody({Key? key, required this.state}) : super(key: key);

  @override
  _DataStateBodyState createState() => _DataStateBodyState();
}

class _DataStateBodyState extends State<_DataStateBody> {
  late ScheduleDayModel selectedDayModel;

  @override
  void initState() {
    selectedDayModel = widget.state.schedulesDays.first;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          _TelehealthHeader(
            date: DateTime.now(),
          ),
          const SizedBox(height: 8),
          _DaysList(
            days: widget.state.schedulesDays,
            onChangeDay: (day) {
              setState(
                () {
                  selectedDayModel = day;
                },
              );
            },
          ),
          const SizedBox(height: 12),
          const Divider(
            color: ColorPalette.lightGray,
          ),
          selectedDayModel.times.isNotEmpty
              ? _ScheduleTimesList(day: selectedDayModel)
              : const _EmptyScheduleContianer()
        ],
      ),
    );
  }
}
