import 'dart:ui';

class PCBLayer {
  final int id;
  final String name;
  final String type;
  final Color defaultColor;
  bool visible;

  PCBLayer({
    required this.id,
    required this.name,
    required this.type,
    this.defaultColor = const Color(0xFF000000),
    this.visible = true,
  });

  static const Map<int, Color> kicadLayerColors = {
    0: Color(0xFFFF0000), // F.Cu - Red
    2: Color(0xFF0000FF), // B.Cu - Blue
    4: Color(0xFF008800), // In1.Cu - Green
    6: Color(0xFF880088), // In2.Cu - Purple
    1: Color(0xFFC0C0C0), // F.Mask - Grey
    3: Color(0xFF808080), // B.Mask - Dark Grey
    5: Color(0xFFFFFF00), // F.SilkS - Yellow
    7: Color(0xFF00FFFF), // B.SilkS - Cyan
    9: Color(0xFFDCDCDC), // F.Adhes - Light Grey
    11: Color(0xFFA9A9A9), // B.Adhes - Dark Grey
    13: Color(0xFF696969), // F.Paste
    15: Color(0xFF808080), // B.Paste
    17: Color(0xFF000000), // Dwgs.User
    19: Color(0xFF000000), // Cmts.User
    21: Color(0xFF000000), // Eco1.User
    23: Color(0xFF000000), // Eco2.User
    25: Color(0xFFFFA500), // Edge.Cuts - Orange
    27: Color(0xFF000000), // Margin
    31: Color(0xFF000000), // F.CrtYd
    29: Color(0xFF000000), // B.CrtYd
    35: Color(0xFF000000), // F.Fab
    33: Color(0xFF000000), // B.Fab
  };

  Color get color {
    return kicadLayerColors[id] ?? const Color(0xFF000000);
  }
}

class PCBFootprint {
  final String reference;
  final String value;
  final String? layer;
  final String? uuid;
  final double x;
  final double y;
  final double rotation;
  final String? description;
  final List<PCBPad> pads;
  final List<PCBGraphicalLine> lines;
  final List<PCBGraphicalText> texts;

  const PCBFootprint({
    required this.reference,
    required this.value,
    this.layer,
    this.uuid,
    this.x = 0,
    this.y = 0,
    this.rotation = 0,
    this.description,
    this.pads = const [],
    this.lines = const [],
    this.texts = const [],
  });
}

class PCBPad {
  final String number;
  final double x;
  final double y;
  final double sizeX;
  final double sizeY;
  final double? drill;
  final String type;
  final String shape;
  final List<String> layers;
  final String? net;

  const PCBPad({
    required this.number,
    this.x = 0,
    this.y = 0,
    this.sizeX = 1,
    this.sizeY = 1,
    this.drill,
    this.type = 'smd',
    this.shape = 'rect',
    this.layers = const ['F.Cu'],
    this.net,
  });
}

class PCBGraphicalLine {
  final double x1;
  final double y1;
  final double x2;
  final double y2;
  final double width;
  final String layer;
  final String? uuid;

  const PCBGraphicalLine({
    required this.x1,
    required this.y1,
    required this.x2,
    required this.y2,
    this.width = 0.12,
    required this.layer,
    this.uuid,
  });
}

class PCBGraphicalText {
  final String text;
  final double x;
  final double y;
  final double size;
  final double rotation;
  final String layer;
  final String? uuid;

  const PCBGraphicalText({
    required this.text,
    this.x = 0,
    this.y = 0,
    this.size = 1,
    this.rotation = 0,
    required this.layer,
    this.uuid,
  });
}

class PCBTrack {
  final double x1;
  final double y1;
  final double x2;
  final double y2;
  final double width;
  final String layer;
  final String? net;
  final String? uuid;

  const PCBTrack({
    required this.x1,
    required this.y1,
    required this.x2,
    required this.y2,
    this.width = 0.25,
    required this.layer,
    this.net,
    this.uuid,
  });
}

class PCBVia {
  final double x;
  final double y;
  final double diameter;
  final double drill;
  final List<String> layers;
  final String? net;

  const PCBVia({
    this.x = 0,
    this.y = 0,
    this.diameter = 0.8,
    this.drill = 0.4,
    this.layers = const ['F.Cu', 'B.Cu'],
    this.net,
  });
}
