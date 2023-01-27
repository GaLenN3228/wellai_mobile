import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wellai_flutter/managers/user_store.dart';
import 'package:wellai_flutter/network/repository/global_repository.dart';
import 'package:wellai_flutter/screens/telehealth_schedule_screen/bloc/telehealth_schedule_bloc.dart';
import 'package:wellai_flutter/screens/telehealth_schedule_screen/models/result_shedule_model.dart';
import 'package:wellai_flutter/screens/telehealth_schedule_screen/telehealth_shedule_screen.dart';

MaterialPageRoute routeTelehealthScheduleScreen() {
  return MaterialPageRoute<ResultScheduleModel?>(
    builder: (context) => BlocProvider(
      create: (context) =>
          TelehealthScheduleBloc(context.read<GlobalRepository>(), context.read<UserStore>())
            ..add(InitialTelehealthScheduleEvent()),
      child: const TelehealthScheduleScreen(),
    ),
  );
}
