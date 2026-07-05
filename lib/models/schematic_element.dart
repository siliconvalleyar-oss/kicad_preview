import 'dart:ui';

class Point {
  final double x;
  final double y;
  const Point(this.x, this.y);

  @override
  String toString() => 'Point($x, $y)';
}

enum SchematicElementType {
  wire,
  junction,
  symbol,
  label,
  text,
  sheet,
  noConnect,
  bus,
}

class SchematicElement {
  final SchematicElementType type;
  final String? uuid;
  final List<Point> points;
  final double strokeWidth;
  final String? strokeType;
  final Color color;
  final String? text;
  final double? textSize;
  final String? sheetName;
  final String? sheetFile;
  final List<SheetPin> pins;
  final Map<String, String> properties;

  const SchematicElement({
    required this.type,
    this.uuid,
    this.points = const [],
    this.strokeWidth = 0,
    this.strokeType,
    this.color = const Color(0xFF000000),
    this.text,
    this.textSize,
    this.sheetName,
    this.sheetFile,
    this.pins = const [],
    this.properties = const {},
  });

  SchematicElement copyWith({
    SchematicElementType? type,
    String? uuid,
    List<Point>? points,
    double? strokeWidth,
    String? strokeType,
    Color? color,
    String? text,
    double? textSize,
    String? sheetName,
    String? sheetFile,
    List<SheetPin>? pins,
    Map<String, String>? properties,
  }) {
    return SchematicElement(
      type: type ?? this.type,
      uuid: uuid ?? this.uuid,
      points: points ?? this.points,
      strokeWidth: strokeWidth ?? this.strokeWidth,
      strokeType: strokeType ?? this.strokeType,
      color: color ?? this.color,
      text: text ?? this.text,
      textSize: textSize ?? this.textSize,
      sheetName: sheetName ?? this.sheetName,
      sheetFile: sheetFile ?? this.sheetFile,
      pins: pins ?? this.pins,
      properties: properties ?? this.properties,
    );
  }
}

class SheetPin {
  final String name;
  final String type;
  final Point position;
  final double rotation;

  const SheetPin({
    required this.name,
    required this.type,
    required this.position,
    this.rotation = 0,
  });
}

class Junction {
  final Point position;
  final String? uuid;

  const Junction({required this.position, this.uuid});
}

class Wire {
  final List<Point> points;
  final double width;
  final String? uuid;

  const Wire({required this.points, this.width = 0, this.uuid});
}

class SchematicText {
  final String text;
  final Point position;
  final double size;
  final double rotation;
  final bool italic;
  final bool bold;

  const SchematicText({
    required this.text,
    required this.position,
    this.size = 1.27,
    this.rotation = 0,
    this.italic = false,
    this.bold = false,
  });
}
