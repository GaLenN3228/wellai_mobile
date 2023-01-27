part of '../telehealth_shedule_screen.dart';

class _DayListItem extends StatelessWidget {
  final void Function() onSelectDay;
  final bool isSelected;
  final ScheduleDayModel day;

  const _DayListItem(
      {Key? key,
        required this.isSelected,
        required this.onSelectDay,
        required this.day})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onSelectDay,
      child: Container(
        height: 60,
        width: 45,
        margin: const EdgeInsets.only(right: 0),
        decoration: BoxDecoration(
          color: isSelected ? ColorPalette.main : ColorPalette.white,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                Formatters.scheduleDayOfWeek(day.date).substring(0, 1),
                style: ProjectTextStyles.ui_14Medium.copyWith(
                  color:
                  isSelected ? ColorPalette.white : ColorPalette.lightGray,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                day.date.day.toString(),
                style: ProjectTextStyles.ui_16Semi.copyWith(
                    color:
                    isSelected ? ColorPalette.white : ColorPalette.black),
              )
            ],
          ),
        ),
      ),
    );
  }
}