import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/theme_provider.dart';
import '../config/app_config.dart';

/// Settings Screen - App preferences including dark mode toggle
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final themeMode = ref.watch(themeProvider);

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: colorScheme.surface,
        surfaceTintColor: colorScheme.surfaceTint,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // App Info
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    colorScheme.primary.withOpacity(0.1),
                    colorScheme.tertiary.withOpacity(0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [colorScheme.primary, colorScheme.tertiary],
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.calendar_month_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Attendance Dashboard',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          AppConfig.companyName,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Version 1.0.0',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Appearance section
            Text(
              'Tampilan',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(height: 12),

            // Theme mode selector
            Container(
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  _ThemeOption(
                    icon: Icons.brightness_auto_rounded,
                    title: 'Sistem',
                    subtitle: 'Ikuti pengaturan perangkat',
                    selected: themeMode == ThemeMode.system,
                    onTap: () => ref.read(themeProvider.notifier).setTheme(ThemeMode.system),
                    colorScheme: colorScheme,
                  ),
                  Divider(height: 1, color: colorScheme.outline.withOpacity(0.1)),
                  _ThemeOption(
                    icon: Icons.light_mode_rounded,
                    title: 'Terang',
                    subtitle: 'Mode terang',
                    selected: themeMode == ThemeMode.light,
                    onTap: () => ref.read(themeProvider.notifier).setTheme(ThemeMode.light),
                    colorScheme: colorScheme,
                  ),
                  Divider(height: 1, color: colorScheme.outline.withOpacity(0.1)),
                  _ThemeOption(
                    icon: Icons.dark_mode_rounded,
                    title: 'Gelap',
                    subtitle: 'Mode gelap',
                    selected: themeMode == ThemeMode.dark,
                    onTap: () => ref.read(themeProvider.notifier).setTheme(ThemeMode.dark),
                    colorScheme: colorScheme,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // About section
            Text(
              'Tentang',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(height: 12),

            Container(
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  _SettingsItem(
                    icon: Icons.info_outline_rounded,
                    title: 'Tentang Aplikasi',
                    onTap: () => _showAboutDialog(context, colorScheme),
                    colorScheme: colorScheme,
                  ),
                  Divider(height: 1, color: colorScheme.outline.withOpacity(0.1)),
                  _SettingsItem(
                    icon: Icons.help_outline_rounded,
                    title: 'Bantuan',
                    onTap: () {},
                    colorScheme: colorScheme,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAboutDialog(BuildContext context, ColorScheme colorScheme) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [colorScheme.primary, colorScheme.tertiary],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.calendar_month_rounded, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            const Text('Attendance Dashboard'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Version 1.0.0'),
            const SizedBox(height: 8),
            Text(
              'Aplikasi dashboard kehadiran karyawan dengan fitur:\n'
              '• View attendance per karyawan\n'
              '• Calendar view\n'
              '• Export laporan\n'
              '• Dark/Light mode',
              style: TextStyle(color: colorScheme.onSurface.withOpacity(0.7)),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }
}

class _ThemeOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;
  final ColorScheme colorScheme;

  const _ThemeOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: selected ? colorScheme.primary.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          color: selected ? colorScheme.primary : colorScheme.onSurface.withOpacity(0.6),
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: selected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 12,
          color: colorScheme.onSurface.withOpacity(0.5),
        ),
      ),
      trailing: selected
          ? Icon(Icons.check_circle_rounded, color: colorScheme.primary)
          : null,
      onTap: onTap,
    );
  }
}

class _SettingsItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final ColorScheme colorScheme;

  const _SettingsItem({
    required this.icon,
    required this.title,
    required this.onTap,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: colorScheme.onSurface.withOpacity(0.7)),
      title: Text(title),
      trailing: Icon(
        Icons.chevron_right_rounded,
        color: colorScheme.onSurface.withOpacity(0.4),
      ),
      onTap: onTap,
    );
  }
}
