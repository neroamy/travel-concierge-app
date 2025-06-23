/// Message payload structure
class MessagePayload {
  final String sessionId;
  final String appName;
  final String userId;
  final UserMessage newMessage;

  MessagePayload({
    required this.sessionId,
    required this.appName,
    required this.userId,
    required this.newMessage,
  });

  Map<String, dynamic> toJson() {
    return {
      'session_id': sessionId,
      'app_name': appName,
      'user_id': userId,
      'new_message': newMessage.toJson(),
    };
  }
}

/// User message structure
class UserMessage {
  final String role;
  final List<MessagePart> parts;

  UserMessage({
    this.role = 'user',
    required this.parts,
  });

  UserMessage.text(String text)
      : role = 'user',
        parts = [MessagePart.text(text)];

  Map<String, dynamic> toJson() {
    return {
      'role': role,
      'parts': parts.map((part) => part.toJson()).toList(),
    };
  }
}

/// Message part structure
class MessagePart {
  final String? text;
  final Map<String, dynamic>? functionCall;
  final Map<String, dynamic>? functionResponse;

  MessagePart({this.text, this.functionCall, this.functionResponse});

  MessagePart.text(String text)
      : text = text,
        functionCall = null,
        functionResponse = null;

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = {};
    if (text != null) json['text'] = text;
    if (functionCall != null) json['functionCall'] = functionCall;
    if (functionResponse != null) json['functionResponse'] = functionResponse;
    return json;
  }
}

/// API Response Event structure
class ApiEvent {
  final String? author;
  final EventContent? content;
  final String? error;

  ApiEvent({this.author, this.content, this.error});

  factory ApiEvent.fromJson(Map<String, dynamic> json) {
    return ApiEvent(
      author: json['author'],
      content: json['content'] != null
          ? EventContent.fromJson(json['content'])
          : null,
      error: json['error'],
    );
  }

  bool get hasError => error != null;
  bool get hasContent => content != null;
}

/// Event content structure
class EventContent {
  final List<MessagePart> parts;

  EventContent({required this.parts});

  factory EventContent.fromJson(Map<String, dynamic> json) {
    final List<dynamic> partsJson = json['parts'] ?? [];
    final List<MessagePart> parts = partsJson.map((partJson) {
      return MessagePart(
        text: partJson['text'],
        functionCall: partJson['functionCall'],
        functionResponse: partJson['functionResponse'],
      );
    }).toList();

    return EventContent(parts: parts);
  }

  /// Get all text parts from content
  List<String> getTextParts() {
    return parts
        .where((part) => part.text != null && part.text!.trim().isNotEmpty)
        .map((part) => part.text!)
        .toList();
  }

  /// Get all function calls
  List<Map<String, dynamic>> getFunctionCalls() {
    return parts
        .where((part) => part.functionCall != null)
        .map((part) => part.functionCall!)
        .toList();
  }

  /// Get all function responses
  List<Map<String, dynamic>> getFunctionResponses() {
    return parts
        .where((part) => part.functionResponse != null)
        .map((part) => part.functionResponse!)
        .toList();
  }
}

/// Search result model for UI
class SearchResult {
  final String text;
  final String author;
  final DateTime timestamp;
  final List<Map<String, dynamic>> functionResponses;

  SearchResult({
    required this.text,
    required this.author,
    required this.timestamp,
    this.functionResponses = const [],
  });
}

/// Itinerary models for AI agent integration
class ItineraryRequest {
  final String destination;
  final String category;
  final int days;
  final Map<String, dynamic>? preferences;

  ItineraryRequest({
    required this.destination,
    required this.category,
    required this.days,
    this.preferences,
  });

  Map<String, dynamic> toJson() {
    return {
      'destination': destination,
      'category': category,
      'days': days,
      'preferences': preferences ?? {},
    };
  }
}

class ItineraryResponse {
  final List<ItineraryDay> days;
  final String destination;
  final Map<String, dynamic> metadata;

  ItineraryResponse({
    required this.days,
    required this.destination,
    required this.metadata,
  });

  factory ItineraryResponse.fromJson(Map<String, dynamic> json) {
    final List<dynamic> daysJson = json['days'] ?? [];
    final List<ItineraryDay> days =
        daysJson.map((dayJson) => ItineraryDay.fromJson(dayJson)).toList();

    return ItineraryResponse(
      days: days,
      destination: json['destination'] ?? '',
      metadata: json['metadata'] ?? {},
    );
  }
}

class ItineraryDay {
  final int day;
  final String date;
  final List<ItineraryActivity> activities;

  ItineraryDay({
    required this.day,
    required this.date,
    required this.activities,
  });

  factory ItineraryDay.fromJson(Map<String, dynamic> json) {
    final List<dynamic> activitiesJson = json['activities'] ?? [];
    final List<ItineraryActivity> activities = activitiesJson
        .map((activityJson) => ItineraryActivity.fromJson(activityJson))
        .toList();

    return ItineraryDay(
      day: json['day'] ?? 0,
      date: json['date'] ?? '',
      activities: activities,
    );
  }
}

class ItineraryActivity {
  final String time;
  final String title;
  final String description;
  final String location;
  final WeatherInfo? weather;
  final ActivityType type;

  ItineraryActivity({
    required this.time,
    required this.title,
    required this.description,
    required this.location,
    this.weather,
    required this.type,
  });

  factory ItineraryActivity.fromJson(Map<String, dynamic> json) {
    return ItineraryActivity(
      time: json['time'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      location: json['location'] ?? '',
      weather: json['weather'] != null
          ? WeatherInfo.fromJson(json['weather'])
          : null,
      type: ActivityType.fromString(json['type'] ?? 'activity'),
    );
  }
}

class WeatherInfo {
  final String condition;
  final String icon;
  final double temperature;
  final String description;

  WeatherInfo({
    required this.condition,
    required this.icon,
    required this.temperature,
    required this.description,
  });

  factory WeatherInfo.fromJson(Map<String, dynamic> json) {
    return WeatherInfo(
      condition: json['condition'] ?? '',
      icon: json['icon'] ?? '☀️',
      temperature: (json['temperature'] ?? 0).toDouble(),
      description: json['description'] ?? '',
    );
  }
}

enum ActivityType {
  sightseeing,
  dining,
  adventure,
  relaxation,
  cultural,
  nightlife,
  transportation;

  static ActivityType fromString(String value) {
    switch (value.toLowerCase()) {
      case 'sightseeing':
        return ActivityType.sightseeing;
      case 'dining':
        return ActivityType.dining;
      case 'adventure':
        return ActivityType.adventure;
      case 'relaxation':
        return ActivityType.relaxation;
      case 'cultural':
        return ActivityType.cultural;
      case 'nightlife':
        return ActivityType.nightlife;
      case 'transportation':
        return ActivityType.transportation;
      default:
        return ActivityType.sightseeing;
    }
  }

  String get displayName {
    switch (this) {
      case ActivityType.sightseeing:
        return 'Sightseeing';
      case ActivityType.dining:
        return 'Dining';
      case ActivityType.adventure:
        return 'Adventure';
      case ActivityType.relaxation:
        return 'Relaxation';
      case ActivityType.cultural:
        return 'Cultural';
      case ActivityType.nightlife:
        return 'Nightlife';
      case ActivityType.transportation:
        return 'Transportation';
    }
  }

  String get icon {
    switch (this) {
      case ActivityType.sightseeing:
        return '🏛️';
      case ActivityType.dining:
        return '🍽️';
      case ActivityType.adventure:
        return '⛰️';
      case ActivityType.relaxation:
        return '🧘';
      case ActivityType.cultural:
        return '🎭';
      case ActivityType.nightlife:
        return '🌃';
      case ActivityType.transportation:
        return '🚗';
    }
  }
}
