part of 'edit_profile_screen_bloc.dart';

abstract class ProfileScreenEvent {}

class DataChangesProfileEvent extends ProfileScreenEvent {
  final DTOCreateProfileRequest profile;
  final String? imagePath;
  final bool isRemoveAvatar;

  DataChangesProfileEvent(this.isRemoveAvatar,
      {required this.profile, this.imagePath});
}
