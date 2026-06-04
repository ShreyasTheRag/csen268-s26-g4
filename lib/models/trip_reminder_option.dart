/// When to notify relative to the trip start time.
enum TripReminderOption {
  tenMinutesBefore,
  oneHourBefore,
  oneDayBefore,
}

extension TripReminderOptionX on TripReminderOption {
  Duration get offsetBeforeStart {
    switch (this) {
      case TripReminderOption.tenMinutesBefore:
        return const Duration(minutes: 10);
      case TripReminderOption.oneHourBefore:
        return const Duration(hours: 1);
      case TripReminderOption.oneDayBefore:
        return const Duration(days: 1);
    }
  }

  String get label {
    switch (this) {
      case TripReminderOption.tenMinutesBefore:
        return '10 min before';
      case TripReminderOption.oneHourBefore:
        return '1 hour before';
      case TripReminderOption.oneDayBefore:
        return '1 day before';
    }
  }

  String get storageKey {
    switch (this) {
      case TripReminderOption.tenMinutesBefore:
        return '10m';
      case TripReminderOption.oneHourBefore:
        return '1h';
      case TripReminderOption.oneDayBefore:
        return '1d';
    }
  }

  int get notificationSlot {
    switch (this) {
      case TripReminderOption.tenMinutesBefore:
        return 0;
      case TripReminderOption.oneHourBefore:
        return 1;
      case TripReminderOption.oneDayBefore:
        return 2;
    }
  }

  String notificationTitle(String tripName) {
    switch (this) {
      case TripReminderOption.tenMinutesBefore:
        return 'Trip starts in 10 minutes';
      case TripReminderOption.oneHourBefore:
        return 'Trip starts in 1 hour';
      case TripReminderOption.oneDayBefore:
        return 'Trip starts tomorrow';
    }
  }

  String notificationBody(String tripName) {
    switch (this) {
      case TripReminderOption.tenMinutesBefore:
        return '$tripName begins in 10 minutes — get ready!';
      case TripReminderOption.oneHourBefore:
        return '$tripName begins in 1 hour — time to head out!';
      case TripReminderOption.oneDayBefore:
        return '$tripName begins in 1 day. Finish packing!';
    }
  }
}

List<TripReminderOption> tripReminderOptionsFromFirestore(
  List<dynamic>? raw,
) {
  if (raw == null || raw.isEmpty) {
    return const [TripReminderOption.oneDayBefore];
  }
  final options = <TripReminderOption>[];
  for (final item in raw) {
    final option = tripReminderOptionFromKey(item.toString());
    if (option != null && !options.contains(option)) {
      options.add(option);
    }
  }
  return options.isEmpty
      ? const [TripReminderOption.oneDayBefore]
      : options;
}

List<String> tripReminderOptionsToFirestore(
  List<TripReminderOption> options,
) {
  return options.map((o) => o.storageKey).toList();
}

TripReminderOption? tripReminderOptionFromKey(String key) {
  switch (key) {
    case '10m':
      return TripReminderOption.tenMinutesBefore;
    case '1h':
      return TripReminderOption.oneHourBefore;
    case '1d':
      return TripReminderOption.oneDayBefore;
    default:
      return null;
  }
}
