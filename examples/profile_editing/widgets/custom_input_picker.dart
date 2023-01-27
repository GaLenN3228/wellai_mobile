part of '../edit_profile_screen.dart';

class _CustomInputPicker extends StatelessWidget {
  final void Function() onTap;
  final String value;

  const _CustomInputPicker({
    Key? key,
    required this.onTap,
    required this.value,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            S.of(context).biologicalSex,
            style: ProjectTextStyles.ui_14Semi.copyWith(
              color: ColorPalette.lightGray,
            ),
          ),
          Container(
            padding: const EdgeInsets.only(bottom: 12, top: 8),
            margin: const EdgeInsets.only(bottom: 12),
            width: double.infinity,
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: ColorPalette.borderLightGray,
                ),
              ),
            ),
            child: Text(value),
          ),
        ],
      ),
    );
  }
}
