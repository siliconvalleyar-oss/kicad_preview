import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/schematic.dart';
import '../models/pcb.dart';
import '../parsers/schematic_parser.dart';
import '../parsers/pcb_parser.dart';

/// Main application state using ChangeNotifier pattern.
class AppState extends ChangeNotifier {
  Schematic? _schematic;
  PCB? _pcb;
  bool _isLoading = false;
  String? _error;
  String _currentFileName = '';
  String _rootFileName = '';
  String _currentView = 'schematic'; // 'schematic', 'pcb', 'bom'
  String? _selectedElementId;
  bool _showHierarchy = true;
  bool _showLayers = true;
  bool _showComponentNames = true;
  bool _showComponentValues = true;

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
  String get rootFileName => _rootFileName;
  String get currentView => _currentView;
  String? get selectedElementId => _selectedElementId;
  bool get showHierarchy => _showHierarchy;
  bool get showLayers => _showLayers;
  bool get showComponentNames => _showComponentNames;
  bool get showComponentValues => _showComponentValues;
  Offset get schematicOffset => _schematicOffset;
  double get schematicScale => _schematicScale;
  Offset get pcbOffset => _pcbOffset;
  double get pcbScale => _pcbScale;

  List<BomItem> get bomItems {
    if (_schematic == null) return [];
    return SchematicParser.generateBom(_schematic!);
  }

  /// Load a schematic file from raw content.
  Future<void> loadSchematic(String content, {String fileName = '', bool isRoot = true}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _schematic = SchematicParser.parse(content, fileName: fileName);
      _currentFileName = fileName;
      if (isRoot) _rootFileName = fileName;
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

  /// Select/deselect an element. In chat mode, inserts a note with the element ref.
  void selectElement(String? id) {
    _selectedElementId = id;
    if (_chatMode && id != null) {
      final ref = getSelectedElementRef();
      if (ref != null) {
        // Auto-insert the reference; chat mode user then types their note after it
        _pendingRef = ref;
      }
    }
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

  void toggleComponentNames() {
    _showComponentNames = !_showComponentNames;
    notifyListeners();
  }

  void toggleComponentValues() {
    _showComponentValues = !_showComponentValues;
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

  /// Navigate to a sub-sheet by loading its file from assets.
  Future<void> navigateToSheet(String fileName) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final content = await rootBundle.loadString(
        'assets/files_kicad/$fileName',
      );
      _schematic = SchematicParser.parse(content, fileName: fileName);
      _currentFileName = fileName;
      _currentView = 'schematic';
      _schematicOffset = Offset.zero;
      _schematicScale = 1.0;
      _showHierarchy = true;
    } catch (e) {
      _error = 'Error loading sheet: $e';
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Navigate back to the root schematic.
  Future<void> navigateToRoot() async {
    if (_rootFileName.isEmpty) return;
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final content = await rootBundle.loadString(
        'assets/files_kicad/$_rootFileName',
      );
      _schematic = SchematicParser.parse(content, fileName: _rootFileName);
      _currentFileName = _rootFileName;
      _currentView = 'schematic';
      _schematicOffset = Offset.zero;
      _schematicScale = 1.0;
      _showHierarchy = true;
    } catch (e) {
      _error = 'Error loading root sheet: $e';
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Show the hierarchy panel (called from toolbar).
  void showPanel() {
    if (_currentView == 'schematic' && !_showHierarchy) {
      _showHierarchy = true;
      notifyListeners();
    } else if (_currentView == 'pcb' && !_showLayers) {
      _showLayers = true;
      notifyListeners();
    }
  }

  // ── Notes / Chat ──────────────────────────────────────

  bool _showNotes = false;
  bool _chatMode = false;
  List<String> _notes = [];
  String _projectNotesDir = '';
  String? _pendingRef;

  bool get showNotes => _showNotes;
  bool get chatMode => _chatMode;
  List<String> get notes => List.unmodifiable(_notes);
  String? get pendingRef => _pendingRef;

  void toggleNotes() {
    _showNotes = !_showNotes;
    if (_showNotes) _loadNotes();
    notifyListeners();
  }

  void toggleChatMode() {
    _chatMode = !_chatMode;
    notifyListeners();
  }

  String _notesFileName() {
    final base = _rootFileName.replaceAll('.kicad_sch', '').replaceAll('.kicad_pcb', '');
    return '${base}_notes.md';
  }

  Future<String> _notesFilePath() async {
    if (_projectNotesDir.isEmpty) {
      final dir = await getApplicationDocumentsDirectory();
      _projectNotesDir = dir.path;
    }
    return '$_projectNotesDir/${_notesFileName()}';
  }

  Future<void> _loadNotes() async {
    try {
      final path = await _notesFilePath();
      final file = File(path);
      if (await file.exists()) {
        final content = await file.readAsString();
        _notes = content.split('\n').where((l) => l.trim().isNotEmpty).toList();
      } else {
        _notes = [];
      }
    } catch (_) {
      _notes = [];
    }
    notifyListeners();
  }

  Future<void> addNote(String text) async {
    if (text.trim().isEmpty) return;
    _notes.add(text.trim());
    _pendingRef = null;
    notifyListeners();
    _saveNotes();
  }

  Future<void> insertNoteWithRef(String ref, String text) async {
    final line = '$ref $text';
    await addNote(line);
  }

  Future<void> _saveNotes() async {
    try {
      final path = await _notesFilePath();
      final file = File(path);
      final content = StringBuffer();
      content.writeln('# Notes - $_rootFileName');
      content.writeln();
      for (final note in _notes) {
        final line = note.startsWith('[') ? '- $note' : '- $note';
        content.writeln(line);
      }
      await file.writeAsString(content.toString());
    } catch (_) {}
  }

  Future<void> shareNotes() async {
    final path = await _notesFilePath();
    final file = File(path);
    if (!await file.exists()) {
      await file.writeAsString('');
    }
    final content = await file.readAsString();
    await SharePlus.instance.share(
      ShareParams(text: content.isNotEmpty ? content : '(empty notes)'),
    );
  }

  String? getSelectedElementRef() {
    if (_selectedElementId == null) return null;
    final id = _selectedElementId!;

    // Check schematic elements
    if (_schematic != null) {
      for (final el in _schematic!.elements) {
        if (el.uuid == id) {
          final name = el.text ?? 'unknown';
          final value = el.properties['Value'] ?? '';
          return '[${_currentFileName.replaceAll('.kicad_sch', '')}:$name${value.isNotEmpty ? ' ($value)' : ''}]';
        }
      }
    }

    // Check PCB footprints
    if (_pcb != null) {
      for (final fp in _pcb!.footprints) {
        if (fp.uuid == id) {
          return '[${_currentFileName.replaceAll('.kicad_pcb', '')}:${fp.reference}]';
        }
      }
    }

    return null;
  }
}
