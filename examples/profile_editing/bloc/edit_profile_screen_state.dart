part of 'edit_profile_screen_bloc.dart';

abstract class EditProfileScreenState {}

class InitialEditProfileScreenState extends EditProfileScreenState {}

class LoadingEditProfileState extends EditProfileScreenState {
  final bool isLoading;

  LoadingEditProfileState(this.isLoading);
}

class SuccessEditProfileScreenState extends EditProfileScreenState {}

class ErrorEditProfileScreenState extends BaseBlocError
    implements EditProfileScreenState {
  ErrorEditProfileScreenState(Object e, StackTrace stackTrace)
      : super(e, stackTrace);
}

// class InitialEditProfileScreenState extends ProfileScreenState {}
