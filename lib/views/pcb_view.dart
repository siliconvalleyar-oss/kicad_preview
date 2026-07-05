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
  void dispose() {
    _transformController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return InteractiveViewer(
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
              selectedElementId:
                  context.watch<AppState>().selectedElementId,
            ),
            size: const Size(2000, 2000),
          ),
        ),
      ),
    );
  }
}

class PCBPainter extends CustomPainter {
  final PCB pcb;
  final String? selectedElementId;

  PCBPainter({required this.pcb, this.selectedElementId});

  @override
  void paint(Canvas canvas, Size size) {
    _drawGrid(canvas, size);

    // Draw graphical lines on Edge.Cuts and other layers
    for (final line in pcb.graphicalLines) {
      final layer = pcb.getLayerById(_layerNameToId(line.layer));
      if (layer != null && !layer.visible) continue;

      final paint = Paint()
        ..color = _getLayerColor(line.layer)
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
      final paint = Paint()
        ..color = isSelected
            ? const Color(0xFF6C5CE7)
            : _getLayerColor(track.layer)
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
      _drawFootprint(canvas, fp);
    }
  }

  void _drawFootprint(Canvas canvas, PCBFootprint fp) {
    final offset = Offset(fp.x * 10, fp.y * 10);
    final fpLayer = fp.layer != null
        ? pcb.getLayerById(_layerNameToId(fp.layer!))
        : null;
    final fpVisible = fpLayer == null || fpLayer.visible;

    if (!fpVisible) return;

    // Draw pads
    for (final pad in fp.pads) {
      final layer = pad.layers.isNotEmpty
          ? pcb.getLayerById(_layerNameToId(pad.layers.first))
          : null;
      if (layer != null && !layer.visible) continue;

      final paint = Paint()
        ..color = const Color(0xFFC0C0C0)
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

      final paint = Paint()
        ..color = _getLayerColor(line.layer)
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

      final textPainter = TextPainter(
        text: TextSpan(
          text: text.text,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.7),
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

    // Draw reference text (always on F.SilkS)
    final refLayer = pcb.getLayerById(_layerNameToId('F.SilkS'));
    if (refLayer == null || refLayer.visible) {
      final textPainter = TextPainter(
        text: TextSpan(
          text: fp.reference,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.7),
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
    for (final layer in pcb.layers) {
      if (layer.name == layerName) {
        return layer.color;
      }
    }
    switch (layerName) {
      case 'F.Cu':
        return const Color(0xFFFF4444);
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
        oldDelegate.selectedElementId != selectedElementId;
  }
}
