import 'schematic_element.dart';

class RectDim {
  final double x;
  final double y;
  final double w;
  final double h;

  const RectDim(this.x, this.y, this.w, this.h);
}

class Schematic {
  final String fileName;
  final String version;
  final String generator;
  final String paper;
  final List<SchematicElement> elements;
  final List<SchematicSheet> sheets;
  final List<Junction> junctions;
  final List<Wire> wires;
  final List<SchematicText> texts;
  final Map<String, List<RectDim>> symbolBodies;
  final Map<String, List<SchematicPin>> symbolPins;

  const Schematic({
    required this.fileName,
    this.version = '',
    this.generator = '',
    this.paper = 'A4',
    this.elements = const [],
    this.sheets = const [],
    this.junctions = const [],
    this.wires = const [],
    this.texts = const [],
    this.symbolBodies = const {},
    this.symbolPins = const {},
  });
}

class SchematicSheet {
  final String name;
  final String fileName;
  final String uuid;
  final double x;
  final double y;
  final double width;
  final double height;
  final List<SheetPin> pins;

  const SchematicSheet({
    required this.name,
    required this.fileName,
    required this.uuid,
    this.x = 0,
    this.y = 0,
    this.width = 0,
    this.height = 0,
    this.pins = const [],
  });
}

class BomItem {
  final String reference;
  final String value;
  final String footprint;
  final String datasheet;
  final int quantity;

  const BomItem({
    required this.reference,
    required this.value,
    this.footprint = '',
    this.datasheet = '',
    this.quantity = 1,
  });

  String toCsvLine() {
    return '"$reference","$value","$footprint","$datasheet",$quantity';
  }

  static String csvHeader() {
    return '"Reference","Value","Footprint","Datasheet","Qty"';
  }
}
