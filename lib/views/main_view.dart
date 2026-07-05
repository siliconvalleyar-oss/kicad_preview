import 'dart:async';
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
import '../widgets/notes_panel.dart';
import '../models/schematic.dart';
import 'package:file_picker/file_picker.dart';

// ignore: depend_on_referenced_packages
import 'dart:convert' show utf8;

/// Available KiCad files bundled in assets.
const List<Map<String, String>> _kicadFiles = [
  {'name': 'project_pi (Main)', 'sch': 'project_pi.kicad_sch', 'pcb': ''},
  {'name': 'POWER (Sub-sheet)', 'sch': 'POWER.kicad_sch', 'pcb': ''},
  {'name': 'BUTONS (Sub-sheet)', 'sch': 'BUTONS.kicad_sch', 'pcb': ''},
  {'name': 'display (Sub-sheet)', 'sch': 'display.kicad_sch', 'pcb': ''},
  {'name': 'LIPO_CHARGER (Sub-sheet)', 'sch': 'LIPO_CHARGER.kicad_sch', 'pcb': ''},
  {'name': 'microSD (Sub-sheet)', 'sch': 'microSD.kicad_sch', 'pcb': ''},
];

class MainView extends StatefulWidget {
  const MainView({super.key});

  @override
  State<MainView> createState() => _MainViewState();
}

class _MainViewState extends State<MainView> {
  Timer? _panelTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDemoProject();
    });
  }

  @override
  void dispose() {
    _panelTimer?.cancel();
    super.dispose();
  }

  void _startPanelTimer() {
    _panelTimer?.cancel();
    _panelTimer = Timer(const Duration(seconds: 2), () {
      if (!mounted) return;
      final appState = context.read<AppState>();
      if (appState.currentView == 'schematic' && appState.showHierarchy) {
        appState.toggleHierarchy();
      } else if (appState.currentView == 'pcb' && appState.showLayers) {
        appState.toggleLayers();
      }
    });
  }

  void _onPanelInteracted() {
    _panelTimer?.cancel();
    _startPanelTimer();
  }

  Future<void> _loadDemoProject() async {
    final appState = context.read<AppState>();
    try {
      final schContent = await rootBundle.loadString(
        'assets/files_kicad/project_pi.kicad_sch',
      );
      await appState.loadSchematic(schContent, fileName: 'project_pi.kicad_sch', isRoot: true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading demo: $e')),
        );
      }
    }
  }

  void _openFile() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF2D2D44),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Icon(Icons.folder_open, color: Color(0xFF6C5CE7), size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Open Project',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(color: Color(0xFF3D3D5C), height: 1),
                ..._kicadFiles.map((f) => ListTile(
                  leading: const Icon(Icons.developer_board,
                      color: Color(0xFF6C5CE7)),
                  title: Text(
                    f['name']!,
                    style: const TextStyle(color: Colors.white),
                  ),
                  subtitle: const Text('Tap to load',
                      style: TextStyle(color: Colors.white54, fontSize: 11)),
                  onTap: () {
                    Navigator.pop(ctx);
                    _loadAssetProject(f['sch']!, f['pcb']!);
                  },
                )),
            const Divider(color: Color(0xFF3D3D5C), height: 1),
            ListTile(
              leading:
                  const Icon(Icons.phone_android, color: Color(0xFF6C5CE7)),
              title: const Text('Browse device storage...',
                  style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(ctx);
                _pickFromDevice();
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _loadAssetProject(String schFile, String pcbFile) async {
    final appState = context.read<AppState>();
    try {
      final schContent =
          await rootBundle.loadString('assets/files_kicad/$schFile');
      await appState.loadSchematic(schContent, fileName: schFile, isRoot: true);

      try {
        final pcbContent =
            await rootBundle.loadString('assets/files_kicad/$pcbFile');
        await appState.loadPCB(pcbContent, fileName: pcbFile);
      } catch (_) {
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Loaded: ${schFile.replaceAll('.kicad_sch', '')}')),
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

  Future<void> _pickFromDevice() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.any,
      withData: true,
    );

    if (result != null && result.files.isNotEmpty) {
      final file = result.files.first;
      final appState = context.read<AppState>();

      try {
        String content;
        if (file.bytes != null) {
          content = utf8.decode(file.bytes!);
        } else {
          content = '';
        }

        final fileName = file.name;

        if (fileName.endsWith('.kicad_sch')) {
          await appState.loadSchematic(content, fileName: fileName);
        } else if (fileName.endsWith('.kicad_pcb')) {
          await appState.loadPCB(content, fileName: fileName);
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Unsupported file type')),
            );
          }
          return;
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
                  onToggleHierarchy: () {
                    appState.toggleHierarchy();
                    if (appState.showHierarchy) _startPanelTimer();
                  },
                  onToggleLayers: () {
                    appState.toggleLayers();
                    if (appState.showLayers) _startPanelTimer();
                  },
                  onToggleNames: () => appState.toggleComponentNames(),
                  onToggleValues: () => appState.toggleComponentValues(),
                  onToggleNotes: () => appState.toggleNotes(),
                  showNames: appState.showComponentNames,
                  showValues: appState.showComponentValues,
                  showNotes: appState.showNotes,
                ),
                Expanded(
                  child: Row(
                    children: [
                      if (appState.showHierarchy &&
                          appState.currentView == 'schematic')
                        GestureDetector(
                          onTap: _onPanelInteracted,
                          onPanDown: (_) => _onPanelInteracted(),
                          child: const HierarchyPanel(),
                        ),
                      if (appState.showLayers &&
                          appState.currentView == 'pcb')
                        GestureDetector(
                          onTap: _onPanelInteracted,
                          onPanDown: (_) => _onPanelInteracted(),
                          child: const LayerPanel(),
                        ),
                      Expanded(
                        child: _buildCanvas(appState),
                      ),
                      if (appState.showNotes)
                        const NotesPanel(),
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
          key: ValueKey('sch_${appState.currentFileName}'),
          schematic: appState.schematic!,
        );
      case 'pcb':
        if (appState.pcb == null) {
          return _buildEmptyState('No PCB loaded');
        }
        return PCBView(
          key: ValueKey('pcb_${appState.currentFileName}'),
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
            'KiCad Preview v1.0.7',
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
