part of '../telehealth_shedule_screen.dart';

class _TelehealthHeader extends StatelessWidget {
  final DateTime date;

  const _TelehealthHeader({Key? key, required this.date}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SizedBox(
        height: 72,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            IconButton(
              icon: Assets.iconsSvg.icArrowLeft.svg(),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
            const SizedBox(width: 22),
            Text(
              date.day.toString(),
              style: ProjectTextStyles.ui_40Semi,
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  Formatters.scheduleDayOfWeek(date),
                  style: ProjectTextStyles.ui_14Medium
                      .copyWith(color: ColorPalette.lightGray),
                ),
                const SizedBox(height: 4),
                Text(
                  Formatters.scheduleMonthYear(date),
                  style: ProjectTextStyles.ui_14Medium
                      .copyWith(color: ColorPalette.lightGray),
                ),
              ],
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: ColorPalette.secondarySuperExtraLight,
              ),
              child: Text(
                S.of(context).today,
                style: ProjectTextStyles.ui_16Semi
                    .copyWith(color: ColorPalette.secondaryMain),
              ),
            ),
            const SizedBox(width: 16),
          ],
        ),
      ),
    );
  }
}