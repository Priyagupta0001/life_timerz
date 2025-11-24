class TimerModel {
  String? id;
  final String uid;
  final String title;
  final String category;
  final DateTime dateTime;
  final bool isCountDown;

  TimerModel({
    this.id,
    required this.uid,
    required this.title,
    required this.category,
    required this.dateTime,
    required this.isCountDown,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'title': title,
      'category': category,
      'datetime': dateTime,
      'isCountDown': isCountDown,
      'createdAt': DateTime.now(),
    };
  }
}
