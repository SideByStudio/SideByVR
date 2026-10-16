import 'package:flutter/services.dart';

class SafDocument {
  final String uri;
  final String name;
  final bool isDirectory;
  final String? mimeType;
  final int? size;
  final int? lastModified;

  const SafDocument({
    required this.uri,
    required this.name,
    required this.isDirectory,
    this.mimeType,
    this.size,
    this.lastModified,
  });

  factory SafDocument.fromMap(Map<Object?, Object?> map) {
    return SafDocument(
      uri: map['uri']! as String,
      name: map['name']! as String,
      isDirectory: map['isDirectory']! as bool,
      mimeType: map['mimeType'] as String?,
      size: (map['size'] as num?)?.toInt(),
      lastModified: (map['lastModified'] as num?)?.toInt(),
    );
  }
}

class SafStorageService {
  static const _channel = MethodChannel('com.sidebyvr.viewer/storage');

  const SafStorageService();

  Future<SafDocument?> pickDirectory({String? initialUri}) async {
    final result = await _channel.invokeMapMethod<Object?, Object?>(
      'pickDirectory',
      {'initialUri': initialUri},
    );
    return result == null ? null : SafDocument.fromMap(result);
  }

  Future<bool> hasPersistedAccess(String uri) async {
    return await _channel.invokeMethod<bool>('hasPersistedAccess', {
          'uri': uri,
        }) ??
        false;
  }

  Future<List<SafDocument>> listChildren(String uri) async {
    final result = await _channel.invokeListMethod<Object?>('listChildren', {
      'uri': uri,
    });
    return (result ?? const [])
        .map((item) => SafDocument.fromMap(item! as Map<Object?, Object?>))
        .toList();
  }

  Future<SafDocument> getDocumentInfo(String uri) async {
    final result = await _channel.invokeMapMethod<Object?, Object?>(
      'getDocumentInfo',
      {'uri': uri},
    );
    if (result == null) throw StateError('Document is no longer available');
    return SafDocument.fromMap(result);
  }

  Future<SafDocument?> getParentDirectory({
    required String rootUri,
    required String currentUri,
  }) async {
    final result = await _channel.invokeMapMethod<Object?, Object?>(
      'getParentDirectory',
      {'rootUri': rootUri, 'currentUri': currentUri},
    );
    return result == null ? null : SafDocument.fromMap(result);
  }

  Future<String> copyDocumentToCache({
    required SafDocument document,
    required String bucket,
    String? fileName,
  }) async {
    final path = await _channel.invokeMethod<String>('copyDocumentToCache', {
      'uri': document.uri,
      'bucket': bucket,
      'fileName': fileName ?? document.name,
    });
    if (path == null) throw StateError('Failed to copy ${document.name}');
    return path;
  }

  Future<void> openExternalUrl(String url) async {
    await _channel.invokeMethod<bool>('openExternalUrl', {'url': url});
  }
}
