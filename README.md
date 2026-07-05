# KiCad Preview

A professional **Flutter** application for previewing KiCad schematic (`.kicad_sch`) and PCB (`.kicad_pcb`) files. Features a minimal, KiCad-inspired interface with layer visualization, hierarchical navigation, and BOM extraction.

## Features

- **Schematic Viewer** — Render symbols, wires, labels, and hierarchical sheets with zoom/pan gestures
- **PCB Viewer** — Multi-layer PCB visualization with standard KiCad layer colors
- **Layer Control** — Toggle individual layers on/off from the side panel
- **Hierarchy Navigation** — Tree view of hierarchical sheet structure
- **BOM Extraction** — Bill of Materials with CSV export
- **Element Selection** — Click to highlight components and traces
- **File Loading** — Open `.kicad_sch` and `.kicad_pcb` files from the device

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
- The demo project (`cnc_pic32`) loads automatically on startup
- Use the "Open" button to load other `.kicad_sch` or `.kicad_pcb` files
- Switch between Schematic, PCB, and BOM views using the toolbar

## Project Structure

```
lib/
├── main.dart              # App entry point
├── controllers/
│   └── app_state.dart     # State management
├── models/
│   ├── schematic.dart     # Schematic data model
│   ├── schematic_element.dart
│   ├── pcb.dart           # PCB data model
│   └── pcb_element.dart
├── parsers/
│   ├── sexpr_parser.dart  # S-expression parser
│   ├── schematic_parser.dart
│   └── pcb_parser.dart
├── views/
│   ├── splash_screen.dart # Splash with animation
│   ├── main_view.dart     # Main application layout
│   ├── schematic_view.dart
│   ├── pcb_view.dart
│   └── bom_view.dart
└── widgets/
    ├── toolbar.dart
    ├── hierarchy_panel.dart
    └── layer_panel.dart
```

## Version

Current version: **1.0.2** <!-- MUST match VERSION file -->

## License

This project is licensed under the MIT License.
