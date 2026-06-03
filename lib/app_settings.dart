import 'package:flutter/material.dart';

// App-wide settings. main.dart listens to these, so changing them
// updates the whole app instantly. Lives at lib/app_settings.dart.
final themeNotifier = ValueNotifier<ThemeMode>(ThemeMode.system);
final localeNotifier = ValueNotifier<Locale?>(null); // null = follow device
