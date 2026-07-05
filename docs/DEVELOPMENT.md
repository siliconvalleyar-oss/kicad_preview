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

# Build for web
flutter build web

# Build for Android
flutter build apk
```

## Architecture

### State Management
The app uses `Provider` + `ChangeNotifier` for state management. The `AppState` class is a `ChangeNotifier` that holds all application state.

### Rendering Pipeline
1. **File Loading** — Assets or FilePicker loads raw file content
2. **Parsing** — SExprParser parses the S-expression structure
3. **Model Construction** — SchematicParser/PCBParser builds typed models
4. **Rendering** — CustomPaint paints the model to the canvas
5. **Interaction** — InteractiveViewer handles zoom/pan gestures

### KiCad File Format
KiCad uses **S-expressions** (Lisp-like syntax):
```
(kicad_sch
  (version 20260306)
  (wire (pts (xy 1 2) (xy 3 4)) ...)
  (junction (at 1 2) ...)
  (sheet (at 1 2) (size 3 4) ...)
)
```

The parser handles this format recursively, converting it to Dart lists and maps.

## Extending the App

### Adding a New Layer Type
1. Add the layer to `PCBLayer.kicadLayerColors`
2. Update `PCBPainter._getLayerColor()` if needed
3. Ensure the parser extracts the new layer from `.kicad_pcb` files

### Adding a New Schematic Element
1. Add the type to `SchematicElementType` enum
2. Create parsing logic in `SchematicParser`
3. Add rendering logic in `SchematicPainter`

## Performance Optimization
- `RepaintBoundary` wraps canvas painters
- `CustomPaint` for efficient canvas rendering
- Grid lines use minimal painting operations
- Use `const` constructors where possible
