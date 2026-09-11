import 'dart:convert';

import 'package:flutter/services.dart';

/// Serves a 1×1 transparent PNG for every asset request so widgets that use
/// `Image.asset` / `AssetImage` can be pumped without the real image files
/// (which are not in the repository).
class FakeAssetBundle extends CachingAssetBundle {
  static final Uint8List _png = base64Decode(
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==',
  );

  @override
  Future<ByteData> load(String key) async {
    if (key == 'AssetManifest.bin') {
      return const StandardMessageCodec().encodeMessage(<String, Object>{})!;
    }
    if (key == 'AssetManifest.json' || key == 'FontManifest.json') {
      return ByteData.sublistView(utf8.encode('{}'));
    }
    return ByteData.sublistView(_png);
  }
}
