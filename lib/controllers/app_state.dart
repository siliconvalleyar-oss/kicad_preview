import 'package:flutter/material.dart';
import '../models/schematic.dart';
import '../models/pcb.dart';
import '../models/schematic_element.dart';
import '../models/pcb_element.dart';
import '../parsers/schematic_parser.dart';
import '../parsers/pcb_parser.dart';

/// Main application state using ChangeNotifier pattern.
class AppState extends ChangeNotifier {
  Schematic? _schematic;
  PCB? _pcb;
  bool _isLoading = false;
  String? _error;
  String _currentFileName = '';
  String _currentView = 'schematic'; // 'schematic', 'pcb', 'bom'
  String? _selectedElementId;
  bool _showHierarchy = true;
  bool _showLayers = true;

  // Schematic view state
  Offset _schematicOffset = Offset.zero;
  double _schematicScale = 1.0;

  // PCB view state
  Offset _pcbOffset = Offset.zero;
  double _pcbScale = 1.0;

  // Getters
  Schematic? get schematic => _schematic;
  PCB? get pcb => _pcb;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get currentFileName => _currentFileName;
  String get currentView => _currentView;
  String? get selectedElementId => _selectedElementId;
  bool get showHierarchy => _showHierarchy;
  bool get showLayers => _showLayers;
  Offset get schematicOffset => _schematicOffset;
  double get schematicScale => _schematicScale;
  Offset get pcbOffset => _pcbOffset;
  double get pcbScale => _pcbScale;

  List<BomItem> get bomItems {
    if (_schematic == null) return [];
    return SchematicParser.generateBom(_schematic!);
  }

  /// Load a schematic file from raw content.
  Future<void> loadSchematic(String content, {String fileName = ''}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _schematic = SchematicParser.parse(content, fileName: fileName);
      _currentFileName = fileName;
      _currentView = 'schematic';
      _schematicOffset = Offset.zero;
      _schematicScale = 1.0;
    } catch (e) {
      _error = 'Error loading schematic: $e';
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Load a PCB file from raw content.
  Future<void> loadPCB(String content, {String fileName = ''}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _pcb = PCBParser.parse(content, fileName: fileName);
      _currentFileName = fileName;
      _currentView = 'pcb';
      _pcbOffset = Offset.zero;
      _pcbScale = 1.0;
    } catch (e) {
      _error = 'Error loading PCB: $e';
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Set the current view.
  void setView(String view) {
    _currentView = view;
    notifyListeners();
  }

  /// Select/deselect an element.
  void selectElement(String? id) {
    _selectedElementId = id;
    notifyListeners();
  }

  /// Toggle hierarchy panel.
  void toggleHierarchy() {
    _showHierarchy = !_showHierarchy;
    notifyListeners();
  }

  /// Toggle layers panel.
  void toggleLayers() {
    _showLayers = !_showLayers;
    notifyListeners();
  }

  /// Toggle a PCB layer visibility.
  void toggleLayer(int layerId) {
    if (_pcb == null) return;
    final layers = _pcb!.layers;
    for (final layer in layers) {
      if (layer.id == layerId) {
        layer.visible = !layer.visible;
        notifyListeners();
        return;
      }
    }
  }

  /// Update schematic view transform.
  void updateSchematicTransform(Offset offset, double scale) {
    _schematicOffset = offset;
    _schematicScale = scale;
    notifyListeners();
  }

  /// Update PCB view transform.
  void updatePCBTransform(Offset offset, double scale) {
    _pcbOffset = offset;
    _pcbScale = scale;
    notifyListeners();
  }

  /// Clear error.
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Get sheets for hierarchy tree.
  List<SchematicSheet> get sheets {
    if (_schematic == null) return [];
    return _schematic!.sheets;
  }

  /// Navigate to a sheet.
  Future<void> navigateToSheet(String fileName) async {
    // This would load the referenced sheet file
    _currentFileName = fileName;
    notifyListeners();
  }
}
