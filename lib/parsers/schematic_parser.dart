import 'dart:math';
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

    // Parse lib_symbols: collect rectangles + pins (recursively through
    // nested alias symbols, since SExprParser helpers are not recursive)
    // and compute each symbol's real body bounding box from its pin
    // positions, so the drawn body matches the designed size.
    final symbolBodies = <String, List<RectDim>>{};
    final symbolPins = <String, List<SchematicPin>>{};

    final symNodes = <String, List<dynamic>>{};
    for (final libSymbols in SExprParser.findAll(root, 'lib_symbols')) {
      // libSymbols is the (lib_symbols ...) node; iterate its children.
      for (final child in libSymbols) {
        if (child is List<dynamic> &&
            child.length >= 2 &&
            child[0] == 'symbol') {
          final name = child[1].toString();
          if (name.isNotEmpty) symNodes[name] = child;
        }
      }
    }

    void collectGeometry(
      List<dynamic> node,
      List<RectDim> rects,
      List<SchematicPin> pins,
    ) {
      for (final item in node) {
        if (item is! List<dynamic> || item.isEmpty) continue;
        final t = item[0].toString();
        if (t == 'rectangle') {
          final start = SExprParser.findFirst(item, 'start');
          final end = SExprParser.findFirst(item, 'end');
          if (start != null &&
              end != null &&
              start.length >= 3 &&
              end.length >= 3) {
            final rx1 = double.tryParse(start[1].toString()) ?? 0;
            final ry1 = double.tryParse(start[2].toString()) ?? 0;
            final rx2 = double.tryParse(end[1].toString()) ?? 0;
            final ry2 = double.tryParse(end[2].toString()) ?? 0;
            rects.add(RectDim(
              (rx1 + rx2) / 2,
              (ry1 + ry2) / 2,
              (rx2 - rx1).abs(),
              (ry2 - ry1).abs(),
            ));
          }
        } else if (t == 'pin') {
          final at = SExprParser.findFirst(item, 'at');
          if (at != null && at.length >= 3) {
            final px = double.tryParse(at[1].toString()) ?? 0;
            final py = double.tryParse(at[2].toString()) ?? 0;
            final angle = at.length > 3
                ? double.tryParse(at[3].toString()) ?? 0.0
                : 0.0;
            final length = double.tryParse(
                    SExprParser.getStringValue(item, 'length') ?? '0') ??
                0.0;
            final number = SExprParser.findFirst(item, 'number');
            final name = SExprParser.findFirst(item, 'name');
            pins.add(SchematicPin(
              x: px,
              y: py,
              angle: angle,
              length: length,
              number: number != null && number.length > 1
                  ? number[1].toString()
                  : '',
              name: name != null && name.length > 1
                  ? name[1].toString()
                  : '',
            ));
          }
        }
        // Descend into all sublists (covers nested alias symbols).
        collectGeometry(item, rects, pins);
      }
    }

    RectDim? bboxFromGeometry(
      List<RectDim> rects,
      List<SchematicPin> pins,
    ) {
      double minX = double.infinity,
          minY = double.infinity,
          maxX = double.negativeInfinity,
          maxY = double.negativeInfinity;
      var found = false;
      void expand(double x, double y) {
        found = true;
        if (x < minX) minX = x;
        if (y < minY) minY = y;
        if (x > maxX) maxX = x;
        if (y > maxY) maxY = y;
      }

      for (final r in rects) {
        expand(r.x - r.w / 2, r.y - r.h / 2);
        expand(r.x + r.w / 2, r.y + r.h / 2);
      }
      for (final p in pins) {
        final rad = p.angle * pi / 180;
        final tx = p.x + p.length * cos(rad);
        final ty = p.y + p.length * sin(rad);
        // Expand by the pin BASE (inner end, near the body) only.
        // The pin TIP (at = p.x,p.y, outer connection point) is left
        // out so pins stick out of the body as designed.
        expand(tx, ty);
      }

      if (!found) return null;
      const pad = 0.5; // small margin around geometry
      return RectDim(
        (minX + maxX) / 2,
        (minY + maxY) / 2,
        (maxX - minX).abs() + pad * 2,
        (maxY - minY).abs() + pad * 2,
      );
    }

    for (final entry in symNodes.entries) {
      final rects = <RectDim>[];
      final pins = <SchematicPin>[];
      var node = entry.value;
      // If the symbol extends a base, merge the base geometry too.
      final extendsVal = SExprParser.getStringValue(node, 'extends');
      if (extendsVal != null &&
          extendsVal.isNotEmpty &&
          symNodes.containsKey(extendsVal)) {
        collectGeometry(symNodes[extendsVal]!, rects, pins);
      }
      collectGeometry(node, rects, pins);

      final name = entry.key;
      // Power symbols keep their dedicated (GND/arrow) rendering.
      if (name.startsWith('power:')) continue;
      final bbox = bboxFromGeometry(rects, pins);
      if (bbox != null) symbolBodies[name] = [bbox];
      if (pins.isNotEmpty) symbolPins[name] = pins;
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

    // Parse no-connect (connectivity) markers
    for (final nc in SExprParser.findAll(root, 'no_connect')) {
      final at = SExprParser.findFirst(nc, 'at');
      if (at != null && at.length >= 3) {
        final x = double.tryParse(at[1].toString()) ?? 0;
        final y = double.tryParse(at[2].toString()) ?? 0;
        final uuid = SExprParser.getStringValue(nc, 'uuid');
        elements.add(SchematicElement(
          type: SchematicElementType.noConnect,
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
          symbolPins: symbolPins[libId] ?? const [],
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
      symbolPins: symbolPins,
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
