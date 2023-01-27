part of '../edit_profile_screen.dart';

@immutable
class _EditProfileBlocListener extends StatelessWidget {
  final Widget child;

  const _EditProfileBlocListener({
    Key? key,
    required this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocListener<EditProfileScreenBloc, EditProfileScreenState>(
      listener: (context, state) {
        if (state is LoadingEditProfileState) {
          if (state.isLoading) {
            LoadingLayer.show(context);
          } else {
            LoadingLayer.hide();
          }
        }
        if (state is ErrorEditProfileScreenState) {
          showCustomSnackbar(
            context,
            context.read<ErrorHandler>().handleError(state),
          );
        }
        if (state is SuccessEditProfileScreenState) {
          Navigator.pop(context, true);
          showCustomSnackbar(
            context,
            S.of(context).success_edit_profile,
            color: ColorPalette.darkGreen,
          );
        }
      },
      child: child,
    );
  }
}
