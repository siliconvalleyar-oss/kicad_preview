# KiCad Preview

A professional **Flutter** application for previewing KiCad schematic (`.kicad_sch`) and PCB (`.kicad_pcb`) files. Features a minimal, KiCad-inspired interface with layer visualization, hierarchical navigation, BOM extraction, and collaborative tools.

## Features

- **Schematic Viewer** — Render symbols, wires, labels, and hierarchical sheets with zoom/pan gestures
- **PCB Viewer** — Multi-layer PCB visualization with proper KiCad v7 layer colors, side toggle, and flip view
- **Layer Control** — Toggle individual layers or use quick presets (Basic, All, None)
- **Hierarchy Navigation** — Tree view of hierarchical sheet structure with sub-sheet loading
- **BOM Extraction** — Bill of Materials with CSV export
- **Notes / Chat Panel** — Add notes with auto-insert of component references in chat mode; export/share notes
- **Properties Panel** — Floating card showing basic properties of the selected component
- **Element Selection** — Click to highlight components and traces; non-selected elements dim
- **Responsive Toolbar** — Icons only in portrait, full labels in landscape
- **File Loading** — Open `.kicad_sch` and `.kicad_pcb` files from bundled assets or device storage

## Getting Started

### Prerequisites
- Flutter SDK 3.44.1+
- Dart SDK 3.12.1+

### Installation

```bash
git clone <repository-url>
cd kicad_preview
flutter pub get
flutter run
```

### Opening Files
- The demo project (`project_pi`) loads automatically on startup with both schematic and PCB
- Tap the folder icon to browse bundled projects or pick files from device storage
- Switch between Schematic, PCB, and BOM views using the toolbar

## Project Structure

```
lib/
├── main.dart                  # App entry point
├── controllers/
│   └── app_state.dart         # State management (ChangeNotifier)
├── models/
│   ├── schematic.dart         # Schematic data model
│   ├── schematic_element.dart  # Element, sheet, wire, junction types
│   ├── pcb.dart               # PCB data model
│   └── pcb_element.dart       # Layer, footprint, track, via types
├── parsers/
│   ├── sexpr_parser.dart      # S-expression parser (KiCad format)
│   ├── schematic_parser.dart  # .kicad_sch parser + BOM generation
│   └── pcb_parser.dart        # .kicad_pcb parser
├── views/
│   ├── splash_screen.dart     # Animated splash with logo
│   ├── main_view.dart         # Main layout with panels and canvas
│   ├── schematic_view.dart    # Schematic rendering (CustomPainter)
│   ├── pcb_view.dart          # PCB rendering with layer control
│   └── bom_view.dart          # Bill of Materials table view
└── widgets/
    ├── toolbar.dart           # Responsive toolbar
    ├── hierarchy_panel.dart   # Sheet navigation tree
    ├── layer_panel.dart       # Layer toggles with presets
    ├── notes_panel.dart       # Notes / Chat panel
    └── properties_panel.dart  # Selected element properties
```

## Version

Current version: **1.1.1** <!-- MUST match VERSION file -->

## License

This project is licensed under the MIT License.
