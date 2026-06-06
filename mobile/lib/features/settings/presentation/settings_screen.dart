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
  late String _backendUrl;

  @override
  void initState() {
    super.initState();
    final prefs = ref.read(userPreferencesProvider);
    _difficulty = prefs.difficulty;
    _storeAudio = prefs.storeAudio;
    _backendUrl = prefs.backendUrl;
  }

  Future<void> _editBackendUrl(BuildContext context) async {
    final controller = TextEditingController(text: _backendUrl);
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Backend URL'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: controller,
              autofocus: true,
              decoration: const InputDecoration(
                hintText: 'http://192.168.1.10:3000',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.url,
            ),
            const SizedBox(height: 8),
            const Text(
              'Use the LAN IP of the machine running docker-compose, '
              'including http:// and the port.',
              style: TextStyle(color: AppColors.mutedText, fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (result == null) return;
    await ref.read(userPreferencesProvider).setBackendUrl(result);
    if (!context.mounted) return;
    setState(() => _backendUrl = ref.read(userPreferencesProvider).backendUrl);
    // Force the Dio-providing providers to rebuild against the new URL.
    ref.invalidate(userPreferencesProvider);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Backend URL set to $_backendUrl')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final prefs = ref.read(userPreferencesProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          const _SectionHeader('Connection'),
          ListTile(
            title: const Text('Backend URL'),
            subtitle: Text(
              _backendUrl,
              style: const TextStyle(color: AppColors.mutedText),
            ),
            trailing: const Icon(Icons.edit_outlined, color: AppColors.gold),
            onTap: () => _editBackendUrl(context),
          ),
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
          const _SectionHeader('الخصوصية'),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: Directionality(
              textDirection: TextDirection.rtl,
              child: Text(
                'يقوم التطبيق بتخزين النصوص المعرَّف بها صوتياً لتحسين تتبع الأخطاء. '
                'يمكنك حذف جميع بياناتك المحلية من خلال زر الحذف أعلاه. '
                'لا يتم مشاركة بياناتك مع أطراف ثالثة.',
                style: TextStyle(color: AppColors.mutedText, height: 1.6),
              ),
            ),
          ),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: TextButton(
                onPressed: () => _showPrivacyPolicy(context),
                child: const Text('سياسة الخصوصية الكاملة'),
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Future<void> _showPrivacyPolicy(BuildContext context) {
    return showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('سياسة الخصوصية'),
        content: const SingleChildScrollView(
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: Text(
              // Placeholder copy — to be replaced with the legal version before
              // the production release (5c.5 checklist).
              'هذا نص مبدئي لسياسة الخصوصية. النسخة النهائية ستُنشر قبل الإطلاق الرسمي. '
              '\n\nالبيانات المُخزَّنة: النصوص المعرَّف بها صوتياً، درجات الثقة، نوع '
              'الخطأ، عدد المحاولات. لا يتم تخزين الصوت الخام إلا بعد موافقة صريحة منك. '
              '\n\nمشاركة البيانات: لا تتم مشاركة بياناتك مع أي طرف ثالث لأغراض إعلانية. '
              '\n\nالحذف: يمكنك حذف بياناتك المحلية أو طلب حذف حسابك في أي وقت.',
              style: TextStyle(height: 1.6),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('حسناً'),
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
