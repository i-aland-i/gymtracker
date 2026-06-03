import 'package:flutter/material.dart';
import '../supabase_client.dart';
import '../app_settings.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    final email = supabase.auth.currentUser?.email ?? '';
    final initial = email.isNotEmpty ? email[0].toUpperCase() : '?';

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.only(top: 8, bottom: 40),
        children: [
          // ── Profile ────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Card(
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: cs.primaryContainer,
                      child: Text(
                        initial,
                        style: TextStyle(
                          color: cs.onPrimaryContainer,
                          fontWeight: FontWeight.w700,
                          fontSize: 18,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            email.isEmpty ? 'Not signed in' : email,
                            style: t.titleSmall,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Your account',
                            style: t.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Appearance ─────────────────────────────────────────────────
          _SectionLabel('Appearance'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Card(
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: ValueListenableBuilder<ThemeMode>(
                  valueListenable: themeNotifier,
                  builder: (context, mode, _) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Theme', style: t.titleSmall),
                      const SizedBox(height: 12),
                      SegmentedButton<ThemeMode>(
                        expandedInsets: EdgeInsets.zero,
                        segments: const [
                          ButtonSegment(
                            value: ThemeMode.system,
                            label: Text('System'),
                            icon: Icon(Icons.brightness_auto_rounded, size: 16),
                          ),
                          ButtonSegment(
                            value: ThemeMode.light,
                            label: Text('Light'),
                            icon: Icon(Icons.light_mode_rounded, size: 16),
                          ),
                          ButtonSegment(
                            value: ThemeMode.dark,
                            label: Text('Dark'),
                            icon: Icon(Icons.dark_mode_rounded, size: 16),
                          ),
                        ],
                        selected: {mode},
                        onSelectionChanged: (s) => themeNotifier.value = s.first,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ── Language ───────────────────────────────────────────────────
          _SectionLabel('Language'),
          ValueListenableBuilder<Locale?>(
            valueListenable: localeNotifier,
            builder: (context, locale, _) {
              final current = locale?.languageCode ?? 'en';
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Card(
                  margin: EdgeInsets.zero,
                  child: Column(
                    children: [
                      _LangTile(
                        label: 'English',
                        selected: current == 'en',
                        onTap: () => localeNotifier.value = const Locale('en'),
                      ),
                      Divider(
                        height: 1,
                        indent: 20,
                        endIndent: 20,
                        color: cs.outlineVariant,
                      ),
                      _LangTile(
                        label: 'العربية',
                        sublabel: 'Arabic',
                        selected: current == 'ar',
                        onTap: () => localeNotifier.value = const Locale('ar'),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
            child: Text(
              'Switching to Arabic flips the layout direction and all built-in controls.',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: cs.onSurfaceVariant),
            ),
          ),

          // ── Account ────────────────────────────────────────────────────
          _SectionLabel('Account'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Card(
              margin: EdgeInsets.zero,
              child: ListTile(
                leading: Icon(Icons.logout_rounded, color: cs.error),
                title: Text(
                  'Sign out',
                  style: t.titleSmall?.copyWith(color: cs.error),
                ),
                trailing: Icon(
                  Icons.chevron_right_rounded,
                  color: cs.error.withValues(alpha: 0.5),
                ),
                onTap: () => supabase.auth.signOut(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
      child: Text(
        text.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: Theme.of(context).colorScheme.primary,
          letterSpacing: 1.2,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _LangTile extends StatelessWidget {
  const _LangTile({
    required this.label,
    this.sublabel,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final String? sublabel;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ListTile(
      title: Text(label),
      subtitle: sublabel != null ? Text(sublabel!) : null,
      trailing: selected
          ? Icon(Icons.check_rounded, color: cs.primary, size: 20)
          : const SizedBox(width: 20),
      onTap: onTap,
    );
  }
}
