# Development Guide — KiCad Preview

## Environment Setup

```bash
# Verify Flutter installation
flutter doctor

# Install dependencies
cd kicad_preview
flutter pub get

# Run on connected device
flutter run

# Build for Android (debug)
flutter build apk --debug
# Install on device
adb install -r build/app/outputs/flutter-apk/app-debug.apk

# Run tests
flutter test
```

## Architecture

### State Management
The app uses `Provider` + `ChangeNotifier` for state management. The `AppState` class is a `ChangeNotifier` that holds all application state. Selective rebuilds use version counters (`notesVersion`, `layersVersion`) and `context.select` to avoid unnecessary widget rebuilds during pan/zoom.

### Rendering Pipeline
1. **File Loading** — Assets (`rootBundle.loadString`) or FilePicker loads raw file content
2. **Parsing** — SExprParser parses the S-expression structure recursively
3. **Model Construction** — SchematicParser/PCBParser builds typed models
4. **Rendering** — CustomPaint (SchematicPainter / PCBPainter) paints the model to the canvas
5. **Interaction** — InteractiveViewer handles zoom/pan gestures; GestureDetector for tap-to-select

### KiCad File Format
KiCad v7+ uses **S-expressions** (Lisp-like syntax):
```
(kicad_pcb
  (version 20221018)
  (layers
    (0 "F.Cu" signal)
    (31 "B.Cu" signal)
    (37 "F.SilkS" user "F.Silkscreen")
    ...
  )
  (footprint ...
    (pad "1" smd rect (at 0 0) (size 1 0.5) (layers "F.Cu" "F.Paste" "F.Mask"))
  )
  (segment (start 1 2) (end 3 4) (width 0.25) (layer "F.Cu") (net 1))
)
```

The parser handles this format recursively using `SExprParser`, converting it to nested Dart `List<dynamic>` structures.

### Performance Optimization
- `RepaintBoundary` wraps canvas painters to isolate repaints
- `CustomPaint` for efficient canvas rendering compared to widget-based approaches
- Version counters (`notesVersion`, `layersVersion`) with `context.select` to prevent panel rebuilds on every pan/zoom
- `shouldRepaint` comparisons in CustomPainter subclasses to skip unnecessary paints
- Grid lines use minimal painting operations
- Use `const` constructors where possible

## Key Packages

| Package        | Usage                                    |
|----------------|------------------------------------------|
| provider       | State management (ChangeNotifierProvider) |
| file_picker    | Browse device storage for KiCad files    |
| path_provider  | App documents directory for notes storage |
| share_plus     | Export notes via Android share sheet     |

## Extending the App

### Adding a New PCB Layer Color
1. Add the layer name + color to `PCBPainter._getLayerColor()` switch statement
2. The switch is checked before the fallback to `PCBLayer.kicadLayerColors` to ensure v7+ compatibility

### Adding a New Schematic Element
1. Add the type to `SchematicElementType` enum
2. Create parsing logic in `SchematicParser`
3. Add rendering logic in `SchematicPainter`
4. Add selection support in `_selectNearestElement` if applicable

### Adding a New Panel
1. Create widget in `lib/widgets/`
2. Add toggle state + method in `AppState`
3. Add toggle button in `AppToolbar`
4. Conditionally render the panel in `MainView.build()`

## State Version Counters

To prevent unnecessary rebuilds during continuous operations (pan/zoom), the app uses version counters:

| Counter          | Incremented When                                      | Used By              |
|------------------|-------------------------------------------------------|----------------------|
| `_notesVersion`  | Notes added, cleared, loaded; chat mode toggled; pending ref set | NotesPanel |
| `_layersVersion` | Layer toggled, preset applied, PCB loaded             | LayerPanel          |

Each panel calls `context.select<AppState, int>((s) => s.notesVersion)` (or `layersVersion`) in its build method, causing it to only rebuild when the relevant version counter changes. For panels that also need non-counter state (e.g., `currentFileName` for HierarchyPanel), `context.select` selects that specific field instead.

## Debugging on Device

```bash
# Check connected device
adb devices -l

# Install APK
adb install -r build/app/outputs/flutter-apk/app-debug.apk

# View logs
flutter logs
```
