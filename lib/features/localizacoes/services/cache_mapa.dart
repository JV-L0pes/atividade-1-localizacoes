import 'dart:io';

import 'package:flutter_map/flutter_map.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

Future<void> prepararCacheMapa() async {
  final raiz = await getApplicationCacheDirectory();
  final pasta = Directory(p.join(raiz.path, 'mapa'));
  await Directory(p.join(pasta.path, 'fm_cache')).create(recursive: true);
  BuiltInMapCachingProvider.getOrCreateInstance(
    cacheDirectory: pasta.path,
    maxCacheSize: 50 * 1024 * 1024,
  );
}
