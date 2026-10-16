import 'dart:convert';
import 'dart:io';

import 'package:archive/archive_io.dart';

import '../models/media_item.dart';

class ZipExtractor {
  static const _manifestName = '.sideby-manifest.json';
  static const _maxMediaFiles = 2000;
  static const _maxUncompressedBytes = 2 * 1024 * 1024 * 1024;

  static Future<List<MediaItem>> extract({
    required String zipPath,
    required String destinationPath,
  }) async {
    final destination = Directory(destinationPath);
    final cached = await _readCache(destination);
    if (cached != null) return cached;

    if (await destination.exists()) {
      await destination.delete(recursive: true);
    }
    await destination.create(recursive: true);

    final input = InputFileStream(zipPath);
    try {
      final archive = ZipDecoder().decodeBuffer(input);
      final files =
          archive.files.where((entry) {
            return entry.isFile &&
                _safeRelativeName(entry.name) != null &&
                isSbsMediaName(entry.name);
          }).toList()..sort(
            (left, right) =>
                left.name.toLowerCase().compareTo(right.name.toLowerCase()),
          );

      if (files.isEmpty) {
        throw StateError('No SBS media found in ZIP');
      }
      if (files.length > _maxMediaFiles) {
        throw StateError(
          'ZIP contains too many SBS media files '
          '(${files.length} > $_maxMediaFiles)',
        );
      }
      final totalBytes = files.fold<int>(
        0,
        (total, entry) => total + entry.size,
      );
      if (totalBytes > _maxUncompressedBytes) {
        throw StateError('ZIP expands beyond the 2 GB safety limit');
      }

      final manifest = <Map<String, Object?>>[];
      for (var index = 0; index < files.length; index++) {
        final entry = files[index];
        final relativeName = _safeRelativeName(entry.name)!;
        final baseName = relativeName.split('/').last;
        final outputName =
            '${(index + 1).toString().padLeft(4, '0')}_${_safeFileName(baseName)}';
        final outputPath =
            '${destination.path}${Platform.pathSeparator}$outputName';
        final output = OutputFileStream(outputPath);
        try {
          entry.writeContent(output);
        } finally {
          await output.close();
        }
        manifest.add({
          'name': relativeName,
          'path': outputPath,
          'size': entry.size,
        });
      }

      await File(
        '${destination.path}${Platform.pathSeparator}$_manifestName',
      ).writeAsString(jsonEncode(manifest), flush: true);
      return _mediaFromManifest(manifest);
    } catch (_) {
      if (await destination.exists()) {
        await destination.delete(recursive: true);
      }
      rethrow;
    } finally {
      await input.close();
    }
  }

  static Future<List<MediaItem>?> _readCache(Directory destination) async {
    final manifestFile = File(
      '${destination.path}${Platform.pathSeparator}$_manifestName',
    );
    if (!await manifestFile.exists()) return null;
    try {
      final decoded = jsonDecode(await manifestFile.readAsString()) as List;
      final manifest = decoded.cast<Map<String, dynamic>>();
      final allExist = manifest.every(
        (item) => File(item['path']! as String).existsSync(),
      );
      return allExist ? _mediaFromManifest(manifest) : null;
    } catch (_) {
      return null;
    }
  }

  static List<MediaItem> _mediaFromManifest(
    List<Map<String, dynamic>> manifest,
  ) {
    return manifest.map((item) {
      return MediaItem.cached(
        displayName: item['name']! as String,
        localPath: item['path']! as String,
        size: (item['size'] as num?)?.toInt(),
      );
    }).toList();
  }

  static String? _safeRelativeName(String rawName) {
    final normalized = rawName.replaceAll('\\', '/');
    if (normalized.startsWith('/')) return null;
    final segments = normalized.split('/');
    if (segments.any((segment) => segment == '..' || segment.isEmpty)) {
      return null;
    }
    return normalized;
  }

  static String _safeFileName(String name) {
    final cleaned = name
        .replaceAll(RegExp(r'[\\/:*?"<>|\x00-\x1F]'), '_')
        .replaceAll('..', '_')
        .trim();
    return cleaned.isEmpty ? 'media' : cleaned;
  }
}
