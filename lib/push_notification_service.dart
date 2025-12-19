import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:toothfile/dashboard_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

class PushNotificationService {
  static final FlutterLocalNotificationsPlugin _flnp =
      FlutterLocalNotificationsPlugin();
  static GlobalKey<NavigatorState>? _navigatorKey;
  static RealtimeChannel? _channel;
  static StreamSubscription<AuthState>? _authSub;
  static Timer? _pollTimer;
  static Set<String> _seenShared = {};
  static Set<String> _seenRequests = {};
  static Set<String> _seenDownloads = {};
  static Set<String> _seenAccepted = {};
  static WindowsNotificationDetails _windowsDetails() {
    return WindowsNotificationDetails(
      actions: <WindowsAction>[
        WindowsAction(content: 'Open', arguments: 'open'),
        WindowsAction(content: 'Dismiss', arguments: 'dismiss'),
      ],
    );
  }

  static Future<bool> _isAllowed(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final push = prefs.getBool('push_enabled') ?? false;
    if (!push) return false;
    return prefs.getBool(key) ?? true;
  }

  static bool get _pushCapable {
    return kIsWeb ||
        (!kIsWeb &&
            (defaultTargetPlatform == TargetPlatform.android ||
                defaultTargetPlatform == TargetPlatform.iOS) &&
            Firebase.apps.isNotEmpty);
  }

  static Future<void> initialize(GlobalKey<NavigatorState> navigatorKey) async {
    _navigatorKey = navigatorKey;

    final androidInit = const AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    final iosInit = const DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    final windowsInit = const WindowsInitializationSettings(
      appUserModelId: 'com.toothfile.desktop',
      appName: 'ToothFile',
      guid: '8a1e7f42-3f50-4f9a-9f3e-5e6d2c7b9c1f',
    );
    await _flnp.initialize(
      InitializationSettings(
        android: androidInit,
        iOS: iosInit,
        windows: windowsInit,
      ),
      onDidReceiveNotificationResponse: (resp) {
        final payload = resp.payload;
        final action = resp.actionId;
        if (payload != null && payload.isNotEmpty) {
          try {
            final data = jsonDecode(payload) as Map<String, dynamic>;
            if (action == 'open') {
              _handleData(data);
            }
          } catch (_) {}
        }
      },
    );

    if (_pushCapable) {
      FirebaseMessaging.onMessage.listen((message) async {
        final notification = message.notification;
        final payload = jsonEncode(message.data);
        if (notification != null) {
          final t = message.data['type']?.toString() ?? '';
          String key = 'notif_file_received';
          if (t == 'file_tracker') {
            key = 'notif_file_tracker';
          } else if (t == 'connection_request') {
            key = 'notif_connection_requests';
          } else if (t == 'connection_accepted') {
            key = 'notif_connection_accepted';
          }
          if (await _isAllowed(key)) {
            await _flnp.show(
              notification.hashCode,
              notification.title,
              notification.body,
              NotificationDetails(
                android: AndroidNotificationDetails(
                  'toothfile_channel',
                  'Toothfile Notifications',
                  importance: Importance.high,
                  priority: Priority.high,
                  icon: '@mipmap/ic_launcher',
                ),
                iOS: const DarwinNotificationDetails(
                  presentAlert: true,
                  presentSound: true,
                  presentBadge: true,
                ),
                windows: _windowsDetails(),
              ),
              payload: payload,
            );
          }
        } else {
          final t = message.data['type']?.toString() ?? '';
          String title = 'Notification';
          String body = '';
          String key = 'notif_file_received';
          if (t == 'file_received') {
            title = 'New file received';
            body = 'You have a new shared file';
            key = 'notif_file_received';
          } else if (t == 'file_tracker') {
            title = 'File downloaded';
            body = 'Your file was downloaded';
            key = 'notif_file_tracker';
          } else if (t == 'connection_request') {
            title = 'New connection request';
            body = 'You have a new connection request';
            key = 'notif_connection_requests';
          } else if (t == 'connection_accepted') {
            title = 'Connection accepted';
            body = 'Your connection request was accepted';
            key = 'notif_connection_accepted';
          }
          if (await _isAllowed(key)) {
            await _flnp.show(
              DateTime.now().millisecondsSinceEpoch,
              title,
              body,
              const NotificationDetails(
                android: AndroidNotificationDetails(
                  'toothfile_channel',
                  'Toothfile Notifications',
                  importance: Importance.high,
                  priority: Priority.high,
                  icon: '@mipmap/ic_launcher',
                ),
                iOS: DarwinNotificationDetails(
                  presentAlert: true,
                  presentSound: true,
                  presentBadge: true,
                ),
              ),
              payload: payload,
            );
          }
        }
      });
      FirebaseMessaging.onMessageOpenedApp.listen((message) {
        _handleData(message.data);
      });
    } else {
      _authSub?.cancel();
      _authSub = Supabase.instance.client.auth.onAuthStateChange.listen((
        state,
      ) {
        final session = state.session;
        if (session?.user != null) {
          _setupRealtimeFallback();
          _startPolling();
        } else {
          _channel?.unsubscribe();
          _channel = null;
          _pollTimer?.cancel();
          _pollTimer = null;
        }
      });
    }
  }

  static Future<void> ensurePermissionsAndSyncToken() async {
    if (!_pushCapable) return;
    await FirebaseMessaging.instance.requestPermission();
    final token = await FirebaseMessaging.instance.getToken();
    final client = Supabase.instance.client;
    final user = client.auth.currentUser;
    if (user == null) return;
    await client
        .from('profiles')
        .update({'fcm_token': token})
        .eq('id', user.id);
  }

  static Future<void> disableNotifications() async {
    final client = Supabase.instance.client;
    final user = client.auth.currentUser;
    if (user == null) return;
    await client.from('profiles').update({'fcm_token': null}).eq('id', user.id);
    _channel?.unsubscribe();
    _channel = null;
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  static void _setupRealtimeFallback() {
    final client = Supabase.instance.client;
    final user = client.auth.currentUser;
    if (user == null) return;
    if (_channel != null) return;
    _channel = client.channel('realtime:notifications_${user.id}');
    _channel!.onPostgresChanges(
      event: PostgresChangeEvent.insert,
      schema: 'public',
      table: 'shared_files',
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'receiver_id',
        value: user.id,
      ),
      callback: (payload) async {
        final record = payload.newRecord ?? {};
        final fileName = record['file_name']?.toString() ?? 'Dental file';
        final senderId = record['sender_id']?.toString() ?? '';
        final data = {
          'type': 'file_received',
          'fileId': record['id']?.toString(),
          'senderId': senderId,
        };
        if (await _isAllowed('notif_file_received')) {
          await _flnp.show(
            DateTime.now().millisecondsSinceEpoch,
            'New file received',
            fileName,
            NotificationDetails(
              android: AndroidNotificationDetails(
                'toothfile_channel',
                'Toothfile Notifications',
                importance: Importance.high,
                priority: Priority.high,
                icon: '@mipmap/ic_launcher',
              ),
              iOS: const DarwinNotificationDetails(),
              windows: _windowsDetails(),
            ),
            payload: jsonEncode(data),
          );
        }
      },
    );
    _channel!.onPostgresChanges(
      event: PostgresChangeEvent.insert,
      schema: 'public',
      table: 'connection_requests',
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'receiver_id',
        value: user.id,
      ),
      callback: (payload) async {
        final record = payload.newRecord ?? {};
        final data = {
          'type': 'connection_request',
          'requestId': record['id']?.toString(),
        };
        if (await _isAllowed('notif_connection_requests')) {
          await _flnp.show(
            DateTime.now().millisecondsSinceEpoch,
            'New connection request',
            'You have a new connection request',
            NotificationDetails(
              android: AndroidNotificationDetails(
                'toothfile_channel',
                'Toothfile Notifications',
                importance: Importance.high,
                priority: Priority.high,
                icon: '@mipmap/ic_launcher',
              ),
              iOS: const DarwinNotificationDetails(),
              windows: _windowsDetails(),
            ),
            payload: jsonEncode(data),
          );
        }
      },
    );
    _channel!.onPostgresChanges(
      event: PostgresChangeEvent.insert,
      schema: 'public',
      table: 'file_tracking',
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'event_type',
        value: 'downloaded',
      ),
      callback: (payload) async {
        final rec = payload.newRecord ?? {};
        final sfId = rec['shared_file_id']?.toString();
        final trackId = rec['id']?.toString();
        if (trackId != null && _seenDownloads.contains(trackId)) return;
        if (sfId == null) return;
        final sf = await client
            .from('shared_files')
            .select('id,file_name,sender_id')
            .eq('id', sfId)
            .maybeSingle();
        if (sf == null) return;
        if (sf['sender_id']?.toString() != user.id) return;
        final data = {
          'type': 'file_tracker',
          'eventType': 'downloaded',
          'fileId': sfId,
        };
        if (await _isAllowed('notif_file_tracker')) {
          if (trackId != null) _seenDownloads.add(trackId);
          try {
            final prefs = await SharedPreferences.getInstance();
            final uid = user.id;
            await prefs.setStringList(
              'seen_downloads_$uid',
              _seenDownloads.toList(),
            );
          } catch (_) {}
          await _flnp.show(
            DateTime.now().millisecondsSinceEpoch,
            'File downloaded',
            sf['file_name']?.toString() ?? 'Your file was downloaded',
            NotificationDetails(
              android: AndroidNotificationDetails(
                'toothfile_channel',
                'Toothfile Notifications',
                importance: Importance.high,
                priority: Priority.high,
                icon: '@mipmap/ic_launcher',
              ),
              iOS: const DarwinNotificationDetails(),
              windows: _windowsDetails(),
            ),
            payload: jsonEncode(data),
          );
        }
      },
    );
    _channel!.onPostgresChanges(
      event: PostgresChangeEvent.update,
      schema: 'public',
      table: 'connection_requests',
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'sender_id',
        value: user.id,
      ),
      callback: (payload) async {
        final rec = payload.newRecord ?? {};
        if (rec['status']?.toString() != 'accepted') return;
        final data = {
          'type': 'connection_accepted',
          'requestId': rec['id']?.toString(),
        };
        if (await _isAllowed('notif_connection_accepted')) {
          await _flnp.show(
            DateTime.now().millisecondsSinceEpoch,
            'Connection accepted',
            'Your connection request was accepted',
            NotificationDetails(
              android: AndroidNotificationDetails(
                'toothfile_channel',
                'Toothfile Notifications',
                importance: Importance.high,
                priority: Priority.high,
                icon: '@mipmap/ic_launcher',
              ),
              iOS: const DarwinNotificationDetails(),
              windows: _windowsDetails(),
            ),
            payload: jsonEncode(data),
          );
        }
      },
    );
    _channel!.subscribe();
  }

  static Future<void> _startPolling() async {
    final client = Supabase.instance.client;
    final user = client.auth.currentUser;
    if (user == null) return;
    final prefs = await SharedPreferences.getInstance();
    _seenShared = (prefs.getStringList('seen_shared_files_${user.id}') ?? [])
        .toSet();
    _seenRequests = (prefs.getStringList('seen_conn_req_${user.id}') ?? [])
        .toSet();
    _seenDownloads = (prefs.getStringList('seen_downloads_${user.id}') ?? [])
        .toSet();
    _seenAccepted = (prefs.getStringList('seen_conn_acc_${user.id}') ?? [])
        .toSet();
    await _pollNow();
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 20), (_) async {
      await _pollNow();
    });
  }

  static Future<void> _pollNow() async {
    final client = Supabase.instance.client;
    final user = client.auth.currentUser;
    if (user == null) return;
    try {
      final shared = await client
          .from('shared_files')
          .select('id,file_name,sender_id,receiver_id,created_at')
          .eq('receiver_id', user.id)
          .order('created_at', ascending: false)
          .limit(20);
      for (final r in shared) {
        final id = r['id']?.toString();
        if (id == null) continue;
        if (_seenShared.contains(id)) continue;
        _seenShared.add(id);
        final data = {
          'type': 'file_received',
          'fileId': id,
          'senderId': r['sender_id']?.toString(),
        };
        if (await _isAllowed('notif_file_received')) {
          await _flnp.show(
            DateTime.now().millisecondsSinceEpoch,
            'New file received',
            r['file_name']?.toString() ?? 'Dental file',
            NotificationDetails(
              android: AndroidNotificationDetails(
                'toothfile_channel',
                'Toothfile Notifications',
                importance: Importance.high,
                priority: Priority.high,
                icon: '@mipmap/ic_launcher',
              ),
              iOS: const DarwinNotificationDetails(),
              windows: _windowsDetails(),
            ),
            payload: jsonEncode(data),
          );
        }
      }
      final reqs = await client
          .from('connection_requests')
          .select('id,receiver_id,created_at')
          .eq('receiver_id', user.id)
          .order('created_at', ascending: false)
          .limit(20);
      for (final r in reqs) {
        final id = r['id']?.toString();
        if (id == null) continue;
        if (_seenRequests.contains(id)) continue;
        _seenRequests.add(id);
        final data = {'type': 'connection_request', 'requestId': id};
        if (await _isAllowed('notif_connection_requests')) {
          await _flnp.show(
            DateTime.now().millisecondsSinceEpoch,
            'New connection request',
            'You have a new connection request',
            NotificationDetails(
              android: AndroidNotificationDetails(
                'toothfile_channel',
                'Toothfile Notifications',
                importance: Importance.high,
                priority: Priority.high,
                icon: '@mipmap/ic_launcher',
              ),
              iOS: const DarwinNotificationDetails(),
              windows: _windowsDetails(),
            ),
            payload: jsonEncode(data),
          );
        }
      }
      final dls = await client
          .from('file_tracking')
          .select('id,shared_file_id,event_type,created_at')
          .eq('event_type', 'downloaded')
          .order('created_at', ascending: false)
          .limit(50);
      for (final d in dls) {
        final id = d['id']?.toString();
        if (id == null) continue;
        if (_seenDownloads.contains(id)) continue;
        final sfId = d['shared_file_id']?.toString();
        if (sfId == null) continue;
        final sf = await client
            .from('shared_files')
            .select('id,file_name,sender_id')
            .eq('id', sfId)
            .maybeSingle();
        if (sf == null) continue;
        if (sf['sender_id']?.toString() != user.id) continue;
        _seenDownloads.add(id);
        final data = {
          'type': 'file_tracker',
          'eventType': 'downloaded',
          'fileId': sfId,
        };
        if (await _isAllowed('notif_file_tracker')) {
          await _flnp.show(
            DateTime.now().millisecondsSinceEpoch,
            'File downloaded',
            sf['file_name']?.toString() ?? 'Your file was downloaded',
            NotificationDetails(
              android: AndroidNotificationDetails(
                'toothfile_channel',
                'Toothfile Notifications',
                importance: Importance.high,
                priority: Priority.high,
                icon: '@mipmap/ic_launcher',
              ),
              iOS: const DarwinNotificationDetails(),
              windows: _windowsDetails(),
            ),
            payload: jsonEncode(data),
          );
        }
      }
      final acc = await client
          .from('connection_requests')
          .select('id,sender_id,status,updated_at')
          .eq('sender_id', user.id)
          .eq('status', 'accepted')
          .order('updated_at', ascending: false)
          .limit(50);
      for (final a in acc) {
        final id = a['id']?.toString();
        if (id == null) continue;
        if (_seenAccepted.contains(id)) continue;
        _seenAccepted.add(id);
        final data = {'type': 'connection_accepted', 'requestId': id};
        if (await _isAllowed('notif_connection_accepted')) {
          await _flnp.show(
            DateTime.now().millisecondsSinceEpoch,
            'Connection accepted',
            'Your connection request was accepted',
            NotificationDetails(
              android: AndroidNotificationDetails(
                'toothfile_channel',
                'Toothfile Notifications',
                importance: Importance.high,
                priority: Priority.high,
                icon: '@mipmap/ic_launcher',
              ),
              iOS: const DarwinNotificationDetails(),
              windows: _windowsDetails(),
            ),
            payload: jsonEncode(data),
          );
        }
      }
      final prefs = await SharedPreferences.getInstance();
      final userId = user.id;
      await prefs.setStringList(
        'seen_shared_files_$userId',
        _seenShared.toList(),
      );
      await prefs.setStringList(
        'seen_conn_req_$userId',
        _seenRequests.toList(),
      );
      await prefs.setStringList(
        'seen_downloads_$userId',
        _seenDownloads.toList(),
      );
      await prefs.setStringList(
        'seen_conn_acc_$userId',
        _seenAccepted.toList(),
      );
    } catch (_) {}
  }

  static Future<void> sendTestNotification() async {
    await _flnp.show(
      DateTime.now().millisecondsSinceEpoch,
      '🔔 Test Notification',
      'This is a test push notification from Toothfile!\ntoothfile.com',
      NotificationDetails(
        android: AndroidNotificationDetails(
          'toothfile_channel',
          'Toothfile Notifications',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(),
        windows: _windowsDetails(),
      ),
      payload: jsonEncode({'type': 'file_received'}),
    );
  }

  static void _handleData(Map<String, dynamic> data) {
    final type = data['type']?.toString() ?? '';
    int index = 0;
    if (type == 'file_received') {
      index = 0;
    } else if (type == 'file_tracker') {
      index = 2;
    } else if (type == 'connection_request') {
      index = 3;
    } else if (type == 'connection_accepted') {
      index = 4;
    }
    _navigatorKey?.currentState?.pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (context) => DashboardPage(initialIndex: index),
      ),
      (route) => false,
    );
  }
}
