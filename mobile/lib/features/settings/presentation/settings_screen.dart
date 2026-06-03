import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/matching/matching_engine.dart';
import '../../../core/preferences/user_preferences.dart';
import '../../../core/theme/app_theme.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  late DifficultyMode _difficulty;
  late bool _storeAudio;

  @override
  void initState() {
    super.initState();
    final prefs = ref.read(userPreferencesProvider);
    _difficulty = prefs.difficulty;
    _storeAudio = prefs.storeAudio;
  }

  @override
  Widget build(BuildContext context) {
    final prefs = ref.read(userPreferencesProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          const _SectionHeader('Recitation'),
          ListTile(
            title: const Text('Difficulty mode'),
            subtitle: Text(_difficulty.name),
            trailing: SegmentedButton<DifficultyMode>(
              segments: const [
                ButtonSegment(value: DifficultyMode.easy, label: Text('E')),
                ButtonSegment(value: DifficultyMode.normal, label: Text('N')),
                ButtonSegment(value: DifficultyMode.strict, label: Text('S')),
              ],
              selected: {_difficulty},
              showSelectedIcon: false,
              onSelectionChanged: (s) async {
                final m = s.first;
                setState(() => _difficulty = m);
                await prefs.setDifficulty(m);
              },
            ),
          ),
          const _SectionHeader('Privacy'),
          SwitchListTile(
            title: const Text('Store recorded audio'),
            subtitle: const Text(
              'Off by default. Only recognized text + confidence are stored.',
            ),
            value: _storeAudio,
            onChanged: (v) async {
              setState(() => _storeAudio = v);
              await prefs.setStoreAudio(v);
            },
          ),
          ListTile(
            title: const Text('Delete all local data'),
            subtitle: const Text('Clears preferences. Session history on the server is unaffected.'),
            trailing: const Icon(Icons.delete_outline, color: Colors.redAccent),
            onTap: () async {
              final ok = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  backgroundColor: AppColors.surface,
                  title: const Text('Delete local data?'),
                  content: const Text('This cannot be undone.'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                    TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete')),
                  ],
                ),
              );
              if (ok == true) {
                await prefs.clearAll();
                if (!context.mounted) return;
                setState(() {
                  _difficulty = DifficultyMode.normal;
                  _storeAudio = false;
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Local data cleared')),
                );
              }
            },
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String label;
  const _SectionHeader(this.label);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        label.toUpperCase(),
        style: const TextStyle(
          color: AppColors.gold,
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}
