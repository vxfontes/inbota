class EventFeedItem {
  const EventFeedItem({
    required this.id,
    required this.type,
    required this.title,
    required this.date,
    this.secondary,
    this.done = false,
    this.allDay = false,
  });

  final String id;
  final EventFeedItemType type;
  final String title;
  final DateTime date;
  final String? secondary;
  final bool done;
  final bool allDay;

  bool get hasExplicitTime {
    if (allDay) return false;
    return date.hour != 0 || date.minute != 0;
  }
}

enum EventFeedItemType { event, todo, reminder }