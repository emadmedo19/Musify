const forkRepository = 'emadmedo19/Musify';
const forkReleasesApi =
    'https://api.github.com/repos/$forkRepository/releases/latest';
const forkApkAssetName = 'Musify-Arabic.apk';

class ForkUpdate {
  const ForkUpdate(this.version, this.downloadUrl, this.notes);
  final String version;
  final Uri downloadUrl;
  final String notes;
}

/// Only stable, published releases with an APK belonging to this repository.
ForkUpdate? parseForkUpdate(dynamic data) {
  if (data is! Map || data['draft'] != false || data['prerelease'] != false)
    return null;
  final version =
      data['tag_name']?.toString().replaceFirst(RegExp('^v'), '') ?? '';
  if (!RegExp(r'^\d+\.\d+\.\d+$').hasMatch(version)) return null;
  final assets = data['assets'];
  if (assets is! List) return null;
  for (final asset in assets.whereType<Map>()) {
    if (asset['name'] != forkApkAssetName) continue;
    final uri = Uri.tryParse(asset['browser_download_url']?.toString() ?? '');
    if (uri == null ||
        uri.scheme != 'https' ||
        uri.host != 'github.com' ||
        !uri.path.startsWith('/$forkRepository/releases/download/') ||
        !uri.path.endsWith('/$forkApkAssetName'))
      continue;
    return ForkUpdate(version, uri, data['body']?.toString() ?? '');
  }
  return null;
}

bool isNewerForkVersion(String current, String candidate) {
  List<int>? parse(String version) {
    if (!RegExp(r'^\d+\.\d+\.\d+$').hasMatch(version)) return null;
    return version.split('.').map(int.parse).toList();
  }

  final a = parse(current);
  final b = parse(candidate);
  if (a == null || b == null) return false;
  for (var i = 0; i < 3; i++) {
    if (b[i] != a[i]) return b[i] > a[i];
  }
  return false;
}
