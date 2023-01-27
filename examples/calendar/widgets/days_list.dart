part of '../telehealth_shedule_screen.dart';

class _DaysList extends StatefulWidget {
  final List<ScheduleDayModel> days;
  final void Function(ScheduleDayModel day)? onChangeDay;

  const _DaysList({
    Key? key,
    required this.days,
    required this.onChangeDay,
  }) : super(key: key);

  @override
  State<_DaysList> createState() => _DaysListState();
}

class _DaysListState extends State<_DaysList> {
  int selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 60,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: widget.days.length,
        itemBuilder: (context, index) {
          return _DayListItem(
            day: widget.days[index],
            isSelected: index == selectedIndex,
            onSelectDay: () {
              setState(() {
                selectedIndex = index;
              });
              widget.onChangeDay?.call(widget.days[selectedIndex]);
            },
          );
        },
      ),
    );
  }
}