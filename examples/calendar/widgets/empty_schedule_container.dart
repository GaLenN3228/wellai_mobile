part of '../telehealth_shedule_screen.dart';


@immutable
class _EmptyScheduleContianer extends StatelessWidget {
  const _EmptyScheduleContianer({
    Key? key,
  })  : super(key: key);

  @override
  Widget build(BuildContext context) => Expanded(
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        children: [
          const SizedBox(
            height: 50,
          ),
          Assets.iconsPng.telehealthScheduleEmpty.image(),
          const SizedBox(
            height: 28,
          ),
          Text(
            S.of(context).the_list_of_doctors_is_not_ready_yet,
            style: ProjectTextStyles.ui_14Regular.copyWith(
              color: ColorPalette.darkGray,
            ),
            textAlign: TextAlign.center,
          )
        ],
      ),
    ),
  );
}