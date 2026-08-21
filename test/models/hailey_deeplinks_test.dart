import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:smoking/constants/hailey_deeplinks.dart';

void main() {
  test('every canonical Hailey deep link resolves to an executable target', () {
    final canonical = (jsonDecode(
      File('rag_backend2.0/app/data/hailey_deeplinks.json').readAsStringSync(),
    ) as List).cast<String>().toSet();
    expect(haileyDeeplinkRegistry.keys.toSet(), canonical);
    for (final uri in canonical) {
      expect(resolveHaileyDeeplink(uri), isNotNull, reason: uri);
    }
  });

  test('unknown Hailey deep links are rejected', () {
    expect(resolveHaileyDeeplink('xhale://doctor-visit'), isNull);
  });
}
