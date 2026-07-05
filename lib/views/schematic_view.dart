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

    void updateBounds(double x, double y) {
      if (x < minX) minX = x; if (y < minY) minY = y;
      if (x > maxX) maxX = x; if (y > maxY) maxY = y;
    }

    for (final wire in widget.schematic.wires) {
      for (final p in wire.points) {
        updateBounds(p.x * 4, p.y * 4);
      }
    }
    for (final junction in widget.schematic.junctions) {
      updateBounds(junction.position.x * 4, junction.position.y * 4);
    }
    for (final sheet in widget.schematic.sheets) {
      updateBounds(sheet.x * 4, sheet.y * 4);
      updateBounds((sheet.x + sheet.width) * 4, (sheet.y + sheet.height) * 4);
    }
    for (final text in widget.schematic.texts) {
      updateBounds(text.position.x * 4, text.position.y * 4);
    }
    for (final el in widget.schematic.elements) {
      if (el.type == SchematicElementType.symbol && el.points.isNotEmpty) {
        updateBounds(el.points[0].x * 4, el.points[0].y * 4);
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
            showNames: context.watch<AppState>().showComponentNames,
            showValues: context.watch<AppState>().showComponentValues,
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
  final bool showNames;
  final bool showValues;

  SchematicPainter({
    required this.schematic,
    this.selectedElementId,
    this.scale = 1.0,
    this.showNames = true,
    this.showValues = true,
  });

  @override
  void paint(Canvas canvas, Size size) {
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

    // Draw symbols (component bodies + text)
    for (final element in schematic.elements) {
      if (element.type != SchematicElementType.symbol) continue;
      if (element.points.isEmpty) continue;

      final pos = element.points[0];
      final cx = pos.x * 4;
      final cy = pos.y * 4;
      final libId = element.properties['lib_id'] ?? '';
      final isSelected = element.uuid == selectedElementId;

      // Draw body
      final bodyPaint = Paint()
        ..color = isSelected
            ? const Color(0xFF6C5CE7)
            : const Color(0xFF8E44AD)
        ..strokeWidth = 1.5
        ..style = PaintingStyle.stroke;

      final bodyFill = Paint()
        ..color = const Color(0xFF2D2D44)
        ..style = PaintingStyle.fill;

      // Try to use actual dimensions from lib_symbol parsing
      final bodies = schematic.symbolBodies[libId];
      if (bodies != null && bodies.isNotEmpty) {
        for (final rect in bodies) {
          final rcx = cx + rect.x * 4;
          final rcy = cy + rect.y * 4;
          final rw = rect.w * 4;
          final rh = rect.h * 4;
          final rrect = RRect.fromRectAndRadius(
            Rect.fromCenter(center: Offset(rcx, rcy), width: rw, height: rh),
            const Radius.circular(1),
          );
          canvas.drawRRect(rrect, bodyFill);
          canvas.drawRRect(rrect, bodyPaint);
        }
      } else if (libId.startsWith('power:')) {
        _drawPowerSymbol(canvas, cx, cy, libId, bodyPaint);
      } else if (libId.contains(':R_') || libId == 'Device:R') {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: Offset(cx, cy), width: 20, height: 10),
            const Radius.circular(1),
          ),
          bodyFill,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: Offset(cx, cy), width: 20, height: 10),
            const Radius.circular(1),
          ),
          bodyPaint,
        );
      } else if (libId.contains(':C_') || libId == 'Device:C') {
        canvas.drawLine(Offset(cx - 4, cy - 6), Offset(cx - 4, cy + 6), bodyPaint);
        canvas.drawLine(Offset(cx + 4, cy - 6), Offset(cx + 4, cy + 6), bodyPaint);
      } else if (libId.contains(':D_') || libId == 'Device:D') {
        final path = Path()
          ..moveTo(cx, cy - 8)
          ..lineTo(cx + 8, cy)
          ..lineTo(cx, cy + 8)
          ..close();
        canvas.drawPath(path, bodyPaint);
        canvas.drawLine(Offset(cx - 4, cy - 8), Offset(cx - 4, cy + 8), bodyPaint);
      } else if (libId.contains(':Q_') || libId.contains('Transistor')) {
        canvas.drawCircle(Offset(cx, cy), 10, bodyFill);
        canvas.drawCircle(Offset(cx, cy), 10, bodyPaint);
      } else {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: Offset(cx, cy), width: 16, height: 14),
            const Radius.circular(2),
          ),
          bodyFill,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: Offset(cx, cy), width: 16, height: 14),
            const Radius.circular(2),
          ),
          bodyPaint,
        );
      }

      // Draw reference name (e.g. R1, U1)
      if (showNames && element.text != null) {
        final refX = double.tryParse(element.properties['ref_x'] ?? '${pos.x}') ?? pos.x;
        final refY = double.tryParse(element.properties['ref_y'] ?? '${pos.y - 1}') ?? pos.y - 1;
        final namePainter = TextPainter(
          text: TextSpan(
            text: element.text,
            style: TextStyle(
              color: isSelected ? const Color(0xFF6C5CE7) : Colors.white,
              fontSize: 8,
              fontWeight: FontWeight.bold,
            ),
          ),
          textDirection: TextDirection.ltr,
        );
        namePainter.layout();
        namePainter.paint(canvas, Offset(refX * 4, refY * 4));
      }

      // Draw value (e.g. 10k, 100nF)
      if (showValues) {
        final value = element.properties['Value'] ?? '';
        if (value.isNotEmpty) {
          final valX = double.tryParse(element.properties['val_x'] ?? '${pos.x}') ?? pos.x;
          final valY = double.tryParse(element.properties['val_y'] ?? '${pos.y + 1}') ?? pos.y + 1;
          final valPainter = TextPainter(
            text: TextSpan(
              text: value,
              style: TextStyle(
                color: isSelected ? const Color(0xFF6C5CE7) : const Color(0xFFF39C12),
                fontSize: 7,
              ),
            ),
            textDirection: TextDirection.ltr,
          );
          valPainter.layout();
          valPainter.paint(canvas, Offset(valX * 4, valY * 4));
        }
      }
    }
  }

  void _drawPowerSymbol(Canvas canvas, double cx, double cy, String libId, Paint paint) {
    final isGround = libId.contains('GND') || libId.contains('gnd');
    if (isGround) {
      final path = Path()
        ..moveTo(cx - 6, cy + 4)
        ..lineTo(cx + 6, cy + 4)
        ..moveTo(cx, cy + 4)
        ..lineTo(cx, cy - 4)
        ..moveTo(cx - 3, cy + 1)
        ..lineTo(cx + 3, cy + 1);
      canvas.drawPath(path, paint);
    } else {
      canvas.drawCircle(Offset(cx, cy), 4, paint..style = PaintingStyle.stroke);
      canvas.drawLine(Offset(cx, cy - 4), Offset(cx, cy + 4), paint);
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
        oldDelegate.selectedElementId != selectedElementId ||
        oldDelegate.showNames != showNames ||
        oldDelegate.showValues != showValues;
  }
}
