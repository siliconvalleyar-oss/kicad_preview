import 'package:flutter/material.dart';

class AppToolbar extends StatelessWidget {
  final VoidCallback onOpenFile;
  final String currentFileName;
  final String currentView;
  final ValueChanged<String> onViewChanged;
  final VoidCallback onToggleHierarchy;
  final VoidCallback onToggleLayers;
  final VoidCallback onToggleNames;
  final VoidCallback onToggleValues;
  final VoidCallback onToggleNotes;
  final bool showNames;
  final bool showValues;
  final bool showNotes;
  final bool showPcbRefs;
  final VoidCallback? onTogglePcbRefs;
  final VoidCallback? onTogglePcbSide;
  final VoidCallback? onTogglePcbFlipped;
  final VoidCallback? onCenterPCB;

  const AppToolbar({
    super.key,
    required this.onOpenFile,
    required this.currentFileName,
    required this.currentView,
    required this.onViewChanged,
    required this.onToggleHierarchy,
    required this.onToggleLayers,
    required this.onToggleNames,
    required this.onToggleValues,
    required this.onToggleNotes,
    required this.showNames,
    required this.showValues,
    required this.showNotes,
    this.showPcbRefs = false,
    this.onTogglePcbRefs,
    this.onTogglePcbSide,
    this.onTogglePcbFlipped,
    this.onCenterPCB,
  });

  @override
  Widget build(BuildContext context) {
    final isPortrait = MediaQuery.of(context).orientation == Orientation.portrait;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: const BoxDecoration(
        color: Color(0xFF2D2D44),
        border: Border(
          bottom: BorderSide(color: Color(0xFF3D3D5C)),
        ),
      ),
      child: Row(
        children: [
          // App icon only (no text)
          const Icon(Icons.developer_board, color: Color(0xFF6C5CE7), size: 20),
          if (isPortrait) ...[
            const SizedBox(width: 4),
            _ToolbarButton(
              icon: Icons.folder_open,
              label: '',
              onPressed: onOpenFile,
            ),
          ] else ...[
            const SizedBox(width: 12),
            _ToolbarButton(
              icon: Icons.folder_open,
              label: 'Open',
              onPressed: onOpenFile,
            ),
          ],
          const SizedBox(width: 4),
          _buildSeparator(),
          if (isPortrait) ...[
            _IconButton(
              icon: Icons.schema,
              isActive: currentView == 'schematic',
              onPressed: () => onViewChanged('schematic'),
            ),
            _IconButton(
              icon: Icons.grid_4x4,
              isActive: currentView == 'pcb',
              onPressed: () => onViewChanged('pcb'),
            ),
            _IconButton(
              icon: Icons.list_alt,
              isActive: currentView == 'bom',
              onPressed: () => onViewChanged('bom'),
            ),
          ] else ...[
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
          ],
          const Spacer(),
          if (currentView == 'pcb') ...[
            if (!isPortrait) ...[
              _ToggleButton(
                icon: Icons.refresh,
                label: 'Refs',
                isActive: showPcbRefs,
                onPressed: onTogglePcbRefs ?? () {},
              ),
              const SizedBox(width: 2),
              _ToolbarButton(
                icon: Icons.flip_to_front,
                label: 'Side',
                onPressed: onTogglePcbSide ?? () {},
              ),
              const SizedBox(width: 2),
              _ToolbarButton(
                icon: Icons.flip,
                label: 'Flip',
                onPressed: onTogglePcbFlipped ?? () {},
              ),
              const SizedBox(width: 2),
            ],
            _ToolbarButton(
              icon: Icons.center_focus_strong,
              label: isPortrait ? '' : 'Center',
              onPressed: onCenterPCB ?? () {},
            ),
            if (!isPortrait) ...[
              const SizedBox(width: 4),
              _buildSeparator(),
              const SizedBox(width: 4),
            ],
          ],
          // Panel toggles (icons only in portrait)
          if (isPortrait) ...[
            _IconButton(
              icon: Icons.account_tree,
              isActive: false,
              onPressed: onToggleHierarchy,
            ),
            _IconButton(
              icon: Icons.layers,
              isActive: false,
              onPressed: onToggleLayers,
            ),
            _IconButton(
              icon: Icons.note_alt,
              isActive: showNotes,
              onPressed: onToggleNotes,
            ),
          ] else ...[
            _ToolbarButton(
              icon: Icons.account_tree,
              label: 'Hierarchy',
              onPressed: onToggleHierarchy,
            ),
            const SizedBox(width: 2),
            _ToolbarButton(
              icon: Icons.layers,
              label: 'Layers',
              onPressed: onToggleLayers,
            ),
            const SizedBox(width: 4),
            _buildSeparator(),
            const SizedBox(width: 4),
            _ToggleButton(
              icon: Icons.note_alt,
              label: 'Notes',
              isActive: showNotes,
              onPressed: onToggleNotes,
            ),
          ],
          if (currentView == 'schematic' && !isPortrait) ...[
            const SizedBox(width: 4),
            _buildSeparator(),
            const SizedBox(width: 4),
            _ToggleButton(
              icon: Icons.text_fields,
              label: 'Names',
              isActive: showNames,
              onPressed: onToggleNames,
            ),
            const SizedBox(width: 2),
            _ToggleButton(
              icon: Icons.numbers,
              label: 'Values',
              isActive: showValues,
              onPressed: onToggleValues,
            ),
          ],
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

class _IconButton extends StatelessWidget {
  final IconData icon;
  final bool isActive;
  final VoidCallback onPressed;

  const _IconButton({
    required this.icon,
    required this.isActive,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 1),
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          foregroundColor:
              isActive ? const Color(0xFF6C5CE7) : Colors.white.withValues(alpha: 0.6),
          backgroundColor:
              isActive ? const Color(0xFF6C5CE7).withValues(alpha: 0.15) : null,
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        child: Icon(icon, size: 18),
      ),
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

class _ToggleButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onPressed;

  const _ToggleButton({
    required this.icon,
    required this.label,
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
