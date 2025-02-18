import 'dart:io';

import 'package:analyzer/file_system/physical_file_system.dart';

String toPackagePath(
  String path,
) {
  final normalizedPath = _normalizePath(path);
  final reg = RegExp('\/(lib|test)\/(.*)');
  final packagedPath = reg.firstMatch(normalizedPath)?.group(2);
  final isTest = reg.firstMatch(normalizedPath)?.group(1) == 'test';
  final result = packagedPath ?? normalizedPath;
  return isTest ? 'test/$result' : result;
}

String _normalizePath(String path) {
  final separator = Platform.pathSeparator;
  return path.replaceAll(separator, '/');
}

String absoluteNormalizedPath(String path) {
  final pathContext = PhysicalResourceProvider.INSTANCE.pathContext;
  return pathContext.normalize(
    pathContext.absolute(path),
  );
}

String? extractPackage(String source) {
  final packageRegExpResult =
      RegExp('(?<=package:).*?(?=\/)').stringMatch(source);

  return packageRegExpResult;
}

const int $backslash = 0x5c;

const int $pipe = 0x7c;
