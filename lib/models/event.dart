class Event {
  final String id;
  final String title;
  final String description;
  final DateTime date;

  Event({
    required this.id,
    required this.title,
    required this.description,
    required this.date,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'title': title,
    'description': description,
    'date': date.millisecondsSinceEpoch,
  };

  factory Event.fromMap(Map<String, dynamic> map) => Event(
    id: map['id'],
    title: map['title'],
    description: map['description'],
    date: DateTime.fromMillisecondsSinceEpoch(map['date']),
  );
}
