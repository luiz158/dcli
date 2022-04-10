import 'dart:async';

import 'package:dcli_core/dcli_core.dart';
import 'package:test/test.dart';

void main() {
  test('withTempDir - check action is awaited.', () async {
    final c = Completer<bool>();
    await withTempDir((dir) async {
      await Future.delayed(const Duration(seconds: 2), () => c.complete(true));
    });

    expect(c.isCompleted, isTrue);
  });
}