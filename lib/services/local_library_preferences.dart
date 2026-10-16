import 'package:shared_preferences/shared_preferences.dart';

class LocalLibraryLocation {
  final String rootUri;
  final String rootName;
  final String currentUri;
  final String currentName;
  final List<String> breadcrumbUris;
  final List<String> breadcrumbNames;

  const LocalLibraryLocation({
    required this.rootUri,
    required this.rootName,
    required this.currentUri,
    required this.currentName,
    required this.breadcrumbUris,
    required this.breadcrumbNames,
  });
}

class LocalLibraryPreferences {
  static const _rootUriKey = 'local_library_root_uri';
  static const _rootNameKey = 'local_library_root_name';
  static const _currentUriKey = 'local_library_current_uri';
  static const _currentNameKey = 'local_library_current_name';
  static const _breadcrumbUrisKey = 'local_library_breadcrumb_uris';
  static const _breadcrumbNamesKey = 'local_library_breadcrumb_names';

  const LocalLibraryPreferences();

  Future<LocalLibraryLocation?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final rootUri = prefs.getString(_rootUriKey);
    final rootName = prefs.getString(_rootNameKey);
    if (rootUri == null || rootName == null) return null;
    final currentUri = prefs.getString(_currentUriKey) ?? rootUri;
    final currentName = prefs.getString(_currentNameKey) ?? rootName;
    final fallbackUris = currentUri == rootUri
        ? [rootUri]
        : [rootUri, currentUri];
    final fallbackNames = currentUri == rootUri
        ? [rootName]
        : [rootName, currentName];
    final breadcrumbUris =
        prefs.getStringList(_breadcrumbUrisKey) ?? fallbackUris;
    final breadcrumbNames =
        prefs.getStringList(_breadcrumbNamesKey) ?? fallbackNames;
    final validBreadcrumbs =
        breadcrumbUris.length == breadcrumbNames.length &&
        breadcrumbUris.isNotEmpty &&
        breadcrumbUris.first == rootUri &&
        breadcrumbUris.last == currentUri &&
        breadcrumbNames.last == currentName;
    return LocalLibraryLocation(
      rootUri: rootUri,
      rootName: rootName,
      currentUri: currentUri,
      currentName: currentName,
      breadcrumbUris: validBreadcrumbs ? breadcrumbUris : fallbackUris,
      breadcrumbNames: validBreadcrumbs ? breadcrumbNames : fallbackNames,
    );
  }

  Future<void> saveRoot({
    required String rootUri,
    required String rootName,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_rootUriKey, rootUri);
    await prefs.setString(_rootNameKey, rootName);
    await prefs.setString(_currentUriKey, rootUri);
    await prefs.setString(_currentNameKey, rootName);
    await prefs.setStringList(_breadcrumbUrisKey, [rootUri]);
    await prefs.setStringList(_breadcrumbNamesKey, [rootName]);
  }

  Future<void> saveCurrent({
    required String currentUri,
    required String currentName,
    required List<String> breadcrumbUris,
    required List<String> breadcrumbNames,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_currentUriKey, currentUri);
    await prefs.setString(_currentNameKey, currentName);
    await prefs.setStringList(_breadcrumbUrisKey, breadcrumbUris);
    await prefs.setStringList(_breadcrumbNamesKey, breadcrumbNames);
  }
}
