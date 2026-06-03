import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://YOURPROJECT.supabase.co', // Settings → API
    anonKey: 'YOUR_ANON_KEY',
  );
  runApp(const MyApp());
}

final supabase = Supabase.instance.client;
