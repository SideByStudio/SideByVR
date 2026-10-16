import 'package:sidebyvr/services/local_library_preferences.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  const preferences = LocalLibraryPreferences();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('保存并恢复准确浏览位置与完整路径', () async {
    await preferences.saveRoot(
      rootUri: 'content://library/root',
      rootName: 'SBS Library',
    );
    await preferences.saveCurrent(
      currentUri: 'content://library/root/album',
      currentName: 'Album',
      breadcrumbUris: const [
        'content://library/root',
        'content://library/root/album',
      ],
      breadcrumbNames: const ['SBS Library', 'Album'],
    );

    final location = await preferences.load();

    expect(location, isNotNull);
    expect(location!.currentUri, 'content://library/root/album');
    expect(location.currentName, 'Album');
    expect(location.breadcrumbUris, [
      'content://library/root',
      'content://library/root/album',
    ]);
    expect(location.breadcrumbNames, ['SBS Library', 'Album']);
  });

  test('路径记录与当前位置不一致时重建最短可用路径', () async {
    SharedPreferences.setMockInitialValues({
      'local_library_root_uri': 'content://library/root',
      'local_library_root_name': 'SBS Library',
      'local_library_current_uri': 'content://library/root/moved',
      'local_library_current_name': 'Moved',
      'local_library_breadcrumb_uris': <String>[
        'content://library/root',
        'content://library/root/other',
      ],
      'local_library_breadcrumb_names': <String>['SBS Library', 'Other'],
    });

    final location = await preferences.load();

    expect(location, isNotNull);
    expect(location!.breadcrumbUris, [
      'content://library/root',
      'content://library/root/moved',
    ]);
    expect(location.breadcrumbNames, ['SBS Library', 'Moved']);
  });
}
