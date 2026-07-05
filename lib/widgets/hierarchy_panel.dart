import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/app_state.dart';

class HierarchyPanel extends StatelessWidget {
  const HierarchyPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final sheets = appState.sheets;
    final rootName = appState.rootFileName;
    final currentName = appState.currentFileName;
    final isRoot = currentName == rootName || currentName.isEmpty;

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
            child: Row(
              children: [
                const Icon(Icons.account_tree,
                    size: 16, color: Color(0xFF6C5CE7)),
                const SizedBox(width: 8),
                Text(
                  'Hierarchy',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          // Sheet tree
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 4),
              children: [
                // Root sheet
                _SheetItem(
                  name: rootName.isNotEmpty ? rootName : 'Root',
                  isRoot: true,
                  isSelected: isRoot,
                  onTap: () {
                    if (!isRoot) appState.navigateToRoot();
                  },
                ),
                // Sub-sheets
                ...sheets.map((sheet) => _SheetItem(
                      name: sheet.name.isNotEmpty ? sheet.name : sheet.fileName,
                      fileName: sheet.fileName,
                      isRoot: false,
                      isSelected: currentName == sheet.fileName,
                      onTap: () => appState.navigateToSheet(sheet.fileName),
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SheetItem extends StatelessWidget {
  final String name;
  final String? fileName;
  final bool isRoot;
  final bool isSelected;
  final VoidCallback onTap;

  const _SheetItem({
    required this.name,
    this.fileName,
    required this.isRoot,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.only(
          left: isRoot ? 12 : 28,
          right: 12,
          top: 6,
          bottom: 6,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF6C5CE7).withValues(alpha: 0.15)
              : null,
          border: const Border(
            bottom: BorderSide(color: Color(0xFF3D3D5C), width: 0.5),
          ),
        ),
        child: Row(
          children: [
            Icon(
              isRoot ? Icons.folder : Icons.description,
              size: 14,
              color: isRoot
                  ? const Color(0xFFF1C40F)
                  : const Color(0xFF2ECC71),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 12,
                      fontWeight: isRoot ? FontWeight.w600 : FontWeight.normal,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (fileName != null && !isRoot)
                    Text(
                      fileName!,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.4),
                        fontSize: 10,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
