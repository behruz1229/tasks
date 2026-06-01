import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:audioplayers/audioplayers.dart';

class TimerProvider extends ChangeNotifier {
  int? _activeTaskId;
  String? _activeTaskTitle;
  int _remainingSeconds = 0;
  bool _isRunning = false;
  Timer? _timer;
  final AudioPlayer _audioPlayer = AudioPlayer();
  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();
  bool _isNotificationInitialized = false;

  int? get activeTaskId => _activeTaskId;
  int get remainingSeconds => _remainingSeconds;
  bool get isRunning => _isRunning;
  String? get activeTaskTitle => _activeTaskTitle;

  Future<void> initNotifications() async {
    if (_isNotificationInitialized) return;

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const settings = InitializationSettings(android: androidSettings, iOS: iosSettings);

    await _notificationsPlugin.initialize(settings);

    // 🔹 ЯВНО СОЗДАЁМ КАНАЛЫ

    // 1. Канал для работающего таймера (ТИХИЙ)
    const timerChannel = AndroidNotificationChannel(
      'timer_channel',
      'Active Timer',
      description: 'Shows active timer notification',
      importance: Importance.low,
      playSound: false,      // 🔹 ЗВУКА НЕТ
      enableVibration: false,
      showBadge: false,
    );

    // 2. Канал для завершения (ГРОМКИЙ)
    // Мы НЕ указываем sound: ..., чтобы использовать ЗВУК ПО УМОЛЧАНИЮ (системный)
    const completeChannel = AndroidNotificationChannel(
      'timer_complete_channel',
      'Timer Complete',
      description: 'Notification when timer completes',
      importance: Importance.max,
      playSound: true,       // 🔹 ЗВУК ЕСТЬ (системный)
      enableVibration: false,
      showBadge: true,
    );

    final androidPlugin = _notificationsPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.createNotificationChannel(timerChannel);
    await androidPlugin?.createNotificationChannel(completeChannel);

    _isNotificationInitialized = true;
  }

  Future<void> requestPermissions() async {
    await initNotifications();

    final androidPlugin = _notificationsPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) {
      await androidPlugin.requestNotificationsPermission();
    }
  }

  Future<void> startTimer(int taskId, String taskTitle, int durationSeconds) async {
    await requestPermissions();

    if (_activeTaskId != null && _activeTaskId != taskId) {
      _timer?.cancel();
      await _cancelNotification();
    }

    _activeTaskId = taskId;
    _activeTaskTitle = taskTitle;
    _remainingSeconds = durationSeconds;
    _isRunning = true;
    notifyListeners();

    await _showNotification();
    _startTicker();
  }

  void restartTimer(int taskId, int newDurationSeconds) {
    if (_activeTaskId == taskId) {
      _remainingSeconds = newDurationSeconds;
      _isRunning = true;
      notifyListeners();
      _startTicker();
    }
  }

  void togglePause() {
    if (_isRunning) {
      _isRunning = false;
      _timer?.cancel();
    } else {
      _isRunning = true;
      _startTicker();
    }
    notifyListeners();
  }

  Future<void> stopTimer() async {
    _timer?.cancel();
    await _cancelNotification();
    _activeTaskId = null;
    _activeTaskTitle = null;
    _remainingSeconds = 0;
    _isRunning = false;
    notifyListeners();
  }

  void _startTicker() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        _remainingSeconds--;
        _showNotification();
        notifyListeners();
      } else {
        _onComplete();
      }
    });
  }

  Future<void> _showNotification() async {
    if (!_isNotificationInitialized) return;

    // Обновляем уведомление (ТИХО)
    final androidDetails = AndroidNotificationDetails(
      'timer_channel',
      'Active Timer',
      importance: Importance.low,
      priority: Priority.low,
      ongoing: true,
      autoCancel: false,
      showWhen: true,
      icon: '@mipmap/ic_launcher',
      onlyAlertOnce: true,
      playSound: false,
      sound: null,
      enableVibration: false,
      channelShowBadge: false,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: false,
      presentBadge: true,
      presentSound: false,
    );

    final details = NotificationDetails(android: androidDetails, iOS: iosDetails);

    await _notificationsPlugin.show(
      0,
      '⏱️ ${_activeTaskTitle ?? "Task"}',
      'Осталось: ${_formatDuration(_remainingSeconds)}',
      details,
      payload: 'timer',
    );
  }

  Future<void> _cancelNotification() async {
    await _notificationsPlugin.cancel(0);
  }

  Future<void> _onComplete() async {
    _timer?.cancel();
    _isRunning = false;
    notifyListeners();

    // 🔔 УВЕДОМЛЕНИЕ О ЗАВЕРШЕНИИ
    final androidDetails = AndroidNotificationDetails(
      'timer_complete_channel',
      'Timer Complete',
      importance: Importance.max,
      priority: Priority.max,
      category: AndroidNotificationCategory.alarm,
      playSound: true,       // 🔹 ВКЛЮЧАЕМ ЗВУК
      // 🔹 sound: null — используем системный звук по умолчанию!
      fullScreenIntent: true,
      visibility: NotificationVisibility.public,
      enableVibration: false,
      channelShowBadge: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details = NotificationDetails(android: androidDetails, iOS: iosDetails);

    // ID = 1, чтобы создать НОВОЕ уведомление, а не обновить старое
    await _notificationsPlugin.show(
      1,
      ' Время вышло!',
      'Задача "${_activeTaskTitle ?? "Task"}" завершена',
      details,
      payload: 'complete',
    );

    // 🔊 Дополнительно пытаемся воспроизвести звук через AudioPlayer (онлайн)
    // Это страховка, если системный звук отключен
    try {
      await _audioPlayer.play(UrlSource('https://www.soundjay.com/misc/sounds/bell-ringing-05.mp3'));
    } catch (e) {
      // Игнорируем ошибки онлайн звука, главное что системный сработал
      debugPrint('Online sound error: $e');
    }

    await Future.delayed(const Duration(seconds: 15));
    await _cancelNotification();
  }

  String _formatDuration(int seconds) {
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    final s = seconds % 60;
    if (h > 0) {
      return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    }
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _timer?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }
}