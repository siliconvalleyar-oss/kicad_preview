import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../controllers/app_state.dart';
import 'schematic_view.dart';
import 'pcb_view.dart';
import 'bom_view.dart';
import '../widgets/toolbar.dart';
import '../widgets/hierarchy_panel.dart';
import '../widgets/layer_panel.dart';
import '../models/schematic.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';

class MainView extends StatefulWidget {
  const MainView({super.key});

  @override
  State<MainView> createState() => _MainViewState();
}

class _MainViewState extends State<MainView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDemoProject();
    });
  }

  Future<void> _loadDemoProject() async {
    final appState = context.read<AppState>();
    try {
      final schContent = await rootBundle.loadString(
        'assets/files_kicad/cnc_pic32.kicad_sch',
      );
      await appState.loadSchematic(schContent, fileName: 'cnc_pic32.kicad_sch');

      try {
        final pcbContent = await rootBundle.loadString(
          'assets/files_kicad/cnc_pic32.kicad_pcb',
        );
        await appState.loadPCB(pcbContent, fileName: 'cnc_pic32.kicad_pcb');
      } catch (_) {
        // PCB loading is optional
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading demo: $e')),
        );
      }
    }
  }

  Future<void> _openFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['kicad_sch', 'kicad_pcb'],
    );

    if (result != null && result.files.isNotEmpty) {
      final file = result.files.first;
      final appState = context.read<AppState>();

      try {
        final content = await File(file.path!).readAsString();
        final fileName = file.name;

        if (fileName.endsWith('.kicad_sch')) {
          await appState.loadSchematic(content, fileName: fileName);
        } else if (fileName.endsWith('.kicad_pcb')) {
          await appState.loadPCB(content, fileName: fileName);
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Loaded: $fileName')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E2E),
      body: SafeArea(
        child: Consumer<AppState>(
          builder: (context, appState, _) {
            return Column(
              children: [
                AppToolbar(
                  onOpenFile: _openFile,
                  currentFileName: appState.currentFileName,
                  currentView: appState.currentView,
                  onViewChanged: (view) => appState.setView(view),
                  onToggleHierarchy: () => appState.toggleHierarchy(),
                  onToggleLayers: () => appState.toggleLayers(),
                ),
                Expanded(
                  child: Row(
                    children: [
                      if (appState.showHierarchy &&
                          appState.currentView == 'schematic')
                        const HierarchyPanel(),
                      if (appState.showLayers &&
                          appState.currentView == 'pcb')
                        const LayerPanel(),
                      Expanded(
                        child: _buildCanvas(appState),
                      ),
                    ],
                  ),
                ),
                _buildStatusBar(appState),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildCanvas(AppState appState) {
    if (appState.isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6C5CE7)),
        ),
      );
    }

    if (appState.error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline,
                  size: 48, color: Color(0xFFE74C3C)),
              const SizedBox(height: 16),
              Text(
                appState.error!,
                style: const TextStyle(color: Color(0xFFE74C3C)),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => appState.clearError(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6C5CE7),
                ),
                child: const Text('Dismiss'),
              ),
            ],
          ),
        ),
      );
    }

    switch (appState.currentView) {
      case 'schematic':
        if (appState.schematic == null) {
          return _buildEmptyState('No schematic loaded');
        }
        return SchematicView(
          schematic: appState.schematic!,
        );
      case 'pcb':
        if (appState.pcb == null) {
          return _buildEmptyState('No PCB loaded');
        }
        return PCBView(
          pcb: appState.pcb!,
        );
      case 'bom':
        if (appState.schematic == null) {
          return _buildEmptyState('No schematic loaded for BOM');
        }
        return BomView(
          items: appState.bomItems,
        );
      default:
        return _buildEmptyState('Select a view');
    }
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.developer_board,
              size: 64, color: Colors.white.withAlpha(77)),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              color: Colors.white.withAlpha(128),
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _openFile,
            icon: const Icon(Icons.folder_open),
            label: const Text('Open File'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6C5CE7),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBar(AppState appState) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: const BoxDecoration(
        color: Color(0xFF2D2D44),
        border: Border(
          top: BorderSide(color: Color(0xFF3D3D5C)),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.insert_drive_file,
              size: 14, color: Colors.white.withAlpha(128)),
          const SizedBox(width: 6),
          Text(
            appState.currentFileName.isNotEmpty
                ? appState.currentFileName
                : 'No file',
            style: TextStyle(
              color: Colors.white.withAlpha(128),
              fontSize: 12,
            ),
          ),
          if (appState.schematic != null) ...[
            const SizedBox(width: 16),
            Text(
              'Sheets: ${appState.sheets.length}',
              style: TextStyle(
                color: Colors.white.withAlpha(102),
                fontSize: 11,
              ),
            ),
          ],
          if (appState.pcb != null) ...[
            const SizedBox(width: 16),
            Text(
              'Layers: ${appState.pcb!.layers.length}',
              style: TextStyle(
                color: Colors.white.withAlpha(102),
                fontSize: 11,
              ),
            ),
            const SizedBox(width: 16),
            Text(
              'Footprints: ${appState.pcb!.footprints.length}',
              style: TextStyle(
                color: Colors.white.withAlpha(102),
                fontSize: 11,
              ),
            ),
          ],
          const Spacer(),
          Text(
            'KiCad Preview v1.0.0',
            style: TextStyle(
              color: Colors.white.withAlpha(77),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}
