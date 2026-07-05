import 'dart:io';

/// A simple S-expression parser for KiCad files.
/// KiCad files use Lisp-like S-expressions: (key value1 value2 ...)
class SExprParser {
  final String input;
  int pos = 0;

  SExprParser(this.input);

  void _skipWhitespace() {
    while (pos < input.length) {
      final c = input[pos];
      if (c == ' ' || c == '\t' || c == '\n' || c == '\r') {
        pos++;
      } else {
        break;
      }
    }
  }

  String? _peek() {
    _skipWhitespace();
    if (pos < input.length) {
      return input[pos];
    }
    return null;
  }

  String _consume() {
    return input[pos++];
  }

  /// Returns true if we are at the end of input or at a closing paren.
  bool get isAtEnd {
    _skipWhitespace();
    return pos >= input.length || input[pos] == ')';
  }

  /// Parse a single S-expression node.
  /// Returns either a String (atom) or List<dynamic> (list).
  dynamic parse() {
    _skipWhitespace();
    if (pos >= input.length) return null;

    if (input[pos] == '(') {
      return _parseList();
    } else if (input[pos] == '"') {
      return _parseString();
    } else {
      return _parseAtom();
    }
  }

  List<dynamic> _parseList() {
    pos++; // skip '('
    final list = <dynamic>[];
    while (pos < input.length) {
      _skipWhitespace();
      if (pos >= input.length) break;
      if (input[pos] == ')') {
        pos++; // skip ')'
        return list;
      }
      list.add(parse());
    }
    return list;
  }

  String _parseString() {
    pos++; // skip opening "
    final buf = StringBuffer();
    while (pos < input.length) {
      final c = input[pos];
      if (c == '\\') {
        pos++;
        if (pos < input.length) {
          buf.write(input[pos]);
          pos++;
        }
      } else if (c == '"') {
        pos++; // skip closing "
        return buf.toString();
      } else {
        buf.write(c);
        pos++;
      }
    }
    return buf.toString();
  }

  String _parseAtom() {
    final buf = StringBuffer();
    while (pos < input.length) {
      final c = input[pos];
      if (c == ' ' || c == '\t' || c == '\n' || c == '\r' || c == '(' || c == ')' || c == '"') {
        break;
      }
      buf.write(c);
      pos++;
    }
    return buf.toString();
  }

  /// Parse the entire content and return the top-level list.
  List<dynamic> parseAll() {
    final results = <dynamic>[];
    while (!isAtEnd) {
      final result = parse();
      if (result != null) {
        results.add(result);
      }
    }
    return results;
  }

  /// Helper: find a list by its first element (the "type").
  static List<dynamic>? findFirst(List<dynamic> list, String type) {
    for (final item in list) {
      if (item is List<dynamic> && item.isNotEmpty && item[0] == type) {
        return item;
      }
    }
    return null;
  }

  /// Helper: find all lists with a given first element.
  static List<List<dynamic>> findAll(List<dynamic> list, String type) {
    final results = <List<dynamic>>[];
    for (final item in list) {
      if (item is List<dynamic> && item.isNotEmpty && item[0] == type) {
        results.add(item);
      }
    }
    return results;
  }

  /// Helper: get a string value from a list (e.g., ["key", "value"]).
  static String? getStringValue(List<dynamic> list, String key) {
    for (final item in list) {
      if (item is List<dynamic> && item.length >= 2 && item[0] == key) {
        return item[1].toString();
      }
    }
    return null;
  }

  /// Helper: get all string pairs (key-value).
  static Map<String, String> getStringPairs(List<dynamic> list, String key) {
    final map = <String, String>{};
    for (final item in list) {
      if (item is List<dynamic> && item.length >= 2 && item[0] == key) {
        map[item[1].toString()] = item.length > 2 ? item[2].toString() : '';
      }
    }
    return map;
  }

  /// Helper: extract xy coordinates from a list.
  static (double, double)? getXY(List<dynamic> list) {
    if (list.length >= 3 && list[0] == 'xy') {
      return (double.tryParse(list[1].toString()) ?? 0,
              double.tryParse(list[2].toString()) ?? 0);
    }
    // Also try (at x y)
    if (list.length >= 3 && list[0] == 'at') {
      return (double.tryParse(list[1].toString()) ?? 0,
              double.tryParse(list[2].toString()) ?? 0);
    }
    return null;
  }

  /// Helper: parse coordinate values from (at x y [rotation]).
  static (double, double, double)? parseAt(List<dynamic> list) {
    if (list.length >= 3 && list[0] == 'at') {
      final x = double.tryParse(list[1].toString()) ?? 0;
      final y = double.tryParse(list[2].toString()) ?? 0;
      final rot = list.length > 3 ? double.tryParse(list[3].toString()) ?? 0 : 0.0;
      return (x, y, rot);
    }
    return null;
  }

  /// Load and parse a KiCad file.
  static Future<List<dynamic>> parseFile(String path) async {
    final file = File(path);
    final content = await file.readAsString();
    final parser = SExprParser(content);
    return parser.parseAll();
  }

  /// Parse a string content directly.
  static List<dynamic> parseString(String content) {
    final parser = SExprParser(content);
    return parser.parseAll();
  }
}
