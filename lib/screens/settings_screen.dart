import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          const ListTile(leading: Icon(Icons.palette), title: Text('Theme')),
          const ListTile(
            leading: Icon(Icons.language),
            title: Text('Language'),
          ),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Sign out'),
            onTap: () => AuthService().signOut(),
          ),
        ],
      ),
    );
  }
}
