
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:inbota/modules/notifications/domain/repositories/i_notifications_repository.dart';
import 'package:inbota/presentation/routes/app_navigation.dart';
import 'package:inbota/presentation/routes/app_routes.dart';
import 'package:inbota/shared/services/push/notification_payload.dart';
import 'package:package_info_plus/package_info_plus.dart';

class PushNotificationService {
  PushNotificationService._();
  static final PushNotificationService instance = PushNotificationService._();

  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  INotificationsRepository? _repository;
  bool _initialized = false;
  String? _currentTopic;

  void setRepository(INotificationsRepository repository) {
    _repository = repository;
  }

  Future<void> initialize() async {
    if (_initialized) return;

    // 1. Init local notifications
    await _initLocalNotifications();

    // 2. Load or generate ntfy topic
    await _setupNtfy();

    _initialized = true;
  }

  Future<void> _initLocalNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsIOS = DarwinInitializationSettings();

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _localNotifications.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: (details) {
        if (details.payload != null) {
          try {
            final data = jsonDecode(details.payload!);
            if (data is Map<String, dynamic>) {
              onTap(NotificationPayload.fromMap(data));
            }
          } catch (e) {
            if (kDebugMode) print('Error parsing notification payload: $e');
          }
        }
      },
    );
  }

  Future<void> _setupNtfy() async {
    // TODO: Implement ntfy.sh topic generation and subscription
    // 1. Check if topic exists in secure storage
    // 2. If not, generate uuid and save
    // 3. Register topic on backend
    // 4. Start WebSocket listener
  }

  void _showLocalNotification(String title, String body, Map<String, dynamic> data) async {
    await _localNotifications.show(
      id: title.hashCode,
      title: title,
      body: body,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'high_importance_channel',
          'High Importance Notifications',
          channelDescription: 'This channel is used for important notifications.',
          importance: Importance.max,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: jsonEncode(data),
    );
  }

  void onTap(NotificationPayload payload) {
    if (payload.id != null) {
      _repository?.markAsRead(payload.id!);
    }

    switch (payload.type) {
      case NotificationType.reminder:
        AppNavigation.navigate(AppRoutes.rootReminders, args: {'id': payload.referenceId});
        break;
      case NotificationType.event:
        AppNavigation.navigate(AppRoutes.rootEvents, args: {'id': payload.referenceId});
        break;
      case NotificationType.task:
        AppNavigation.navigate(AppRoutes.rootHome, args: {'id': payload.referenceId});
        break;
      case NotificationType.routine:
        AppNavigation.navigate(AppRoutes.rootSchedule);
        break;
      default:
        break;
    }
  }

  Future<void> registerToken() async {
    if (_currentTopic != null && _repository != null) {
      final info = await PackageInfo.fromPlatform();
      String platform = Platform.isIOS ? 'ios' : 'android';
      await _repository!.registerDeviceToken(
        _currentTopic!,
        platform,
        appVersion: info.version,
      );
    }
  }

  Future<void> unregisterToken() async {
    if (_currentTopic != null && _repository != null) {
      await _repository!.unregisterDeviceToken(_currentTopic!);
    }
    // TODO: Stop ntfy subscription
  }
}
