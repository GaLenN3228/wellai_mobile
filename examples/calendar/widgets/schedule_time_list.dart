part of '../telehealth_shedule_screen.dart';

class _ScheduleTimesList extends StatelessWidget {
  final ScheduleDayModel day;

  const _ScheduleTimesList({Key? key, required this.day})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(top: 24),
              child: Row(
                children: [
                  SizedBox(
                    width: 93.0,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 16, right: 23),
                      child: Text(
                        S.of(context).time,
                        style: ProjectTextStyles.ui_14Medium
                            .copyWith(color: ColorPalette.lightGray),
                      ),
                    ),
                  ),
                  Container(
                    height: 20,
                    width: 1,
                    color: ColorPalette.borderLightGray,
                  ),
                  const SizedBox(width: 20),
                  Text(
                    S.of(context).free_doctors,
                    style: ProjectTextStyles.ui_14Medium
                        .copyWith(color: ColorPalette.lightGray),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Row(
              children: [
                const SizedBox(width: 93),
                Flexible(
                  child: Container(
                    height: 30,
                    width: 1,
                    color: ColorPalette.borderLightGray,
                  ),
                ),
              ],
            ),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
                    (context, index) =>
                    _DoctorsAtOneTimeItem(time: day.times[index]),
                childCount: day.times.length),
          )
        ],
      ),
    );
  }
}