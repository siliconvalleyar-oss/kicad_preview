import 'package:flutter/material.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../models/schematic.dart';

class BomView extends StatelessWidget {
  final List<BomItem> items;

  const BomView({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inventory_2_outlined,
                size: 64, color: Colors.white.withOpacity(0.3)),
            const SizedBox(height: 16),
            Text(
              'No components found',
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Export button
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: const BoxDecoration(
            color: Color(0xFF2D2D44),
            border: Border(
              bottom: BorderSide(color: Color(0xFF3D3D5C)),
            ),
          ),
          child: Row(
            children: [
              const Icon(Icons.list_alt, color: Color(0xFF6C5CE7), size: 20),
              const SizedBox(width: 8),
              Text(
                'Bill of Materials',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Text(
                '${items.length} items',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.5),
                  fontSize: 13,
                ),
              ),
              const SizedBox(width: 12),
              _buildExportButton(context),
            ],
          ),
        ),
        // Table
        Expanded(
          child: ListView.builder(
            itemCount: items.length + 1, // +1 for header
            itemBuilder: (context, index) {
              if (index == 0) {
                return _buildHeader();
              }
              return _buildItemRow(items[index - 1], index);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildExportButton(BuildContext context) {
    return TextButton.icon(
      onPressed: () => _exportToCsv(context),
      icon: const Icon(Icons.download, size: 16),
      label: const Text('CSV', style: TextStyle(fontSize: 12)),
      style: TextButton.styleFrom(
        foregroundColor: const Color(0xFF6C5CE7),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: const Color(0xFF353550),
      child: Row(
        children: [
          _buildCell('#', 40),
          _buildCell('Reference', 120),
          _buildCell('Value', 100),
          _buildCell('Footprint', 150),
          _buildCell('Qty', 50),
        ],
      ),
    );
  }

  Widget _buildItemRow(BomItem item, int index) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: index.isEven ? const Color(0xFF262640) : const Color(0xFF2A2A45),
        border: const Border(
          bottom: BorderSide(color: Color(0xFF3D3D5C), width: 0.5),
        ),
      ),
      child: Row(
        children: [
          _buildCell('$index', 40),
          _buildCell(item.reference, 120),
          _buildCell(item.value, 100),
          _buildCell(item.footprint, 150),
          _buildCell('${item.quantity}', 50),
        ],
      ),
    );
  }

  Widget _buildCell(String text, double width) {
    return SizedBox(
      width: width,
      child: Text(
        text,
        style: TextStyle(
          color: Colors.white.withOpacity(0.8),
          fontSize: 12,
        ),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Future<void> _exportToCsv(BuildContext context) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/bom_export.csv');
      final buffer = StringBuffer();
      buffer.writeln(BomItem.csvHeader());
      for (final item in items) {
        buffer.writeln(item.toCsvLine());
      }
      await file.writeAsString(buffer.toString(), flush: true);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('BOM exported to ${file.path}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
