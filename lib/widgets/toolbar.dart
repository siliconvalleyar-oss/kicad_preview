import 'package:flutter/material.dart';

class AppToolbar extends StatelessWidget {
  final VoidCallback onOpenFile;
  final String currentFileName;
  final String currentView;
  final ValueChanged<String> onViewChanged;
  final VoidCallback onToggleHierarchy;
  final VoidCallback onToggleLayers;

  const AppToolbar({
    super.key,
    required this.onOpenFile,
    required this.currentFileName,
    required this.currentView,
    required this.onViewChanged,
    required this.onToggleHierarchy,
    required this.onToggleLayers,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: const BoxDecoration(
        color: Color(0xFF2D2D44),
        border: Border(
          bottom: BorderSide(color: Color(0xFF3D3D5C)),
        ),
      ),
      child: Row(
        children: [
          // App icon/name
          const Icon(Icons.developer_board, color: Color(0xFF6C5CE7), size: 22),
          const SizedBox(width: 8),
          const Text(
            'KiCad Preview',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 20),
          // Open file button
          _ToolbarButton(
            icon: Icons.folder_open,
            label: 'Open',
            onPressed: onOpenFile,
          ),
          const SizedBox(width: 8),
          // Separator
          _buildSeparator(),
          // View buttons
          _ViewButton(
            label: 'Schematic',
            icon: Icons.schema,
            isActive: currentView == 'schematic',
            onPressed: () => onViewChanged('schematic'),
          ),
          _ViewButton(
            label: 'PCB',
            icon: Icons.grid_4x4,
            isActive: currentView == 'pcb',
            onPressed: () => onViewChanged('pcb'),
          ),
          _ViewButton(
            label: 'BOM',
            icon: Icons.list_alt,
            isActive: currentView == 'bom',
            onPressed: () => onViewChanged('bom'),
          ),
          const Spacer(),
          // Panel toggles
          _ToolbarButton(
            icon: Icons.account_tree,
            label: 'Hierarchy',
            onPressed: onToggleHierarchy,
          ),
          const SizedBox(width: 4),
          _ToolbarButton(
            icon: Icons.layers,
            label: 'Layers',
            onPressed: onToggleLayers,
          ),
        ],
      ),
    );
  }

  Widget _buildSeparator() {
    return Container(
      width: 1,
      height: 24,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      color: const Color(0xFF3D3D5C),
    );
  }
}

class _ToolbarButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  const _ToolbarButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: Colors.white.withValues(alpha: 0.8),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}

class _ViewButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isActive;
  final VoidCallback onPressed;

  const _ViewButton({
    required this.label,
    required this.icon,
    required this.isActive,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          foregroundColor:
              isActive ? const Color(0xFF6C5CE7) : Colors.white.withValues(alpha: 0.6),
          backgroundColor:
              isActive ? const Color(0xFF6C5CE7).withValues(alpha: 0.15) : null,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16),
            const SizedBox(width: 4),
            Text(label, style: const TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
