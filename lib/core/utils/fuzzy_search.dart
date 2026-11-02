import 'dart:math' as math;

/// Lower-cased letters and digits only, so "EG-0042" matches "eg 0042".
String _compact(String s) =>
    s.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');

List<String> _words(String s) => s
    .toLowerCase()
    .split(RegExp(r'[^a-z0-9]+'))
    .where((w) => w.isNotEmpty)
    .toList();

/// Typos allowed for a query word of [length] characters.
int _allowedTypos(int length) => length <= 3
    ? 0
    : length <= 6
        ? 1
        : 2;

/// Edit distance counting a swap of two neighbouring letters as one typo,
/// giving up once it exceeds [max].
int _distance(String a, String b, int max) {
  if ((a.length - b.length).abs() > max) return max + 1;
  var prev2 = <int>[];
  var prev = List<int>.generate(b.length + 1, (i) => i);
  for (var i = 1; i <= a.length; i++) {
    final cur = List<int>.filled(b.length + 1, 0)..[0] = i;
    var rowMin = cur[0];
    for (var j = 1; j <= b.length; j++) {
      final cost = a.codeUnitAt(i - 1) == b.codeUnitAt(j - 1) ? 0 : 1;
      var d = math.min(
        math.min(cur[j - 1] + 1, prev[j] + 1),
        prev[j - 1] + cost,
      );
      if (i > 1 &&
          j > 1 &&
          a.codeUnitAt(i - 1) == b.codeUnitAt(j - 2) &&
          a.codeUnitAt(i - 2) == b.codeUnitAt(j - 1)) {
        d = math.min(d, prev2[j - 2] + 1);
      }
      cur[j] = d;
      rowMin = math.min(rowMin, d);
    }
    if (rowMin > max) return max + 1;
    prev2 = prev;
    prev = cur;
  }
  return prev[b.length];
}

/// Whether query word [q] is a near-typo of field word [w], or of the
/// start of it (so partly typed words still match).
bool _close(String q, String w) {
  final max = _allowedTypos(q.length);
  if (max == 0) return false;
  if (_distance(q, w, max) <= max) return true;
  return w.length > q.length &&
      _distance(q, w.substring(0, q.length), max) <= max;
}

/// Typo-tolerant search: every word of [query] must appear in one of
/// [fields], ignoring case, spaces and punctuation, or be within one or two
/// typos of a word in them (by word length).
bool fuzzyMatches(String query, Iterable<String?> fields) {
  final tokens = _words(query);
  if (tokens.isEmpty) return true;
  final values = fields.whereType<String>().where((f) => f.isNotEmpty).toList();
  final compacted = values.map(_compact).toList();
  final words = [for (final v in values) ..._words(v)];
  final compactQuery = _compact(query);
  if (compacted.any((f) => f.contains(compactQuery))) return true;
  return tokens.every(
    (t) =>
        compacted.any((f) => f.contains(t)) || words.any((w) => _close(t, w)),
  );
}
