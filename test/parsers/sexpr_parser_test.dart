import 'package:flutter_test/flutter_test.dart';
import 'package:kicad_preview/parsers/sexpr_parser.dart';

void main() {
  group('SExprParser - Basic Parsing', () {
    test('parses a simple atom', () {
      final result = SExprParser.parseString('hello');
      expect(result, ['hello']);
    });

    test('parses a number atom', () {
      final result = SExprParser.parseString('42');
      expect(result, ['42']);
    });

    test('parses a decimal atom', () {
      final result = SExprParser.parseString('3.14');
      expect(result, ['3.14']);
    });

    test('parses an empty list', () {
      final result = SExprParser.parseString('()');
      expect(result, [[]]);
    });

    test('parses a simple list', () {
      final result = SExprParser.parseString('(a b c)');
      expect(result, [
        ['a', 'b', 'c'],
      ]);
    });

    test('parses a list with mixed types', () {
      final result = SExprParser.parseString('(key 123 value)');
      expect(result, [
        ['key', '123', 'value'],
      ]);
    });

    test('parses a quoted string', () {
      final result = SExprParser.parseString('("hello world")');
      expect(result, [
        ['hello world'],
      ]);
    });

    test('parses nested lists', () {
      final result = SExprParser.parseString('(a (b c) d)');
      expect(result, [
        ['a', ['b', 'c'], 'd'],
      ]);
    });

    test('parses deeply nested lists', () {
      final result = SExprParser.parseString('(a (b (c d) e) f)');
      expect(result, [
        ['a', ['b', ['c', 'd'], 'e'], 'f'],
      ]);
    });

    test('parses multiple top-level expressions', () {
      final result = SExprParser.parseString('(a b) (c d)');
      expect(result, [
        ['a', 'b'],
        ['c', 'd'],
      ]);
    });

    test('handles empty input', () {
      final result = SExprParser.parseString('');
      expect(result, []);
    });

    test('handles whitespace-only input', () {
      final result = SExprParser.parseString('   \t\n  ');
      expect(result, []);
    });

    test('handles extra whitespace between elements', () {
      final result = SExprParser.parseString('(  a   b    c  )');
      expect(result, [
        ['a', 'b', 'c'],
      ]);
    });

    test('handles newlines between elements', () {
      final result = SExprParser.parseString('(\n\ta\n\tb\n\tc\n)');
      expect(result, [
        ['a', 'b', 'c'],
      ]);
    });
  });

  group('SExprParser - Advanced Parsing', () {
    test('parses a KiCad-like header', () {
      final input = '(kicad_sch\n\t(version 20260306)\n\t(generator "eeschema")\n)';
      final result = SExprParser.parseString(input);
      expect(result.length, 1);
      final root = result[0] as List<dynamic>;
      expect(root[0], 'kicad_sch');
      
      final versionNode = root[1] as List<dynamic>;
      expect(versionNode[0], 'version');
      expect(versionNode[1], '20260306');

      final generatorNode = root[2] as List<dynamic>;
      expect(generatorNode[0], 'generator');
      expect(generatorNode[1], 'eeschema');
    });

    test('parses xy coordinates', () {
      final input = '(pts (xy 165.1 76.2) (xy 228.6 76.2))';
      final result = SExprParser.parseString(input);
      final pts = result[0] as List<dynamic>;
      expect(pts[0], 'pts');
      
      final xy1 = pts[1] as List<dynamic>;
      expect(xy1[0], 'xy');
      expect(xy1[1], '165.1');
      expect(xy1[2], '76.2');
    });

    test('parses stroke style', () {
      final input = '(stroke\n\t(width 0.1524)\n\t(type solid)\n)';
      final result = SExprParser.parseString(input);
      final stroke = result[0] as List<dynamic>;
      expect(stroke[0], 'stroke');
      
      final width = stroke[1] as List<dynamic>;
      expect(width[0], 'width');
      expect(width[1], '0.1524');
    });

    test('parses a complete wire element', () {
      final input = '(wire\n\t(pts\n\t\t(xy 165.1 76.2) (xy 228.6 76.2)\n\t)\n\t(stroke\n\t\t(width 0)\n\t\t(type default)\n\t)\n\t(uuid "051a348b-1569-4714-b2d0-230d78c6edd1")\n)';
      final result = SExprParser.parseString(input);
      final wire = result[0] as List<dynamic>;
      expect(wire[0], 'wire');
      
      final pts = wire[1] as List<dynamic>;
      expect(pts[0], 'pts');
      expect((pts[1] as List<dynamic>)[0], 'xy');

      final uuid = wire[3] as List<dynamic>;
      expect(uuid[0], 'uuid');
      expect(uuid[1], '051a348b-1569-4714-b2d0-230d78c6edd1');
    });

    test('parses string with backslash escaping', () {
      // Parser strips backslash and writes the next character
      final input = '("hello\\nworld")';
      final result = SExprParser.parseString(input);
      final parsed = (result[0] as List<dynamic>)[0] as String;
      expect(parsed, 'hellonworld');
      expect(parsed.contains('\\'), false);
    });
  });

  group('SExprParser - Helper Methods', () {
    test('findFirst finds the first matching item', () {
      final list = [
        ['a', '1'],
        ['b', '2'],
        ['a', '3'],
      ];
      final found = SExprParser.findFirst(list, 'a');
      expect(found, ['a', '1']);
    });

    test('findFirst returns null when not found', () {
      final list = [
        ['a', '1'],
        ['b', '2'],
      ];
      final found = SExprParser.findFirst(list, 'c');
      expect(found, isNull);
    });

    test('findAll finds all matching items', () {
      final list = [
        ['a', '1'],
        ['b', '2'],
        ['a', '3'],
      ];
      final found = SExprParser.findAll(list, 'a');
      expect(found.length, 2);
      expect(found[0][1], '1');
      expect(found[1][1], '3');
    });

    test('findAll returns empty list when not found', () {
      final list = [
        ['a', '1'],
      ];
      final found = SExprParser.findAll(list, 'b');
      expect(found, isEmpty);
    });

    test('getStringValue extracts correct value', () {
      final list = [
        ['name', 'John'],
        ['age', '30'],
      ];
      expect(SExprParser.getStringValue(list, 'name'), 'John');
      expect(SExprParser.getStringValue(list, 'age'), '30');
    });

    test('getStringValue returns null for missing key', () {
      final list = [
        ['name', 'John'],
      ];
      expect(SExprParser.getStringValue(list, 'missing'), isNull);
    });

    test('getStringPairs returns all key-value pairs', () {
      final list = [
        ['prop', 'key1', 'value1'],
        ['prop', 'key2', 'value2'],
      ];
      final pairs = SExprParser.getStringPairs(list, 'prop');
      expect(pairs['key1'], 'value1');
      expect(pairs['key2'], 'value2');
    });

    test('getXY extracts coordinates from xy list', () {
      final list = ['xy', '165.1', '76.2'];
      final xy = SExprParser.getXY(list);
      expect(xy, isNotNull);
      expect(xy!.$1, 165.1);
      expect(xy.$2, 76.2);
    });

    test('getXY extracts coordinates from at list', () {
      final list = ['at', '100.5', '50.25'];
      final xy = SExprParser.getXY(list);
      expect(xy, isNotNull);
      expect(xy!.$1, 100.5);
      expect(xy.$2, 50.25);
    });

    test('getXY returns null for non-coordinate list', () {
      final list = ['color', 'red'];
      expect(SExprParser.getXY(list), isNull);
    });

    test('parseAt extracts coordinates with rotation', () {
      final list = ['at', '10.0', '20.0', '90'];
      final at = SExprParser.parseAt(list);
      expect(at, isNotNull);
      expect(at!.$1, 10.0);
      expect(at.$2, 20.0);
      expect(at.$3, 90.0);
    });

    test('parseAt handles missing rotation', () {
      final list = ['at', '10.0', '20.0'];
      final at = SExprParser.parseAt(list);
      expect(at, isNotNull);
      expect(at!.$1, 10.0);
      expect(at.$2, 20.0);
      expect(at.$3, 0.0);
    });

    test('parseAt returns null for non-at list', () {
      final list = ['pos', '10.0', '20.0'];
      expect(SExprParser.parseAt(list), isNull);
    });
  });

  group('SExprParser - Real KiCad Snippets', () {
    test('parses a junction element', () {
      final input = '(junction\n\t(at 207.01 76.2)\n\t(diameter 0)\n\t(color 0 0 0 0)\n\t(uuid "a4b698d8-c58a-44d3-82ce-74e84d34c90b")\n)';
      final result = SExprParser.parseString(input);
      final junction = result[0] as List<dynamic>;
      expect(junction[0], 'junction');
      
      final at = junction[1] as List<dynamic>;
      expect(at[1], '207.01');
      expect(at[2], '76.2');
    });

    test('parses a sheet with properties and pins', () {
      final input = '(sheet\n\t(at 25.4 123.19)\n\t(size 33.02 36.83)\n\t(uuid "01979eff-2b02-4479-903a-ef1b6c01f12f")\n\t(property "Sheetname" "zigbee"\n\t\t(at 25.4 122.4784 0)\n\t)\n\t(property "Sheetfile" "zigbee.kicad_sch"\n\t\t(at 25.4 160.6046 0)\n\t)\n\t(pin "mclr" input\n\t\t(at 220.98 128.27 180)\n\t)\n)';
      final result = SExprParser.parseString(input);
      final sheet = result[0] as List<dynamic>;
      expect(sheet[0], 'sheet');

      final props = SExprParser.findAll(sheet, 'property');
      expect(props.length, 2);
      expect(props[0][1], 'Sheetname');
      expect(props[0][2], 'zigbee');

      final pins = SExprParser.findAll(sheet, 'pin');
      expect(pins.length, 1);
      expect(pins[0][1], 'mclr');
    });

    test('parses a text element with effects', () {
      final input = '(text "Test Label"\n\t(at 100.0 200.0 0)\n\t(effects\n\t\t(font\n\t\t\t(size 1.27 1.27)\n\t\t)\n\t\t(justify left)\n\t)\n)';
      final result = SExprParser.parseString(input);
      final text = result[0] as List<dynamic>;
      expect(text[0], 'text');
      expect(text[1], 'Test Label');
    });

    test('parses a lib_symbol reference', () {
      final input = '(symbol\n\t(lib_symbol\n\t\t(property "Reference" "R1")\n\t\t(property "Value" "10K")\n\t)\n)';
      final result = SExprParser.parseString(input);
      final symbol = result[0] as List<dynamic>;
      expect(symbol[0], 'symbol');
      
      final libSymbol = SExprParser.findFirst(symbol, 'lib_symbol');
      expect(libSymbol, isNotNull);
      
      final props = SExprParser.findAll(libSymbol!, 'property');
      expect(props.length, 2);
    });
  });

  group('SExprParser - Edge Cases', () {
    test('handles single atom input', () {
      expect(SExprParser.parseString('word'), ['word']);
    });

    test('handles lists with empty nested lists', () {
      final result = SExprParser.parseString('(a () b)');
      expect(result, [
        ['a', [], 'b'],
      ]);
    });

    test('handles multiple empty lists', () {
      final result = SExprParser.parseString('() () ()');
      expect(result, [
        [],
        [],
        [],
      ]);
    });

    test('handles special characters in atoms', () {
      final result = SExprParser.parseString('(net-name_1)');
      expect(result, [
        ['net-name_1'],
      ]);
    });

    test('handles UUID format', () {
      final result = SExprParser.parseString('(uuid "550e8400-e29b-41d4-a716-446655440000")');
      final uuidList = result[0] as List<dynamic>;
      expect(uuidList[1], '550e8400-e29b-41d4-a716-446655440000');
    });

    test('parses expression with tab indentation', () {
      final input = '(kicad_pcb\n\t(version 20260206)\n\t(generator "pcbnew")\n)';
      final result = SExprParser.parseString(input);
      expect(result.length, 1);
      expect((result[0] as List<dynamic>)[0], 'kicad_pcb');
    });

    test('handles very nested structures', () {
      final input = '(a (b (c (d (e (f g))))))';
      final result = SExprParser.parseString(input);
      expect(result.length, 1);
      
      // Traverse to the innermost list [f, g]
      final innerMost = result[0][1][1][1][1][1] as List<dynamic>;
      expect(innerMost[0], 'f');
      expect(innerMost[1], 'g');
      expect(innerMost.length, 2);
    });

    test('handles empty string in quoted string', () {
      final result = SExprParser.parseString('("")');
      expect((result[0] as List<dynamic>)[0], '');
    });
  });
}
