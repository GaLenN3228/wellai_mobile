part of '../telehealth_shedule_screen.dart';

@immutable
class _DoctorItem extends StatelessWidget {
  final ScheduleTimeModel time;
  final int index;

  const _DoctorItem({
    Key? key,
    required this.time,
    required this.index,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final doctor = time.doctors[index];
    return Container(
      height: 98,
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: ColorPalette.backgroundLightGray,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              MainAvatar(
                radius: 14,
                networkAvatar: doctor.avatar,
                blurHash: doctor.blurHash,
              ),
              const SizedBox(width: 8),
              Text(
                doctor.name ?? S.of(context).no_data,
                style: ProjectTextStyles.ui_16Medium,
              ),
            ],
          ),
          const SizedBox(height: 10),
          MainButton(
            buttonHeight: 36,
            title: S.of(context).choose_this_doctor,
            onTap: () {
              Navigator.pop(context, ResultScheduleModel(doctor, time.time));
            },
          ),
        ],
      ),
    );
  }
}
