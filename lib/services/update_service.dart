import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class UpdateInfo {
  final String tagName;
  final String title;
  final String body;
  final String releaseUrl;
  final String publishedAt;

  UpdateInfo({
    required this.tagName,
    required this.title,
    required this.body,
    required this.releaseUrl,
    required this.publishedAt,
  });
}

class UpdateService {
  static const String currentVersion = "1.0.0";
  static const String _repo = "qkryt/MaterialVless";

  /// Сравнивает две версии, например "1.1" и "1.0.0" или "2.0" и "1.0.0"
  static bool isNewer(String latest, String current) {
    try {
      final lClean = latest.trim().replaceAll(RegExp(r'^[vV]'), '');
      final cClean = current.trim().replaceAll(RegExp(r'^[vV]'), '');

      final lParts = lClean.split('.').map((e) => int.tryParse(e) ?? 0).toList();
      final cParts = cClean.split('.').map((e) => int.tryParse(e) ?? 0).toList();

      final maxLen = lParts.length > cParts.length ? lParts.length : cParts.length;
      for (int i = 0; i < maxLen; i++) {
        final l = i < lParts.length ? lParts[i] : 0;
        final c = i < cParts.length ? cParts[i] : 0;
        if (l > c) return true;
        if (l < c) return false;
      }
    } catch (_) {}
    return false;
  }

  /// Проверяет наличие обновления через GitHub Releases API
  static Future<UpdateInfo?> checkForUpdate() async {
    try {
      final url = Uri.parse('https://api.github.com/repos/$_repo/releases/latest');
      final response = await http.get(
        url,
        headers: {
          'Accept': 'application/vnd.github.v3+json',
          'User-Agent': 'MaterialVless-App',
        },
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final tagName = data['tag_name'] as String? ?? '';
        final title = data['name'] as String? ?? 'Новая версия';
        final body = data['body'] as String? ?? '';
        final htmlUrl = data['html_url'] as String? ?? 'https://github.com/$_repo/releases';
        final publishedAt = data['published_at'] as String? ?? '';

        if (isNewer(tagName, currentVersion)) {
          return UpdateInfo(
            tagName: tagName,
            title: title,
            body: body,
            releaseUrl: htmlUrl,
            publishedAt: publishedAt,
          );
        }
      }
    } catch (_) {
      // Игнорируем сетевые сбои при проверке
    }
    return null;
  }

  /// Открытие ссылки на релиз в системном браузере
  static void openUrl(String url) {
    try {
      if (Platform.isWindows) {
        Process.run('cmd', ['/c', 'start', '', url]);
      } else if (Platform.isLinux) {
        Process.run('xdg-open', [url]);
      } else if (Platform.isMacOS) {
        Process.run('open', [url]);
      }
    } catch (_) {}
  }

  /// Показ всплывающего окна в Material You (Material 3) дизайне
  static Future<void> showUpdateDialog(BuildContext context, UpdateInfo info) async {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        return AlertDialog(
          icon: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.system_update_rounded,
              color: colorScheme.onPrimaryContainer,
              size: 32,
            ),
          ),
          title: Text(
            'Доступно обновление!',
            textAlign: TextAlign.center,
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420, maxHeight: 320),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Текущая: v$currentVersion',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Icon(Icons.arrow_forward_rounded, size: 16, color: colorScheme.primary),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: colorScheme.primary,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            info.tagName,
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: colorScheme.onPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (info.body.isNotEmpty) ...[
                    Text(
                      'Что нового:',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(
                        info.body.trim(),
                        style: theme.textTheme.bodySmall?.copyWith(height: 1.4),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          actionsAlignment: MainAxisAlignment.end,
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Позже'),
            ),
            FilledButton.icon(
              onPressed: () {
                Navigator.of(ctx).pop();
                openUrl(info.releaseUrl);
              },
              icon: const Icon(Icons.download_rounded, size: 18),
              label: const Text('Скачать'),
              style: FilledButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        );
      },
    );
  }
}
