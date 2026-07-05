import 'package:flutter/foundation.dart';
import '../models/schematic.dart';
import '../models/schematic_element.dart';
import 'sexpr_parser.dart';

class SchematicParser {
  /// Parse a .kicad_sch file content into a Schematic model.
  static Schematic parse(String content, {String fileName = ''}) {
    final data = SExprParser.parseString(content);

    if (data.isEmpty) {
      return Schematic(fileName: fileName);
    }

    final root = data.first;
    if (root is! List<dynamic> || root.isEmpty) {
      return Schematic(fileName: fileName);
    }

    final version = SExprParser.getStringValue(root, 'version') ?? '';
    final generator = SExprParser.getStringValue(root, 'generator') ?? '';
    final paper = SExprParser.getStringValue(root, 'paper') ?? 'A4';

    final elements = <SchematicElement>[];
    final sheets = <SchematicSheet>[];
    final junctions = <Junction>[];
    final wires = <Wire>[];
    final texts = <SchematicText>[];

    // Parse lib_symbols to get body dimensions
    final symbolBodies = <String, List<RectDim>>{};
    for (final libSymbols in SExprParser.findAll(root, 'lib_symbols')) {
      for (final symEntry in libSymbols) {
        if (symEntry is List<dynamic> && symEntry.length >= 2 && symEntry[0] == 'symbol') {
          final libId = symEntry[1].toString();
          if (libId.isEmpty) continue;
          final rects = <RectDim>[];
          for (final item in symEntry) {
            if (item is List<dynamic> && item.length >= 2 && item[0] == 'rectangle') {
              final start = SExprParser.findFirst(item, 'start');
              final end = SExprParser.findFirst(item, 'end');
              if (start != null && end != null && start.length >= 3 && end.length >= 3) {
                final x1 = double.tryParse(start[1].toString()) ?? 0;
                final y1 = double.tryParse(start[2].toString()) ?? 0;
                final x2 = double.tryParse(end[1].toString()) ?? 0;
                final y2 = double.tryParse(end[2].toString()) ?? 0;
                rects.add(RectDim(
                  (x1 + x2) / 2,
                  (y1 + y2) / 2,
                  (x2 - x1).abs(),
                  (y2 - y1).abs(),
                ));
              }
            }
          }
          if (rects.isNotEmpty) {
            symbolBodies[libId] = rects;
          }
        }
      }
    }

    // Parse wires
    for (final wire in SExprParser.findAll(root, 'wire')) {
      final pts = SExprParser.findFirst(wire, 'pts');
      final points = <Point>[];
      if (pts != null) {
        for (final pt in pts) {
          if (pt is List<dynamic> && pt.length >= 3 && pt[0] == 'xy') {
            final x = double.tryParse(pt[1].toString()) ?? 0;
            final y = double.tryParse(pt[2].toString()) ?? 0;
            points.add(Point(x, y));
          }
        }
      }
      final stroke = SExprParser.findFirst(wire, 'stroke');
      final width = stroke != null
          ? double.tryParse(SExprParser.getStringValue(stroke, 'width') ?? '0') ?? 0
          : 0.0;
      final uuid = SExprParser.getStringValue(wire, 'uuid');
      wires.add(Wire(points: points, width: width, uuid: uuid));
      elements.add(SchematicElement(
        type: SchematicElementType.wire,
        points: points,
        strokeWidth: width,
        uuid: uuid,
      ));
    }

    // Parse junctions
    for (final junction in SExprParser.findAll(root, 'junction')) {
      final at = SExprParser.findFirst(junction, 'at');
      if (at != null && at.length >= 3) {
        final x = double.tryParse(at[1].toString()) ?? 0;
        final y = double.tryParse(at[2].toString()) ?? 0;
        final uuid = SExprParser.getStringValue(junction, 'uuid');
        junctions.add(Junction(position: Point(x, y), uuid: uuid));
        elements.add(SchematicElement(
          type: SchematicElementType.junction,
          points: [Point(x, y)],
          uuid: uuid,
        ));
      }
    }

    // Parse sheets (hierarchical)
    for (final sheet in SExprParser.findAll(root, 'sheet')) {
      final at = SExprParser.findFirst(sheet, 'at');
      final size = SExprParser.findFirst(sheet, 'size');
      final uuid = SExprParser.getStringValue(sheet, 'uuid') ?? '';
      double x = 0, y = 0, w = 0, h = 0;
      if (at != null && at.length >= 3) {
        x = double.tryParse(at[1].toString()) ?? 0;
        y = double.tryParse(at[2].toString()) ?? 0;
      }
      if (size != null && size.length >= 3) {
        w = double.tryParse(size[1].toString()) ?? 0;
        h = double.tryParse(size[2].toString()) ?? 0;
      }

      String sheetName = '';
      String sheetFile = '';
      final pins = <SheetPin>[];

      for (final prop in SExprParser.findAll(sheet, 'property')) {
        if (prop.length >= 3) {
          final name = prop[1].toString();
          final value = prop[2].toString();
          if (name == 'Sheetname') sheetName = value;
          if (name == 'Sheetfile') sheetFile = value;
        }
      }

      // Parse sheet pins
      for (final pin in SExprParser.findAll(sheet, 'pin')) {
        if (pin.length >= 2) {
          final pinName = pin[1].toString();
          final pinType = pin.length > 2 ? pin[2].toString() : '';
          final pinAt = SExprParser.findFirst(pin, 'at');
          double px = 0, py = 0, prot = 0;
          if (pinAt != null && pinAt.length >= 3) {
            px = double.tryParse(pinAt[1].toString()) ?? 0;
            py = double.tryParse(pinAt[2].toString()) ?? 0;
            prot = pinAt.length > 3 ? double.tryParse(pinAt[3].toString()) ?? 0 : 0;
          }
          pins.add(SheetPin(
            name: pinName,
            type: pinType,
            position: Point(px, py),
            rotation: prot,
          ));
        }
      }

      sheets.add(SchematicSheet(
        name: sheetName,
        fileName: sheetFile,
        uuid: uuid,
        x: x,
        y: y,
        width: w,
        height: h,
        pins: pins,
      ));

      elements.add(SchematicElement(
        type: SchematicElementType.sheet,
        points: [Point(x, y), Point(x + w, y + h)],
        sheetName: sheetName,
        sheetFile: sheetFile,
        pins: pins,
        uuid: uuid,
        strokeWidth: 0.1524,
      ));
    }

    // Parse text entries
    for (final text in SExprParser.findAll(root, 'text')) {
      final at = SExprParser.findFirst(text, 'at');
      if (at != null && at.length >= 3) {
        final x = double.tryParse(at[1].toString()) ?? 0;
        final y = double.tryParse(at[2].toString()) ?? 0;
        final rot = at.length > 3 ? double.tryParse(at[3].toString()) ?? 0 : 0.0;
        final textContent = text.length > 1 ? text[1].toString() : '';
        final effects = SExprParser.findFirst(text, 'effects');
        double size = 1.27;
        if (effects != null) {
          final font = SExprParser.findFirst(effects, 'font');
          if (font != null) {
            final sizeNode = SExprParser.findFirst(font, 'size');
            if (sizeNode != null && sizeNode.length >= 2) {
              size = double.tryParse(sizeNode[1].toString()) ?? 1.27;
            }
          }
        }
        texts.add(SchematicText(
          text: textContent,
          position: Point(x, y),
          size: size,
          rotation: rot,
        ));
        elements.add(SchematicElement(
          type: SchematicElementType.text,
          points: [Point(x, y)],
          text: textContent,
          textSize: size,
        ));
      }
    }

    // Parse labels (global, hierarchical, net)
    for (final label in [
      ...SExprParser.findAll(root, 'label'),
      ...SExprParser.findAll(root, 'global_label'),
      ...SExprParser.findAll(root, 'hierarchical_label'),
    ]) {
      final labelText = label.length > 1 ? label[1].toString() : '';
      final at = SExprParser.findFirst(label, 'at');
      if (at != null && at.length >= 3) {
        final x = double.tryParse(at[1].toString()) ?? 0;
        final y = double.tryParse(at[2].toString()) ?? 0;
        elements.add(SchematicElement(
          type: SchematicElementType.label,
          points: [Point(x, y)],
          text: labelText,
        ));
      }
    }

    // Parse symbol instances (components)
    for (final symbol in SExprParser.findAll(root, 'symbol')) {
      final at = SExprParser.findFirst(symbol, 'at');
      double sx = 0, sy = 0, srot = 0;
      if (at != null && at.length >= 3) {
        sx = double.tryParse(at[1].toString()) ?? 0;
        sy = double.tryParse(at[2].toString()) ?? 0;
        srot = at.length > 3 ? double.tryParse(at[3].toString()) ?? 0 : 0;
      }
      final libId = SExprParser.getStringValue(symbol, 'lib_id') ?? '';
      final uuid = SExprParser.getStringValue(symbol, 'uuid');

      String reference = '';
      String value = '';
      Point? refPos, valuePos;
      for (final prop in SExprParser.findAll(symbol, 'property')) {
        if (prop.length >= 3) {
          final name = prop[1].toString();
          final valueStr = prop[2].toString();
          if (name == 'Reference') {
            reference = valueStr;
            final pat = SExprParser.findFirst(prop, 'at');
            if (pat != null && pat.length >= 3) {
              refPos = Point(
                double.tryParse(pat[1].toString()) ?? 0,
                double.tryParse(pat[2].toString()) ?? 0,
              );
            }
          }
          if (name == 'Value') {
            value = valueStr;
            final pat = SExprParser.findFirst(prop, 'at');
            if (pat != null && pat.length >= 3) {
              valuePos = Point(
                double.tryParse(pat[1].toString()) ?? 0,
                double.tryParse(pat[2].toString()) ?? 0,
              );
            }
          }
        }
      }
      if (reference.isNotEmpty) {
        elements.add(SchematicElement(
          type: SchematicElementType.symbol,
          points: [Point(sx, sy)],
          text: reference,
          textSize: 1.27,
          uuid: uuid,
          properties: {
            'Reference': reference,
            'Value': value,
            'lib_id': libId,
            'ref_x': '${refPos?.x ?? sx}',
            'ref_y': '${refPos?.y ?? sy - 2}',
            'val_x': '${valuePos?.x ?? sx}',
            'val_y': '${valuePos?.y ?? sy + 2}',
          },
        ));
      }
    }

    return Schematic(
      fileName: fileName,
      version: version,
      generator: generator,
      paper: paper,
      elements: elements,
      sheets: sheets,
      junctions: junctions,
      wires: wires,
      texts: texts,
      symbolBodies: symbolBodies,
    );
  }

  /// Generate BOM from schematic elements.
  static List<BomItem> generateBom(Schematic schematic) {
    final bomMap = <String, BomItem>{};
    for (final element in schematic.elements) {
      if (element.type == SchematicElementType.symbol) {
        final ref = element.properties['Reference'] ?? '';
        final value = element.properties['Value'] ?? '';
        final key = '$value|${element.properties['Footprint'] ?? ''}';
        if (bomMap.containsKey(key)) {
          final existing = bomMap[key]!;
          bomMap[key] = BomItem(
            reference: '${existing.reference}, $ref',
            value: existing.value,
            footprint: existing.footprint,
            datasheet: existing.datasheet,
            quantity: existing.quantity + 1,
          );
        } else {
          bomMap[key] = BomItem(
            reference: ref,
            value: value,
            footprint: element.properties['Footprint'] ?? '',
            datasheet: element.properties['Datasheet'] ?? '',
          );
        }
      }
    }
    return bomMap.values.toList();
  }
}
