class EventFeedItem {
  const EventFeedItem({
    required this.id,
    required this.type,
    required this.title,
    required this.date,
    this.endDate,
    this.secondary,
    this.flagLabel,
    this.subflagLabel,
    this.flagColor,
    this.subflagColor,
    this.done = false,
    this.allDay = false,
  });

  final String id;
  final EventFeedItemType type;
  final String title;
  final DateTime date;
  final DateTime? endDate;
  final String? secondary;
  final String? flagLabel;
  final String? subflagLabel;
  final String? flagColor;
  final String? subflagColor;
  final bool done;
  final bool allDay;

  bool get hasExplicitTime {
    if (allDay) return false;
    return date.hour != 0 || date.minute != 0;
  }

  bool get hasExplicitEndTime {
    if (allDay) return false;
    if (endDate == null) return false;
    return endDate!.hour != 0 || endDate!.minute != 0;
  }
}

enum EventFeedItemType { event, todo, reminder }
