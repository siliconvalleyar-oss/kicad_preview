import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/schematic.dart';
import '../models/schematic_element.dart';
import '../controllers/app_state.dart';

class SchematicView extends StatefulWidget {
  final Schematic schematic;

  const SchematicView({super.key, required this.schematic});

  @override
  State<SchematicView> createState() => _SchematicViewState();
}

class _SchematicViewState extends State<SchematicView> {
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

    for (final wire in widget.schematic.wires) {
      for (final p in wire.points) {
        final x = p.x * 4;
        final y = p.y * 4;
        if (x < minX) minX = x; if (y < minY) minY = y;
        if (x > maxX) maxX = x; if (y > maxY) maxY = y;
      }
    }
    for (final junction in widget.schematic.junctions) {
      final x = junction.position.x * 4;
      final y = junction.position.y * 4;
      if (x < minX) minX = x; if (y < minY) minY = y;
      if (x > maxX) maxX = x; if (y > maxY) maxY = y;
    }
    for (final sheet in widget.schematic.sheets) {
      final x = (sheet.x + sheet.width) * 4;
      final y = (sheet.y + sheet.height) * 4;
      if (sheet.x * 4 < minX) minX = sheet.x * 4;
      if (sheet.y * 4 < minY) minY = sheet.y * 4;
      if (x > maxX) maxX = x; if (y > maxY) maxY = y;
    }
    for (final text in widget.schematic.texts) {
      final x = text.position.x * 4;
      final y = text.position.y * 4;
      if (x < minX) minX = x; if (y < minY) minY = y;
      if (x > maxX) maxX = x; if (y > maxY) maxY = y;
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
    return InteractiveViewer(
      transformationController: _transformController,
      boundaryMargin: const EdgeInsets.all(double.infinity),
      minScale: 0.1,
      maxScale: 10.0,
      onInteractionEnd: (details) {
        final matrix = _transformController.value;
        final scale = matrix.getMaxScaleOnAxis();
        final offset = Offset(matrix.getTranslation().x, matrix.getTranslation().y);
        context.read<AppState>().updateSchematicTransform(offset, scale);
      },
      child: SizedBox(
        width: 2000,
        height: 2000,
        child: GestureDetector(
          onTapDown: (details) {
            // Convert tap to schematic coordinates
            final matrix = _transformController.value;
            final scale = matrix.getMaxScaleOnAxis();
            final tx = matrix.getTranslation().x / scale;
            final ty = matrix.getTranslation().y / scale;
            final tapX = (details.localPosition.dx - tx) / scale;
            final tapY = (details.localPosition.dy - ty) / scale;

            // Find closest element
            _selectNearestElement(tapX, tapY);
          },
          child: RepaintBoundary(
            child: CustomPaint(
              painter: SchematicPainter(
                schematic: widget.schematic,
                selectedElementId:
                    context.watch<AppState>().selectedElementId,
                scale: _transformController.value.getMaxScaleOnAxis(),
              ),
              size: const Size(2000, 2000),
            ),
          ),
        ),
      ),
    );
  }

  void _selectNearestElement(double x, double y) {
    const double hitRadius = 20.0;
    String? closestId;
    double closestDist = double.infinity;

    for (final element in widget.schematic.elements) {
      for (final point in element.points) {
        final dist = (point.x - x).abs() + (point.y - y).abs();
        if (dist < hitRadius && dist < closestDist) {
          closestDist = dist;
          closestId = element.uuid ?? element.text;
        }
      }
    }

    context.read<AppState>().selectElement(closestId);
  }
}

class SchematicPainter extends CustomPainter {
  final Schematic schematic;
  final String? selectedElementId;
  final double scale;

  SchematicPainter({
    required this.schematic,
    this.selectedElementId,
    this.scale = 1.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Draw grid
    _drawGrid(canvas, size);

    // Draw wires
    for (final wire in schematic.wires) {
      final isSelected = wire.uuid == selectedElementId;
      final paint = Paint()
        ..color = isSelected
            ? const Color(0xFF6C5CE7)
            : const Color(0xFF4A90D9)
        ..strokeWidth = (wire.width > 0 ? wire.width : 0.3) * 4
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      if (isSelected) {
        paint.strokeWidth = paint.strokeWidth * 2;
      }

      for (int i = 0; i < wire.points.length - 1; i++) {
        final p1 = wire.points[i];
        final p2 = wire.points[i + 1];
        canvas.drawLine(
          Offset(p1.x * 4, p1.y * 4),
          Offset(p2.x * 4, p2.y * 4),
          paint,
        );
      }
    }

    // Draw junctions
    for (final junction in schematic.junctions) {
      final isSelected = junction.uuid == selectedElementId;
      final paint = Paint()
        ..color = isSelected
            ? const Color(0xFF6C5CE7)
            : const Color(0xFFE74C3C)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(
        Offset(junction.position.x * 4, junction.position.y * 4),
        4,
        paint,
      );
    }

    // Draw sheets (hierarchical blocks)
    for (final sheet in schematic.sheets) {
      final paint = Paint()
        ..color = const Color(0xFF2ECC71)
        ..strokeWidth = 1.5
        ..style = PaintingStyle.stroke;

      final rect = Rect.fromLTWH(
        sheet.x * 4,
        sheet.y * 4,
        sheet.width * 4,
        sheet.height * 4,
      );
      canvas.drawRect(rect, paint);

      // Draw sheet name
      final textPainter = TextPainter(
        text: TextSpan(
          text: sheet.name,
          style: const TextStyle(
            color: Color(0xFF2ECC71),
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(sheet.x * 4, sheet.y * 4 - 12));

      // Draw pins
      for (final pin in sheet.pins) {
        final pinPaint = Paint()
          ..color = const Color(0xFFE67E22)
          ..strokeWidth = 1.5;
        final pinPos = Offset(pin.position.x * 4, pin.position.y * 4);
        canvas.drawCircle(pinPos, 3, pinPaint);

        final pinText = TextPainter(
          text: TextSpan(
            text: pin.name,
            style: const TextStyle(color: Color(0xFFE67E22), fontSize: 7),
          ),
          textDirection: TextDirection.ltr,
        );
        pinText.layout();
        final offset = pin.rotation == 180
            ? Offset(pinPos.dx - pinText.width - 4, pinPos.dy - 4)
            : Offset(pinPos.dx + 4, pinPos.dy - 4);
        pinText.paint(canvas, offset);
      }
    }

    // Draw text labels
    for (final text in schematic.texts) {
      final textPainter = TextPainter(
        text: TextSpan(
          text: text.text,
          style: TextStyle(
            color: const Color(0xFFF1C40F),
            fontSize: text.size * 3,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(text.position.x * 4, text.position.y * 4),
      );
    }

    // Draw labels
    for (final element in schematic.elements) {
      if (element.type == SchematicElementType.label && element.text != null) {
        final textPainter = TextPainter(
          text: TextSpan(
            text: element.text,
            style: const TextStyle(
              color: Color(0xFF3498DB),
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
          textDirection: TextDirection.ltr,
        );
        textPainter.layout();
        if (element.points.isNotEmpty) {
          textPainter.paint(
            canvas,
            Offset(element.points[0].x * 4, element.points[0].y * 4 - 8),
          );
        }
      }
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

  @override
  bool shouldRepaint(SchematicPainter oldDelegate) {
    return oldDelegate.schematic != schematic ||
        oldDelegate.selectedElementId != selectedElementId;
  }
}
