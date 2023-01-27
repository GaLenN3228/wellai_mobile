part of '../telehealth_shedule_screen.dart';

class _DoctorsAtOneTimeItem extends StatelessWidget {
  final ScheduleTimeModel time;

  const _DoctorsAtOneTimeItem({Key? key, required this.time}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 60,
            child: Column(
              children: [
                Text(
                  Formatters.mainTime(time.time),
                  style: ProjectTextStyles.ui_14Semi,
                ),
                const SizedBox(height: 4),
                Text(
                  Formatters.mainTime(time.endTime),
                  style: ProjectTextStyles.ui_14Semi
                      .copyWith(color: ColorPalette.lightGray),
                ),
              ],
            ),
          ),
          Container(
            margin: const EdgeInsets.only(right: 16, left: 17),
            height: (time.doctors.length * 98) + 20,
            width: 1,
            color: ColorPalette.borderLightGray,
          ),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(
                time.doctors.length,
                (index) => _DoctorItem(time: time, index: index),
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
