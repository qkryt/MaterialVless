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
  final String? setupDownloadUrl;

  UpdateInfo({
    required this.tagName,
    required this.title,
    required this.body,
    required this.releaseUrl,
    required this.publishedAt,
    this.setupDownloadUrl,
  });
}

class CheckUpdateResult {
  final bool hasUpdate;
  final bool isSuccess;
  final UpdateInfo? updateInfo;
  final String latestTagName;
  final String? errorMessage;

  CheckUpdateResult({
    required this.hasUpdate,
    required this.isSuccess,
    this.updateInfo,
    this.latestTagName = '',
    this.errorMessage,
  });
}

class UpdateService {
  static const String currentVersion = "2.16.1";
  static const String _repo = "qkryt/MaterialVless";

  /// Сравнивает две версии, например "2.1" и "2.0.0" или "2.1.0" и "2.0.0"
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

  /// Детальная проверка наличия обновления с возвратом статуса
  static Future<CheckUpdateResult> checkDetailedUpdate() async {
    try {
      final url = Uri.parse('https://api.github.com/repos/$_repo/releases/latest');
      final response = await http.get(
        url,
        headers: {
          'Accept': 'application/vnd.github.v3+json',
          'User-Agent': 'MaterialVless-App/2.16.1',
        },
      ).timeout(const Duration(seconds: 6));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final tagName = data['tag_name'] as String? ?? '';
        final title = data['name'] as String? ?? 'MaterialVless $tagName';
        final body = data['body'] as String? ?? '';
        final htmlUrl = data['html_url'] as String? ?? 'https://github.com/$_repo/releases';
        final publishedAt = data['published_at'] as String? ?? '';

        String? setupUrl;
        final assets = data['assets'] as List<dynamic>? ?? [];
        for (final a in assets) {
          final name = a['name']?.toString() ?? '';
          if (name.contains('Setup.exe') || (name.endsWith('.exe') && name.contains('Windows-x64'))) {
            setupUrl = a['browser_download_url']?.toString();
            break;
          }
        }

        final info = UpdateInfo(
          tagName: tagName,
          title: title,
          body: body,
          releaseUrl: htmlUrl,
          publishedAt: publishedAt,
          setupDownloadUrl: setupUrl,
        );

        final bool newer = isNewer(tagName, currentVersion);
        return CheckUpdateResult(
          hasUpdate: newer,
          isSuccess: true,
          updateInfo: info,
          latestTagName: tagName,
        );
      } else {
        return CheckUpdateResult(
          hasUpdate: false,
          isSuccess: false,
          errorMessage: 'Ошибка сервера GitHub: код ${response.statusCode}',
        );
      }
    } catch (e) {
      return CheckUpdateResult(
        hasUpdate: false,
        isSuccess: false,
        errorMessage: 'Ошибка сети: $e',
      );
    }
  }

  /// Проверяет наличие обновления через GitHub Releases API
  static Future<UpdateInfo?> checkForUpdate() async {
    final result = await checkDetailedUpdate();
    if (result.hasUpdate && result.updateInfo != null) {
      return result.updateInfo;
    }
    return null;
  }

  /// Скачивание установщика .exe и запуск с последующим закрытием программы
  static Future<void> downloadAndLaunchInstaller(
    BuildContext context,
    String setupUrl,
  ) async {
    double progress = 0.0;
    int downloadedBytes = 0;
    int totalBytes = 0;
    bool isCancelled = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setProgressState) {
            return AlertDialog(
              title: const Text('Загрузка обновления...'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  LinearProgressIndicator(value: progress > 0 ? progress : null),
                  const SizedBox(height: 14),
                  Text(
                    totalBytes > 0
                        ? '${(downloadedBytes / (1024 * 1024)).toStringAsFixed(1)} MB / ${(totalBytes / (1024 * 1024)).toStringAsFixed(1)} MB (${(progress * 100).toStringAsFixed(0)}%)'
                        : 'Подготовка к загрузке...',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    isCancelled = true;
                    Navigator.pop(ctx);
                  },
                  child: const Text('Отмена'),
                ),
              ],
            );
          },
        );
      },
    );

    try {
      final request = http.Request('GET', Uri.parse(setupUrl));
      request.headers['User-Agent'] = 'MaterialVless-App/2.16.1';
      final response = await http.Client().send(request);

      totalBytes = response.contentLength ?? 0;
      final tempDir = Directory.systemTemp.path;
      final installerPath = '$tempDir\\MaterialVless-Update-Setup.exe';
      final file = File(installerPath);
      final sink = file.openWrite();

      await for (final chunk in response.stream) {
        if (isCancelled) {
          await sink.close();
          if (await file.exists()) await file.delete();
          return;
        }
        sink.add(chunk);
        downloadedBytes += chunk.length;
        if (totalBytes > 0) {
          progress = downloadedBytes / totalBytes;
        }
      }

      await sink.close();

      if (!isCancelled && await file.exists()) {
        // Запуск установщика в фоновом режиме
        await Process.start(installerPath, [], mode: ProcessStartMode.detached);
        // Немедленное закрытие текущего рабочего инстанса
        exit(0);
      }
    } catch (e) {
      debugPrint('Error downloading installer: $e');
    }
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
                      color: colorScheme.surfaceContainerHighest.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: colorScheme.outlineVariant.withOpacity(0.4)),
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
            if (info.setupDownloadUrl != null && Platform.isWindows)
              FilledButton.icon(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  downloadAndLaunchInstaller(context, info.setupDownloadUrl!);
                },
                icon: const Icon(Icons.install_desktop_rounded, size: 18),
                label: const Text('Обновить сейчас'),
                style: FilledButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              )
            else
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
