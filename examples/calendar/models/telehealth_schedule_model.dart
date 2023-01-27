class ScheduleDayModel {
  final DateTime date;
  final List<ScheduleTimeModel> times;

  ScheduleDayModel(this.date, this.times);
}

class ScheduleTimeModel {
  final DateTime time;
  final DateTime endTime;
  final List<DoctorModel> doctors;

  ScheduleTimeModel(this.time, this.doctors, this.endTime);
}

class DoctorModel {
  final String? avatar;
  final String? name;
  final int id;
  final DateTime bookingDate;
  final String? blurHash;

  DoctorModel(this.avatar, this.name, this.id, this.bookingDate, this.blurHash);
}
