import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';

Future<void> registerStaffDevice(String token) async {
  final supabase = Supabase.instance.client;

  final existing = await supabase
      .from('staff_devices')
      .select('id')
      .eq('device_token', token)
      .maybeSingle();

  if (existing == null) {
    await supabase.from('staff_devices').insert({
      'device_token': token,
      'device_name': 'staff_android',
      'is_active': true,
    });

    debugPrint('✅ 새 직원 기기 등록 완료');
  } else {
    await supabase
        .from('staff_devices')
        .update({
          'is_active': true,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', existing['id']);

    debugPrint('✅ 기존 직원 기기 갱신 완료');
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ============================================================
  // Supabase
  // 웹 / Android 둘 다 사용
  // ============================================================

  await Supabase.initialize(
    url: 'https://jwfqdmmhawrheakzkrhu.supabase.co',
    publishableKey: 'sb_publishable_H9mo2RjrFTJ2A1RvopqTgQ_YnR4FBLz',
  );

  // ============================================================
  // Firebase / FCM
  // Android 직원 앱에서만 사용
  // ============================================================

  if (!kIsWeb &&
      defaultTargetPlatform == TargetPlatform.android) {
    await Firebase.initializeApp();

    final messaging = FirebaseMessaging.instance;

    final permission = await messaging.requestPermission();

    debugPrint(
      '🔔 알림 권한 = ${permission.authorizationStatus}',
    );

    final token = await messaging.getToken();

    debugPrint('🔥 FCM TOKEN = $token');

    if (token != null) {
      await registerStaffDevice(token);
    }

    FirebaseMessaging.instance.onTokenRefresh.listen(
      (newToken) async {
        debugPrint('♻️ FCM TOKEN 갱신 = $newToken');

        await registerStaffDevice(newToken);
      },
    );
  } else {
    debugPrint('🌐 웹 실행: Firebase/FCM 초기화 건너뜀');
  }

  // ============================================================
  // App
  // ============================================================

  runApp(
    const ProviderScope(
      child: StaffApp(),
    ),
  );
}