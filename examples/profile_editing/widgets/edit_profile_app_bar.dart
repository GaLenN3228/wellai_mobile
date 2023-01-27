part of '../edit_profile_screen.dart';

@immutable
class _EditProfileAppBar extends StatelessWidget {
  const _EditProfileAppBar({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final vm = context.read<EditProfileScreenViewModel>();
    return SliverAppBar(
      elevation: 0,
      pinned: false,
      snap: false,
      floating: false,
      actions: [
        if (!context.read<EditProfileScreenViewModel>().isEditable)
          Padding(
            padding: const EdgeInsets.only(right: 16.0, top: 30.0),
            child: GestureDetector(
              onTap: () async {
                await Navigator.of(context, rootNavigator: true)
                    .push(routeEditProfileScreen(isEditable: true));
              },
              child: Assets.iconsSvg.icEditPencil.svg(),
            ),
          ),
      ],
      leading: context.read<EditProfileScreenViewModel>().isEditable
          ? IconButton(
              icon: Assets.iconsSvg.icArrowLeft.svg(),
              onPressed: () {
                Navigator.pop(context);
              },
            )
          : null,
      expandedHeight: 300,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          margin: const EdgeInsets.only(bottom: 28),
          decoration: BoxDecoration(
            color: ColorPalette.white,
            borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(56.0),
                bottomRight: Radius.circular(56.0)),
            boxShadow: [
              BoxShadow(
                color: ColorPalette.gray.withOpacity(0.3),
                spreadRadius: 0.2,
                blurRadius: 10,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Column(
            children: [
              const SizedBox(height: kToolbarHeight + 40),
              context.watch<EditProfileScreenViewModel>().avatar != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(100),
                      child: Image.file(
                        vm.avatar!,
                        width: 120,
                        height: 120,
                        fit: BoxFit.cover,
                      ))
                  : MainAvatar(
                      radius: 60,
                      networkAvatar: vm.getAvatar != "" ? vm.getAvatar : null,
                      blurHash: vm.getBlurHash,
                    ),
              const SizedBox(height: 5),
              if (context.read<EditProfileScreenViewModel>().isEditable)
                SizedBox(
                  width: 120,
                  child: PrimaryTextButton(
                    title: vm.getAvatar != ""
                        ? S.of(context).editPhoto
                        : S.of(context).set_photo,
                    onPressed: () {
                      _buildCupertinoModal(
                        context: context,
                        actions: <CupertinoActionSheetAction>[
                          CupertinoActionSheetAction(
                            child: Text(
                              S.of(context).take_photo,
                            ),
                            onPressed: () async {
                              final XFile? avatar =
                                  await ImagePicker().pickImage(
                                source: ImageSource.camera,
                              );
                              if (avatar != null) {
                                vm.setAvatar = File(avatar.path);
                              }
                              Navigator.of(context).pop();
                            },
                          ),
                          if (vm.getAvatar.isNotEmpty)
                            CupertinoActionSheetAction(
                              isDestructiveAction: true,
                              onPressed: () async {
                                vm.removeAvatar();
                                Navigator.of(context).pop();
                              },
                              child: Text(
                                S.of(context).removeCurrentPhoto,
                              ),
                            ),
                          CupertinoActionSheetAction(
                            child: Text(
                              S.of(context).choose_from_library,
                            ),
                            onPressed: () async {
                              final XFile? avatar = await ImagePicker()
                                  .pickImage(source: ImageSource.gallery);
                              if (avatar != null) {
                                vm.setAvatar = File(avatar.path);
                              }
                              Navigator.of(context).pop();
                            },
                          ),
                        ],
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
