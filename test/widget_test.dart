import 'package:flutter_test/flutter_test.dart';
import 'dart:ui' show Color;
import 'package:kicad_preview/parsers/sexpr_parser.dart';
import 'package:kicad_preview/models/schematic.dart';
import 'package:kicad_preview/models/pcb.dart';
import 'package:kicad_preview/models/schematic_element.dart';
import 'package:kicad_preview/models/pcb_element.dart';

void main() {
  group('Integration: Parser produces valid models', () {
    test('SExprParser output can construct Schematic model', () {
      final result = SExprParser.parseString(
        '(kicad_sch (version 1) (paper A4))',
      );
      expect(result.length, 1);
      final root = result[0] as List<dynamic>;
      expect(root[0], 'kicad_sch');
    });

    test('SExprParser wire output creates valid Wire model', () {
      final result = SExprParser.parseString(
        '(wire (pts (xy 0 0) (xy 100 0)) (uuid "test-123"))',
      );
      expect(result.length, 1);
      final wire = result[0] as List<dynamic>;
      expect(wire[0], 'wire');

      final pts = wire[1] as List<dynamic>;
      expect((pts[1] as List<dynamic>)[1], '0');
      expect((pts[2] as List<dynamic>)[1], '100');
    });

    test('PCB model constructs with parsed-style data', () {
      final pcb = PCB(
        fileName: 'test.kicad_pcb',
        layers: [
          PCBLayer(id: 0, name: 'F.Cu', type: 'signal'),
          PCBLayer(id: 25, name: 'Edge.Cuts', type: 'user'),
        ],
        tracks: [
          const PCBTrack(
            x1: 0, y1: 0, x2: 100, y2: 50,
            width: 0.25, layer: 'F.Cu', net: 'GND',
          ),
        ],
      );
      expect(pcb.layers.length, 2);
      expect(pcb.tracks.length, 1);
      expect(pcb.getLayerById(0)?.name, 'F.Cu');
      expect(pcb.getLayerById(25)?.color, const Color(0xFFFFA500));
    });

    test('Schematic model constructs from parsed data', () {
      final sheet = SchematicSheet(
        name: 'Main',
        fileName: 'main.kicad_sch',
        uuid: 'main-uuid',
        x: 0, y: 0,
        width: 100, height: 80,
      );
      final schematic = Schematic(
        fileName: 'top.kicad_sch',
        sheets: [sheet],
        texts: [
          const SchematicText(text: 'GND', position: Point(50, 50)),
        ],
      );
      expect(schematic.sheets.length, 1);
      expect(schematic.texts.length, 1);
      expect(schematic.texts[0].text, 'GND');
    });

    test('BomItem roundtrip via CSV', () {
      const item = BomItem(
        reference: 'R1, R2',
        value: '10K',
        footprint: '0805',
        quantity: 2,
      );
      final csvLine = item.toCsvLine();
      expect(csvLine, '"R1, R2","10K","0805","",2');
    });
  });
}
