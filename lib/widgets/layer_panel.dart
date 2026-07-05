import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/app_state.dart';

class LayerPanel extends StatelessWidget {
  const LayerPanel({super.key});

  @override
  Widget build(BuildContext context) {
    context.select<AppState, int>((s) => s.layersVersion);
    final appState = context.read<AppState>();
    final pcb = appState.pcb;
    if (pcb == null) return const SizedBox.shrink();

    // Group layers by category
    final signalLayers = pcb.layers.where((l) => l.type == 'signal').toList();
    final userLayers =
        pcb.layers.where((l) => l.type == 'user').toList();

    return Container(
      width: 200,
      decoration: const BoxDecoration(
        color: Color(0xFF252540),
        border: Border(
          right: BorderSide(color: Color(0xFF3D3D5C)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: const BoxDecoration(
              color: Color(0xFF2D2D44),
              border: Border(
                bottom: BorderSide(color: Color(0xFF3D3D5C)),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.layers, size: 16, color: Color(0xFF6C5CE7)),
                    const SizedBox(width: 8),
                    Text(
                      'Layers',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${pcb.layers.length}',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.4),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    _ActionChip(
                      label: 'Basic',
                      onTap: () => appState.showBasicLayers(),
                    ),
                    const SizedBox(width: 4),
                    _ActionChip(
                      label: 'All',
                      onTap: () => appState.showAllLayers(),
                    ),
                    const SizedBox(width: 4),
                    _ActionChip(
                      label: 'None',
                      onTap: () => appState.hideAllLayers(),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Layer list
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 4),
              children: [
                // Signal layers
                _buildSectionHeader('Copper'),
                ...signalLayers.map((layer) => _LayerItem(
                      layerId: layer.id,
                      name: layer.name,
                      color: layer.color,
                      visible: layer.visible,
                      onToggle: () => appState.toggleLayer(layer.id),
                    )),
                const SizedBox(height: 8),
                // User layers
                _buildSectionHeader('Technical'),
                ...userLayers.map((layer) => _LayerItem(
                      layerId: layer.id,
                      name: layer.name,
                      color: layer.color,
                      visible: layer.visible,
                      onToggle: () => appState.toggleLayer(layer.id),
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      child: Text(
        title,
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.4),
          fontSize: 10,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _ActionChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _ActionChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: const Color(0xFF6C5CE7).withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: const Color(0xFF6C5CE7).withValues(alpha: 0.4),
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: const Color(0xFF6C5CE7).withValues(alpha: 0.9),
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _LayerItem extends StatelessWidget {
  final int layerId;
  final String name;
  final Color color;
  final bool visible;
  final VoidCallback onToggle;

  const _LayerItem({
    required this.layerId,
    required this.name,
    required this.color,
    required this.visible,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onToggle,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        child: Row(
          children: [
            // Visibility checkbox
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: visible ? color.withValues(alpha: 0.3) : Colors.transparent,
                border: Border.all(
                  color: visible
                      ? color
                      : Colors.white.withValues(alpha: 0.3),
                  width: 1.5,
                ),
                borderRadius: BorderRadius.circular(3),
              ),
              child: visible
                  ? Icon(Icons.check, size: 11, color: color)
                  : null,
            ),
            const SizedBox(width: 8),
            // Color indicator
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 8),
            // Layer name
            Expanded(
              child: Text(
                name,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: visible ? 0.9 : 0.4),
                  fontSize: 12,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
