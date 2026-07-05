import '../models/pcb.dart';
import '../models/pcb_element.dart';
import 'sexpr_parser.dart';

class PCBParser {
  /// Parse a .kicad_pcb file content into a PCB model.
  static PCB parse(String content, {String fileName = ''}) {
    final data = SExprParser.parseString(content);

    if (data.isEmpty) {
      return PCB(fileName: fileName);
    }

    final root = data.first;
    if (root is! List<dynamic> || root.isEmpty) {
      return PCB(fileName: fileName);
    }

    final version = SExprParser.getStringValue(root, 'version') ?? '';
    final generator = SExprParser.getStringValue(root, 'generator') ?? '';
    final paper = SExprParser.getStringValue(root, 'paper') ?? 'A4';

    // Parse general
    double thickness = 1.6;
    final general = SExprParser.findFirst(root, 'general');
    if (general != null) {
      thickness = double.tryParse(
          SExprParser.getStringValue(general, 'thickness') ?? '1.6') ?? 1.6;
    }

    // Parse layers
    final layers = <PCBLayer>[];
    final layersNode = SExprParser.findFirst(root, 'layers');
    if (layersNode != null) {
      for (final layer in layersNode) {
        if (layer is List<dynamic> && layer.length >= 3) {
          final id = int.tryParse(layer[0].toString()) ?? 0;
          final name = layer[1].toString();
          final type = layer[2].toString();
          layers.add(PCBLayer(id: id, name: name, type: type));
        }
      }
    }

    // Parse footprints
    final footprints = <PCBFootprint>[];
    for (final fp in SExprParser.findAll(root, 'footprint')) {
      final name = fp.length > 1 ? fp[1].toString() : '';
      final layer = SExprParser.getStringValue(fp, 'layer');
      final uuid = SExprParser.getStringValue(fp, 'uuid');
      final at = SExprParser.findFirst(fp, 'at');

      double x = 0, y = 0, rot = 0;
      if (at != null && at.length >= 3) {
        x = double.tryParse(at[1].toString()) ?? 0;
        y = double.tryParse(at[2].toString()) ?? 0;
        rot = at.length > 3 ? double.tryParse(at[3].toString()) ?? 0 : 0;
      }

      String reference = name;
      String value = '';
      for (final prop in SExprParser.findAll(fp, 'property')) {
        if (prop.length >= 3) {
          final propName = prop[1].toString();
          final propValue = prop[2].toString();
          if (propName == 'Reference') reference = propValue;
          if (propName == 'Value') value = propValue;
        }
      }

      // Parse pads within footprint
      final pads = <PCBPad>[];
      for (final pad in SExprParser.findAll(fp, 'pad')) {
        if (pad.length >= 2) {
          final padNum = pad[1].toString();
          final padType = pad.length > 2 ? pad[2].toString() : 'smd';
          final padShape = pad.length > 3 ? pad[3].toString() : 'rect';
          final padAt = SExprParser.findFirst(pad, 'at');
          double px = 0, py = 0;
          if (padAt != null && padAt.length >= 3) {
            px = double.tryParse(padAt[1].toString()) ?? 0;
            py = double.tryParse(padAt[2].toString()) ?? 0;
          }
          final padSize = SExprParser.findFirst(pad, 'size');
          double sx = 1, sy = 1;
          if (padSize != null && padSize.length >= 3) {
            sx = double.tryParse(padSize[1].toString()) ?? 1;
            sy = double.tryParse(padSize[2].toString()) ?? 1;
          }
          final drill = double.tryParse(
              SExprParser.getStringValue(pad, 'drill') ?? '');
          final padLayers = <String>[];
          final layersNode = SExprParser.findFirst(pad, 'layers');
          if (layersNode != null) {
            for (int i = 1; i < layersNode.length; i++) {
              padLayers.add(layersNode[i].toString());
            }
          }
          final net = SExprParser.getStringValue(pad, 'net');

          pads.add(PCBPad(
            number: padNum,
            x: px,
            y: py,
            sizeX: sx,
            sizeY: sy,
            drill: drill,
            type: padType,
            shape: padShape,
            layers: padLayers,
            net: net,
          ));
        }
      }

      // Parse graphical lines
      final lines = <PCBGraphicalLine>[];
      // Parse fp_line and fp_poly lines
      for (final fpLine in [
        ...SExprParser.findAll(fp, 'fp_line'),
        ...SExprParser.findAll(fp, 'fp_arc'),
      ]) {
        final start = SExprParser.findFirst(fpLine, 'start');
        final end = SExprParser.findFirst(fpLine, 'end');
        final fpLayer = SExprParser.getStringValue(fpLine, 'layer') ?? '';
        final stroke = SExprParser.findFirst(fpLine, 'stroke');
        double sw = 0.12;
        if (stroke != null) {
          sw = double.tryParse(
              SExprParser.getStringValue(stroke, 'width') ?? '0.12') ?? 0.12;
        }
        double x1 = 0, y1 = 0, x2 = 0, y2 = 0;
        if (start != null && start.length >= 3) {
          x1 = double.tryParse(start[1].toString()) ?? 0;
          y1 = double.tryParse(start[2].toString()) ?? 0;
        }
        if (end != null && end.length >= 3) {
          x2 = double.tryParse(end[1].toString()) ?? 0;
          y2 = double.tryParse(end[2].toString()) ?? 0;
        }
        lines.add(PCBGraphicalLine(
          x1: x1 + x, y1: y1 + y,
          x2: x2 + x, y2: y2 + y,
          width: sw,
          layer: fpLayer,
          uuid: SExprParser.getStringValue(fpLine, 'uuid'),
        ));
      }

      // Parse fp_rect
      for (final fpRect in SExprParser.findAll(fp, 'fp_rect')) {
        final start = SExprParser.findFirst(fpRect, 'start');
        final end = SExprParser.findFirst(fpRect, 'end');
        final fpLayer = SExprParser.getStringValue(fpRect, 'layer') ?? '';
        final stroke = SExprParser.findFirst(fpRect, 'stroke');
        double sw = 0.12;
        if (stroke != null) {
          sw = double.tryParse(
              SExprParser.getStringValue(stroke, 'width') ?? '0.12') ?? 0.12;
        }
        double x1 = 0, y1 = 0, x2 = 0, y2 = 0;
        if (start != null && start.length >= 3) {
          x1 = double.tryParse(start[1].toString()) ?? 0;
          y1 = double.tryParse(start[2].toString()) ?? 0;
        }
        if (end != null && end.length >= 3) {
          x2 = double.tryParse(end[1].toString()) ?? 0;
          y2 = double.tryParse(end[2].toString()) ?? 0;
        }
        // Draw as two lines for rectangle
        lines.add(PCBGraphicalLine(
          x1: x1 + x, y1: y1 + y,
          x2: x2 + x, y2: y1 + y,
          width: sw, layer: fpLayer,
        ));
        lines.add(PCBGraphicalLine(
          x1: x2 + x, y1: y1 + y,
          x2: x2 + x, y2: y2 + y,
          width: sw, layer: fpLayer,
        ));
        lines.add(PCBGraphicalLine(
          x1: x2 + x, y1: y2 + y,
          x2: x1 + x, y2: y2 + y,
          width: sw, layer: fpLayer,
        ));
        lines.add(PCBGraphicalLine(
          x1: x1 + x, y1: y2 + y,
          x2: x1 + x, y2: y1 + y,
          width: sw, layer: fpLayer,
        ));
      }

      // Parse fp_text
      final texts = <PCBGraphicalText>[];
      for (final fpText in SExprParser.findAll(fp, 'fp_text')) {
        if (fpText.length >= 3) {
          final textType = fpText[1].toString();
          final textContent = fpText[2].toString();
          final textAt = SExprParser.findFirst(fpText, 'at');
          double tx = 0, ty = 0, trot = 0;
          if (textAt != null && textAt.length >= 3) {
            tx = double.tryParse(textAt[1].toString()) ?? 0;
            ty = double.tryParse(textAt[2].toString()) ?? 0;
            trot = textAt.length > 3 ? double.tryParse(textAt[3].toString()) ?? 0 : 0;
          }
          final textLayer = SExprParser.getStringValue(fpText, 'layer') ?? '';
          texts.add(PCBGraphicalText(
            text: textContent,
            x: tx + x, y: ty + y,
            size: 1,
            rotation: trot,
            layer: textLayer,
            uuid: SExprParser.getStringValue(fpText, 'uuid'),
          ));
        }
      }

      footprints.add(PCBFootprint(
        reference: reference,
        value: value,
        layer: layer,
        uuid: uuid,
        x: x, y: y, rotation: rot,
        description: SExprParser.getStringValue(fp, 'descr'),
        pads: pads,
        lines: lines,
        texts: texts,
      ));
    }

    // Parse tracks
    final tracks = <PCBTrack>[];
    for (final track in SExprParser.findAll(root, 'track')) {
      final start = SExprParser.findFirst(track, 'start');
      final end = SExprParser.findFirst(track, 'end');
      final trackLayer = SExprParser.getStringValue(track, 'layer') ?? 'F.Cu';
      final trackWidth = double.tryParse(
          SExprParser.getStringValue(track, 'width') ?? '0.25') ?? 0.25;
      final net = SExprParser.getStringValue(track, 'net');
      final uuid = SExprParser.getStringValue(track, 'uuid');
      double x1 = 0, y1 = 0, x2 = 0, y2 = 0;
      if (start != null && start.length >= 3) {
        x1 = double.tryParse(start[1].toString()) ?? 0;
        y1 = double.tryParse(start[2].toString()) ?? 0;
      }
      if (end != null && end.length >= 3) {
        x2 = double.tryParse(end[1].toString()) ?? 0;
        y2 = double.tryParse(end[2].toString()) ?? 0;
      }
      tracks.add(PCBTrack(
        x1: x1, y1: y1, x2: x2, y2: y2,
        width: trackWidth,
        layer: trackLayer,
        net: net,
        uuid: uuid,
      ));
    }

    // Parse vias
    final vias = <PCBVia>[];
    for (final via in SExprParser.findAll(root, 'via')) {
      final at = SExprParser.findFirst(via, 'at');
      final viaDrill = double.tryParse(
          SExprParser.getStringValue(via, 'drill') ?? '0.4') ?? 0.4;
      final viaDiameter = double.tryParse(
          SExprParser.getStringValue(via, 'diameter') ?? '0.8') ?? 0.8;
      final net = SExprParser.getStringValue(via, 'net');
      double vx = 0, vy = 0;
      if (at != null && at.length >= 3) {
        vx = double.tryParse(at[1].toString()) ?? 0;
        vy = double.tryParse(at[2].toString()) ?? 0;
      }
      final viaLayers = <String>[];
      final layersNode = SExprParser.findFirst(via, 'layers');
      if (layersNode != null) {
        for (int i = 1; i < layersNode.length; i++) {
          viaLayers.add(layersNode[i].toString());
        }
      }
      vias.add(PCBVia(
        x: vx, y: vy,
        diameter: viaDiameter,
        drill: viaDrill,
        layers: viaLayers.isNotEmpty ? viaLayers : ['F.Cu', 'B.Cu'],
        net: net,
      ));
    }

    // Parse graphical items on the PCB level
    final graphicalLines = <PCBGraphicalLine>[];
    for (final grLine in [
      ...SExprParser.findAll(root, 'gr_line'),
      ...SExprParser.findAll(root, 'gr_arc'),
      ...SExprParser.findAll(root, 'gr_circle'),
    ]) {
      final start = SExprParser.findFirst(grLine, 'start');
      final end = SExprParser.findFirst(grLine, 'end');
      final grLayer = SExprParser.getStringValue(grLine, 'layer') ?? 'Edge.Cuts';
      final stroke = SExprParser.findFirst(grLine, 'stroke');
      double sw = 0.12;
      if (stroke != null) {
        sw = double.tryParse(
            SExprParser.getStringValue(stroke, 'width') ?? '0.12') ?? 0.12;
      }
      double x1 = 0, y1 = 0, x2 = 0, y2 = 0;
      if (start != null && start.length >= 3) {
        x1 = double.tryParse(start[1].toString()) ?? 0;
        y1 = double.tryParse(start[2].toString()) ?? 0;
      }
      if (end != null && end.length >= 3) {
        x2 = double.tryParse(end[1].toString()) ?? 0;
        y2 = double.tryParse(end[2].toString()) ?? 0;
      }
      graphicalLines.add(PCBGraphicalLine(
        x1: x1, y1: y1, x2: x2, y2: y2,
        width: sw,
        layer: grLayer,
        uuid: SExprParser.getStringValue(grLine, 'uuid'),
      ));
    }

    // Parse zone fills
    for (final zone in SExprParser.findAll(root, 'zone')) {
      // Zones are complex, we'll approximate them as filled polygons later
    }

    return PCB(
      fileName: fileName,
      version: version,
      generator: generator,
      thickness: thickness,
      paper: paper,
      layers: layers,
      footprints: footprints,
      tracks: tracks,
      vias: vias,
      graphicalLines: graphicalLines,
      graphicalTexts: [],
    );
  }
}
