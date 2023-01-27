import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wellai_flutter/managers/error_handler/error_handler.dart';
import 'package:wellai_flutter/managers/user_store.dart';
import 'package:wellai_flutter/network/models/dto_models/request/dto_create_profile_request.dart';
import 'package:wellai_flutter/network/repository/global_repository.dart';
import 'package:wellai_flutter/network/repository/hive_repository.dart';

part 'edit_profile_screen_event.dart';
part 'edit_profile_screen_state.dart';

class EditProfileScreenBloc extends Bloc<ProfileScreenEvent, EditProfileScreenState> {
  final GlobalRepository _globalRepository;
  final UserStore _userStore;
  final HiveRepository _hiveRepository;

  EditProfileScreenBloc({
    required GlobalRepository globalRepository,
    required UserStore userStore,
    required HiveRepository hiveRepository,
  })  : _globalRepository = globalRepository,
        _userStore = userStore,
        _hiveRepository = hiveRepository,
        super(InitialEditProfileScreenState()) {
    on<DataChangesProfileEvent>(_buildDataChangesProfileEvent);
  }

  FutureOr<void> _buildDataChangesProfileEvent(
      DataChangesProfileEvent event, Emitter<EditProfileScreenState> emit) async {
    emit(LoadingEditProfileState(true));
    try {
      await _globalRepository.createEditProfile(
          event.profile, event.imagePath, event.isRemoveAvatar);
      final userInfo = await _globalRepository.getUserInfo();
      _userStore.upsertUser(userInfo);
      _hiveRepository.saveUserAvatar(
        userInfo.profile?.image?.name,
        userInfo.profile?.image?.blur,
      );
      emit(LoadingEditProfileState(false));
      emit(SuccessEditProfileScreenState());
    } catch (ex, stackTrace) {
      emit(LoadingEditProfileState(false));
      emit(ErrorEditProfileScreenState(ex, stackTrace));
    }
  }
}
