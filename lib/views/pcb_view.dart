import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/pcb.dart';
import '../models/pcb_element.dart';
import '../controllers/app_state.dart';

class PCBView extends StatefulWidget {
  final PCB pcb;

  const PCBView({super.key, required this.pcb});

  @override
  State<PCBView> createState() => _PCBViewState();
}

class _PCBViewState extends State<PCBView> {
  final TransformationController _transformController =
      TransformationController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _centerView());
  }

  void _centerView() {
    final size = context.size;
    if (size == null) return;

    double minX = double.infinity, minY = double.infinity;
    double maxX = double.negativeInfinity, maxY = double.negativeInfinity;

    for (final track in widget.pcb.tracks) {
      for (final p in [Offset(track.x1, track.y1), Offset(track.x2, track.y2)]) {
        final x = p.dx * 10;
        final y = p.dy * 10;
        if (x < minX) minX = x; if (y < minY) minY = y;
        if (x > maxX) maxX = x; if (y > maxY) maxY = y;
      }
    }
    for (final via in widget.pcb.vias) {
      final x = via.x * 10;
      final y = via.y * 10;
      if (x < minX) minX = x; if (y < minY) minY = y;
      if (x > maxX) maxX = x; if (y > maxY) maxY = y;
    }
    for (final fp in widget.pcb.footprints) {
      final x = fp.x * 10;
      final y = fp.y * 10;
      if (x < minX) minX = x; if (y < minY) minY = y;
      if (x > maxX) maxX = x; if (y > maxY) maxY = y;
    }
    for (final line in widget.pcb.graphicalLines) {
      for (final p in [Offset(line.x1, line.y1), Offset(line.x2, line.y2)]) {
        final x = p.dx * 10;
        final y = p.dy * 10;
        if (x < minX) minX = x; if (y < minY) minY = y;
        if (x > maxX) maxX = x; if (y > maxY) maxY = y;
      }
    }

    if (minX == double.infinity) return;

    final contentWidth = maxX - minX;
    final contentHeight = maxY - minY;
    final contentCenterX = (minX + maxX) / 2;
    final contentCenterY = (minY + maxY) / 2;

    final scaleX = size.width / (contentWidth + 100);
    final scaleY = size.height / (contentHeight + 100);
    final scale = scaleX < scaleY ? scaleX : scaleY;

    final tx = size.width / 2 - contentCenterX * scale;
    final ty = size.height / 2 - contentCenterY * scale;

    _transformController.value = Matrix4.identity()
      ..translate(tx, ty)
      ..scale(scale);
  }

  @override
  void dispose() {
    _transformController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final side = appState.pcbSide;
    final flipped = appState.pcbFlipped;
    final showRefs = appState.showPcbRefs;

    Widget content = InteractiveViewer(
      transformationController: _transformController,
      boundaryMargin: const EdgeInsets.all(double.infinity),
      minScale: 0.1,
      maxScale: 10.0,
      onInteractionEnd: (details) {
        final matrix = _transformController.value;
        final scale = matrix.getMaxScaleOnAxis();
        final offset = Offset(matrix.getTranslation().x, matrix.getTranslation().y);
        context.read<AppState>().updatePCBTransform(offset, scale);
      },
      child: SizedBox(
        width: 2000,
        height: 2000,
        child: RepaintBoundary(
          child: CustomPaint(
            painter: PCBPainter(
              pcb: widget.pcb,
              selectedElementId: appState.selectedElementId,
              pcbSide: side,
              showPcbRefs: showRefs,
            ),
            size: const Size(2000, 2000),
          ),
        ),
      ),
    );

    if (flipped) {
      content = RotatedBox(quarterTurns: 2, child: content);
    }

    return content;
  }
}

class PCBPainter extends CustomPainter {
  final PCB pcb;
  final String? selectedElementId;
  final String pcbSide;
  final bool showPcbRefs;

  PCBPainter({
    required this.pcb,
    this.selectedElementId,
    this.pcbSide = 'top',
    this.showPcbRefs = false,
  });

  bool _isBottomSide(String layerName) {
    return layerName.startsWith('B.');
  }

  double _sideOpacity(String layerName) {
    final onBottom = _isBottomSide(layerName);
    if (pcbSide == 'top') {
      return onBottom ? 0.4 : 1.0;
    } else {
      return onBottom ? 1.0 : 0.4;
    }
  }

  Color _selectionColor(String? id, Color base, {String layer = ''}) {
    double alpha = 1.0;
    if (selectedElementId != null) {
      if (id != selectedElementId) alpha = 0.2;
    }
    alpha *= _sideOpacity(layer);
    if (alpha >= 1.0) return base;
    return base.withValues(alpha: alpha);
  }

  @override
  void paint(Canvas canvas, Size size) {
    _drawGrid(canvas, size);

    // Draw graphical lines on Edge.Cuts and other layers
    for (final line in pcb.graphicalLines) {
      final layer = pcb.getLayerById(_layerNameToId(line.layer));
      if (layer != null && !layer.visible) continue;

      final baseColor = _getLayerColor(line.layer);
      final paint = Paint()
        ..color = _selectionColor(null, baseColor, layer: line.layer)
        ..strokeWidth = line.width * 10
        ..style = PaintingStyle.stroke;

      canvas.drawLine(
        Offset(line.x1 * 10, line.y1 * 10),
        Offset(line.x2 * 10, line.y2 * 10),
        paint,
      );
    }

    // Draw tracks (copper traces)
    for (final track in pcb.tracks) {
      final layer = pcb.getLayerById(_layerNameToId(track.layer));
      if (layer != null && !layer.visible) continue;

      final isSelected = track.uuid == selectedElementId;
      final baseColor = _getLayerColor(track.layer);
      final paint = Paint()
        ..color = isSelected
            ? const Color(0xFF6C5CE7)
            : _selectionColor(track.uuid, baseColor, layer: track.layer)
        ..strokeWidth = track.width * 10
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      if (isSelected) {
        paint.strokeWidth = paint.strokeWidth * 1.5;
      }

      canvas.drawLine(
        Offset(track.x1 * 10, track.y1 * 10),
        Offset(track.x2 * 10, track.y2 * 10),
        paint,
      );
    }

    // Draw vias
    for (final via in pcb.vias) {
      final viaLayer = pcb.getLayerById(_layerNameToId(via.layers.first));
      if (viaLayer != null && !viaLayer.visible) continue;

      final paint = Paint()
        ..color = const Color(0xFF95A5A6)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(
        Offset(via.x * 10, via.y * 10),
        (via.diameter / 2) * 10,
        paint,
      );

      // Drill hole
      final holePaint = Paint()
        ..color = const Color(0xFF1E1E2E)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(
        Offset(via.x * 10, via.y * 10),
        (via.drill / 2) * 10,
        holePaint,
      );
    }

    // Draw footprints
    for (final fp in pcb.footprints) {
      _drawFootprint(canvas, fp, fp.uuid == selectedElementId);
    }
  }

  void _drawFootprint(Canvas canvas, PCBFootprint fp, bool isSelected) {
    final offset = Offset(fp.x * 10, fp.y * 10);
    final fpLayer = fp.layer != null
        ? pcb.getLayerById(_layerNameToId(fp.layer!))
        : null;
    final fpVisible = fpLayer == null || fpLayer.visible;

    if (!fpVisible) return;

    final dimColor = !isSelected && selectedElementId != null;

    // Draw pads
    for (final pad in fp.pads) {
      final layer = pad.layers.isNotEmpty
          ? pcb.getLayerById(_layerNameToId(pad.layers.first))
          : null;
      if (layer != null && !layer.visible) continue;

      final padLayerName = pad.layers.isNotEmpty ? pad.layers.first : 'F.Cu';
      final baseColor = const Color(0xFFC0C0C0);
      final sideAlpha = _sideOpacity(padLayerName);
      final paintAlpha = dimColor ? 0.2 * sideAlpha : sideAlpha;
      final paint = Paint()
        ..color = baseColor.withValues(alpha: paintAlpha.clamp(0.0, 1.0))
        ..style = PaintingStyle.fill;

      final rect = Rect.fromCenter(
        center: Offset(pad.x * 10, pad.y * 10) + offset,
        width: pad.sizeX * 10,
        height: pad.sizeY * 10,
      );

      if (pad.shape == 'circle' || pad.shape == 'roundrect') {
        canvas.drawRRect(
          RRect.fromRectAndRadius(rect, const Radius.circular(2)),
          paint,
        );
      } else {
        canvas.drawRect(rect, paint);
      }

      // Draw drill hole
      if (pad.drill != null && pad.drill! > 0) {
        final holePaint = Paint()
          ..color = const Color(0xFF1E1E2E)
          ..style = PaintingStyle.fill;
        canvas.drawCircle(
          Offset(pad.x * 10, pad.y * 10) + offset,
          (pad.drill! / 2) * 10,
          holePaint,
        );
      }
    }

    // Draw footprint outline lines
    for (final line in fp.lines) {
      final layer = pcb.getLayerById(_layerNameToId(line.layer));
      if (layer != null && !layer.visible) continue;

      final baseColor = _getLayerColor(line.layer);
      final sideAlpha = _sideOpacity(line.layer);
      final paintAlpha = dimColor ? 0.2 * sideAlpha : sideAlpha;
      final paint = Paint()
        ..color = baseColor.withValues(alpha: paintAlpha.clamp(0.0, 1.0))
        ..strokeWidth = line.width * 10
        ..style = PaintingStyle.stroke;

      canvas.drawLine(
        Offset(line.x1 * 10, line.y1 * 10),
        Offset(line.x2 * 10, line.y2 * 10),
        paint,
      );
    }

    // Draw footprint texts
    for (final text in fp.texts) {
      final layer = pcb.getLayerById(_layerNameToId(text.layer));
      if (layer != null && !layer.visible) continue;

      final sideAlpha = _sideOpacity(text.layer);
      final textAlpha = dimColor ? 0.15 * sideAlpha : 0.4 * sideAlpha;
      final textPainter = TextPainter(
        text: TextSpan(
          text: text.text,
          style: TextStyle(
            color: Colors.white.withValues(alpha: textAlpha.clamp(0.0, 1.0)),
            fontSize: text.size * 8,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(text.x * 10, text.y * 10),
      );
    }

    // Draw reference text (user-toggleable)
    if (showPcbRefs) {
      final sideAlpha = _sideOpacity('F.SilkS');
      final refAlpha = dimColor ? 0.15 * sideAlpha : 0.4 * sideAlpha;
      final textPainter = TextPainter(
        text: TextSpan(
          text: fp.reference,
          style: TextStyle(
            color: Colors.white.withValues(alpha: refAlpha.clamp(0.0, 1.0)),
            fontSize: 8,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(canvas, offset + const Offset(-10, -10));
    }
  }

  void _drawGrid(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = const Color(0xFF2D2D44)
      ..strokeWidth = 0.5;

    const gridSize = 50.0;
    for (double x = 0; x < size.width; x += gridSize) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y < size.height; y += gridSize) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
  }

  Color _getLayerColor(String layerName) {
    // Check hardcoded named colors first (avoids old ID mismatch in v7+ files)
    switch (layerName) {
      case 'F.Cu':
        return const Color(0xFFFF4444);
      case 'In1.Cu':
        return const Color(0xFF44FF44);
      case 'In2.Cu':
        return const Color(0xFFAA44FF);
      case 'B.Cu':
        return const Color(0xFF4488FF);
      case 'F.SilkS':
        return const Color(0xFFFFFF88);
      case 'B.SilkS':
        return const Color(0xFF88FFFF);
      case 'F.Mask':
        return const Color(0xFF88AA88);
      case 'B.Mask':
        return const Color(0xFF88AA88);
      case 'Edge.Cuts':
        return const Color(0xFFFFA500);
      case 'F.Fab':
        return const Color(0xFF888888);
      case 'B.Fab':
        return const Color(0xFF666666);
      case 'F.CrtYd':
        return const Color(0xFF444444);
      case 'B.CrtYd':
        return const Color(0xFF333333);
      default:
        // Fallback to layer color from file (may be black for unmapped IDs)
        for (final layer in pcb.layers) {
          if (layer.name == layerName) {
            final c = layer.color;
            if (c != const Color(0xFF000000)) return c;
            break;
          }
        }
        return const Color(0xFF555555);
    }
  }

  int _layerNameToId(String name) {
    for (final layer in pcb.layers) {
      if (layer.name == name) return layer.id;
    }
    return 0;
  }

  @override
  bool shouldRepaint(PCBPainter oldDelegate) {
    return oldDelegate.pcb != pcb ||
        oldDelegate.selectedElementId != selectedElementId ||
        oldDelegate.pcbSide != pcbSide ||
        oldDelegate.showPcbRefs != showPcbRefs;
  }
}
