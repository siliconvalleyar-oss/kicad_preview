import 'package:flutter_test/flutter_test.dart';
import 'package:kicad_preview/models/schematic.dart';
import 'package:kicad_preview/models/schematic_element.dart';
import 'package:flutter/material.dart' show Color;

void main() {
  group('Point', () {
    test('creates a Point with x and y coordinates', () {
      final point = Point(10.5, 20.3);
      expect(point.x, 10.5);
      expect(point.y, 20.3);
    });

    test('toString returns formatted string', () {
      final point = Point(1.0, 2.0);
      expect(point.toString(), 'Point(1.0, 2.0)');
    });

    test('const constructor works', () {
      const point = Point(0, 0);
      expect(point.x, 0);
      expect(point.y, 0);
    });
  });

  group('SchematicElementType', () {
    test('contains all expected types', () {
      expect(SchematicElementType.values.length, 8);
      expect(SchematicElementType.values, containsAll([
        SchematicElementType.wire,
        SchematicElementType.junction,
        SchematicElementType.symbol,
        SchematicElementType.label,
        SchematicElementType.text,
        SchematicElementType.sheet,
        SchematicElementType.noConnect,
        SchematicElementType.bus,
      ]));
    });
  });

  group('SchematicElement', () {
    test('creates a wire element', () {
      final element = const SchematicElement(
        type: SchematicElementType.wire,
        uuid: 'test-uuid',
        points: [Point(0, 0), Point(10, 10)],
        strokeWidth: 0.3,
      );
      expect(element.type, SchematicElementType.wire);
      expect(element.uuid, 'test-uuid');
      expect(element.points.length, 2);
      expect(element.strokeWidth, 0.3);
    });

    test('creates a sheet element with pins', () {
      final element = SchematicElement(
        type: SchematicElementType.sheet,
        sheetName: 'MCU',
        sheetFile: 'mcu.kicad_sch',
        pins: [
          const SheetPin(
            name: 'RXD',
            type: 'input',
            position: Point(10, 20),
            rotation: 180,
          ),
        ],
      );
      expect(element.sheetName, 'MCU');
      expect(element.sheetFile, 'mcu.kicad_sch');
      expect(element.pins.length, 1);
      expect(element.pins[0].name, 'RXD');
    });

    test('creates an element with properties', () {
      final element = const SchematicElement(
        type: SchematicElementType.symbol,
        text: 'R1 (10K)',
        properties: {'Reference': 'R1', 'Value': '10K'},
      );
      expect(element.properties['Reference'], 'R1');
      expect(element.properties['Value'], '10K');
    });

    test('copyWith creates a modified copy', () {
      const original = SchematicElement(
        type: SchematicElementType.wire,
        uuid: 'original',
        strokeWidth: 0.1,
      );
      final modified = original.copyWith(
        uuid: 'modified',
        strokeWidth: 0.5,
      );
      expect(modified.uuid, 'modified');
      expect(modified.strokeWidth, 0.5);
      expect(modified.type, SchematicElementType.wire);
      expect(original.uuid, 'original');
    });

    test('default values are set correctly', () {
      const element = SchematicElement(type: SchematicElementType.junction);
      expect(element.points, []);
      expect(element.strokeWidth, 0);
      expect(element.color, Color(0xFF000000));
      expect(element.pins, []);
      expect(element.properties, {});
      expect(element.uuid, isNull);
      expect(element.text, isNull);
    });
  });

  group('SheetPin', () {
    test('creates a SheetPin with all fields', () {
      const pin = SheetPin(
        name: 'TX',
        type: 'output',
        position: Point(100, 200),
        rotation: 90,
      );
      expect(pin.name, 'TX');
      expect(pin.type, 'output');
      expect(pin.position.x, 100);
      expect(pin.position.y, 200);
      expect(pin.rotation, 90);
    });
  });

  group('Junction', () {
    test('creates a Junction', () {
      const junction = Junction(
        position: Point(50, 75),
        uuid: 'junction-uuid',
      );
      expect(junction.position.x, 50);
      expect(junction.position.y, 75);
      expect(junction.uuid, 'junction-uuid');
    });

    test('uuid can be null', () {
      const junction = Junction(position: Point(0, 0));
      expect(junction.uuid, isNull);
    });
  });

  group('Wire', () {
    test('creates a Wire with multiple points', () {
      final wire = Wire(
        points: [
          const Point(0, 0),
          const Point(100, 0),
          const Point(100, 50),
        ],
        width: 0.3,
        uuid: 'wire-uuid',
      );
      expect(wire.points.length, 3);
      expect(wire.width, 0.3);
      expect(wire.uuid, 'wire-uuid');
    });
  });

  group('SchematicText', () {
    test('creates a SchematicText with default values', () {
      const text = SchematicText(
        text: 'GND',
        position: Point(50, 50),
      );
      expect(text.text, 'GND');
      expect(text.size, 1.27);
      expect(text.rotation, 0);
      expect(text.italic, false);
      expect(text.bold, false);
    });

    test('creates a SchematicText with all fields', () {
      const text = SchematicText(
        text: 'VCC',
        position: Point(10, 20),
        size: 2.0,
        rotation: 90,
        italic: true,
        bold: true,
      );
      expect(text.text, 'VCC');
      expect(text.size, 2.0);
      expect(text.rotation, 90);
      expect(text.italic, true);
      expect(text.bold, true);
    });
  });

  group('Schematic', () {
    test('creates a Schematic with required fileName', () {
      const schematic = Schematic(fileName: 'test.kicad_sch');
      expect(schematic.fileName, 'test.kicad_sch');
      expect(schematic.version, '');
      expect(schematic.generator, '');
      expect(schematic.paper, 'A4');
      expect(schematic.elements, []);
      expect(schematic.sheets, []);
      expect(schematic.junctions, []);
      expect(schematic.wires, []);
      expect(schematic.texts, []);
    });

    test('creates a Schematic with all fields', () {
      final schematic = Schematic(
        fileName: 'project.kicad_sch',
        version: '20260306',
        generator: 'eeschema',
        paper: 'A3',
        elements: [
          const SchematicElement(type: SchematicElementType.wire),
          const SchematicElement(type: SchematicElementType.junction),
        ],
        sheets: [
          const SchematicSheet(
            name: 'MCU',
            fileName: 'mcu.kicad_sch',
            uuid: 'sheet-uuid',
          ),
        ],
        junctions: [
          const Junction(position: Point(10, 20)),
        ],
        wires: [
          Wire(points: [const Point(0, 0), const Point(10, 10)]),
        ],
        texts: [
          const SchematicText(text: 'Label', position: Point(5, 5)),
        ],
      );
      expect(schematic.version, '20260306');
      expect(schematic.generator, 'eeschema');
      expect(schematic.paper, 'A3');
      expect(schematic.elements.length, 2);
      expect(schematic.sheets.length, 1);
      expect(schematic.sheets[0].name, 'MCU');
      expect(schematic.junctions.length, 1);
      expect(schematic.wires.length, 1);
      expect(schematic.texts.length, 1);
    });
  });

  group('SchematicSheet', () {
    test('creates a SchematicSheet with defaults', () {
      const sheet = SchematicSheet(
        name: 'Power',
        fileName: 'power.kicad_sch',
        uuid: 'power-uuid',
      );
      expect(sheet.name, 'Power');
      expect(sheet.fileName, 'power.kicad_sch');
      expect(sheet.uuid, 'power-uuid');
      expect(sheet.x, 0);
      expect(sheet.y, 0);
      expect(sheet.width, 0);
      expect(sheet.height, 0);
      expect(sheet.pins, []);
    });

    test('creates a SchematicSheet with position and size', () {
      const sheet = SchematicSheet(
        name: 'MCU',
        fileName: 'mcu.kicad_sch',
        uuid: 'mcu-uuid',
        x: 88.9,
        y: 50.8,
        width: 76.2,
        height: 101.6,
      );
      expect(sheet.x, 88.9);
      expect(sheet.y, 50.8);
      expect(sheet.width, 76.2);
      expect(sheet.height, 101.6);
    });
  });

  group('BomItem', () {
    test('creates a BomItem with required fields', () {
      const item = BomItem(reference: 'R1', value: '10K');
      expect(item.reference, 'R1');
      expect(item.value, '10K');
      expect(item.footprint, '');
      expect(item.datasheet, '');
      expect(item.quantity, 1);
    });

    test('creates a BomItem with all fields', () {
      const item = BomItem(
        reference: 'R1, R2',
        value: '10K',
        footprint: '0805',
        datasheet: 'https://example.com',
        quantity: 2,
      );
      expect(item.reference, 'R1, R2');
      expect(item.footprint, '0805');
      expect(item.datasheet, 'https://example.com');
      expect(item.quantity, 2);
    });

    test('toCsvLine formats correctly', () {
      const item = BomItem(
        reference: 'R1',
        value: '10K',
        footprint: '0805',
        datasheet: '',
        quantity: 1,
      );
      expect(item.toCsvLine(), '"R1","10K","0805","",1');
    });

    test('toCsvLine handles quantity > 1', () {
      const item = BomItem(
        reference: 'C1, C2, C3',
        value: '100nF',
        footprint: '0805',
        quantity: 3,
      );
      expect(item.toCsvLine(), '"C1, C2, C3","100nF","0805","",3');
    });

    test('csvHeader returns correct header', () {
      expect(BomItem.csvHeader(), '"Reference","Value","Footprint","Datasheet","Qty"');
    });

    test('BomItem const constructor works', () {
      const item = BomItem(reference: 'LED1', value: 'Red');
      expect(item.reference, 'LED1');
    });
  });
}
