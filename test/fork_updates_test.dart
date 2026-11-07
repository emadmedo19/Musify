import 'package:flutter_test/flutter_test.dart';
import 'package:musify/utilities/fork_updates.dart';

void main() {
  Map<String, dynamic> release({
    String host = 'github.com',
    bool prerelease = false,
    String repository = forkRepository,
  }) => {
    'draft': false,
    'prerelease': prerelease,
    'tag_name': 'v10.7.0',
    'body': 'Release notes',
    'assets': [
      {
        'name': forkApkAssetName,
        'browser_download_url':
            'https://$host/$repository/releases/download/v10.7.0/$forkApkAssetName',
      },
    ],
  };
  test('updates resolve only this fork published universal signed asset', () {
    final update = parseForkUpdate(release());
    expect(update?.version, '10.7.0');
    expect(update?.downloadUrl.host, 'github.com');
    expect(update?.notes, 'Release notes');
  });
  test('upstream, external, draft, prerelease and missing assets cannot replace the fork', () {
    expect(parseForkUpdate(release(repository: 'gokadzev/Musify')), isNull);
    expect(parseForkUpdate(release(host: 'example.com')), isNull);
    expect(parseForkUpdate(release(prerelease: true)), isNull);
    expect(parseForkUpdate({...release(), 'draft': true}), isNull);
    expect(parseForkUpdate({...release(), 'assets': []}), isNull);
    expect(parseForkUpdate({'message': 'Not Found'}), isNull);
  });
  test('version parsing handles malformed service data without crashing', () {
    expect(isNewerForkVersion('10.6.2', '10.7.0'), isTrue);
    expect(isNewerForkVersion('10.7.0', '10.7.0'), isFalse);
    expect(isNewerForkVersion('10.7.0', '10.6.2'), isFalse);
    expect(isNewerForkVersion('10.7.0', 'broken'), isFalse);
    expect(parseForkUpdate({...release(), 'tag_name': 'master'}), isNull);
  });
}
