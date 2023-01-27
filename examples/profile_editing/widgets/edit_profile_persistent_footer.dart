part of '../edit_profile_screen.dart';

@immutable
class _PersistentFooter extends StatelessWidget {
  const _PersistentFooter({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final vm = context.read<EditProfileScreenViewModel>();
    return !(KeyboardNotifierProvider.of(context)?.isKeyboardOpened ?? false)
        ? PersistentFooterWrapper(
            child: MainButton(
              title: S.of(context).save,
              padding: const EdgeInsets.all(16.0),
              onTap: () {
                if (vm.formFieldKey.currentState!.validate()) {
                  context.read<EditProfileScreenBloc>().add(
                        DataChangesProfileEvent(
                          vm.isRemoveAvatar,
                          profile: vm.buildRequest(),
                          imagePath: vm.avatar?.path,
                        ),
                      );
                }
              },
            ),
          )
        : const SizedBox.shrink();
  }
}
