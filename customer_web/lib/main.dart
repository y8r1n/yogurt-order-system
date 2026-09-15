import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://jwfqdmmhawrheakzkrhu.supabase.co',
    publishableKey: 'sb_publishable_H9mo2RjrFTJ2A1RvopqTgQ_YnR4FBLz',
  );

  runApp(
    const ProviderScope(
      child: CustomerApp(),
    ),
  );
}