import 'dart:convert';
import 'dart:io';

bool _hasLikelyMojibake(String s) {
  return s.contains('?') ||
      s.contains('?') ||
      s.contains('?') ||
      s.contains('?') ||
      s.contains('?') ||
      s.contains('?') ||
      s.contains('???') ||
      s.contains('?') ||
      s.contains('?');
}

String _tryDecodeLatin1Utf8(String s) {
  if (!_hasLikelyMojibake(s)) return s;
  for (final codeUnit in s.codeUnits) {
    if (codeUnit > 255) return s;
  }
  try {
    final decoded = utf8.decode(latin1.encode(s), allowMalformed: false);
    return decoded;
  } catch (_) {
    return s;
  }
}

String _repairLine(String line) {
  var next = _tryDecodeLatin1Utf8(line);
  for (var i = 0; i < 3; i++) {
    final decoded = _tryDecodeLatin1Utf8(next);
    if (decoded == next) break;
    next = decoded;
  }
  return next;
}

void main() {
  final dir = Directory('lib/views/home');
  final files = dir
      .listSync()
      .whereType<File>()
      .where((f) => f.path.endsWith('_request_page.dart'));
  for (final file in files) {
    final lines = file.readAsLinesSync(encoding: utf8);
    final repaired = lines.map(_repairLine).toList();
    file.writeAsStringSync(repaired.join('\n'), encoding: utf8);
  }
}
