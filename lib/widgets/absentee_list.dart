import 'package:flutter/material.dart';

import '../config/app_config.dart';
import '../models/models.dart';

/// Absentee List Widget
/// 
/// Displays list of employees who are absent today.

class AbsenteeList extends StatelessWidget {
  final List<Absentee> absentees;
  final VoidCallback? onViewAll;

  const AbsenteeList({
    super.key,
    required this.absentees,
    this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainerHighest.withOpacity(0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Color(AppConfig.colorTidakHadir).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.person_off_rounded,
                        color: Color(AppConfig.colorTidakHadir),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Tidak Hadir Hari Ini',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${absentees.length} karyawan',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurface.withOpacity(0.5),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                if (onViewAll != null)
                  TextButton(
                    onPressed: onViewAll,
                    child: const Text('Lihat Semua'),
                  ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // List
            if (absentees.isEmpty)
              _buildEmptyState(theme, colorScheme)
            else
              _buildList(theme, colorScheme),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.celebration_rounded,
              size: 48,
              color: Color(AppConfig.colorHadir).withOpacity(0.5),
            ),
            const SizedBox(height: 12),
            Text(
              'Semua karyawan hadir! 🎉',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildList(ThemeData theme, ColorScheme colorScheme) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: absentees.length > 5 ? 5 : absentees.length,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final absentee = absentees[index];
        return _AbsenteeItem(absentee: absentee);
      },
    );
  }
}

class _AbsenteeItem extends StatelessWidget {
  final Absentee absentee;

  const _AbsenteeItem({required this.absentee});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Generate avatar color from name
    final avatarColor = _getAvatarColor(absentee.nama);
    final initials = _getInitials(absentee.nama);

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 4),
      leading: CircleAvatar(
        backgroundColor: avatarColor.withOpacity(0.2),
        foregroundColor: avatarColor,
        child: Text(
          initials,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      title: Text(
        absentee.nama,
        style: theme.textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        'NIK: ${absentee.nik}',
        style: theme.textTheme.bodySmall?.copyWith(
          color: colorScheme.onSurface.withOpacity(0.5),
        ),
      ),
      trailing: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 10,
          vertical: 4,
        ),
        decoration: BoxDecoration(
          color: Color(AppConfig.colorTidakHadir).withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          'Tidak Hadir',
          style: theme.textTheme.labelSmall?.copyWith(
            color: Color(AppConfig.colorTidakHadir),
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[parts.length - 1][0]}'.toUpperCase();
  }

  Color _getAvatarColor(String name) {
    final colors = [
      Colors.blue,
      Colors.purple,
      Colors.teal,
      Colors.orange,
      Colors.pink,
      Colors.indigo,
      Colors.cyan,
      Colors.amber,
    ];
    
    final hash = name.codeUnits.fold(0, (prev, curr) => prev + curr);
    return colors[hash % colors.length];
  }
}
