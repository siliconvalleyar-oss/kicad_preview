# API Documentation — KiCad Preview

## Core Models

### Schematic
Represents a parsed KiCad schematic file.

| Property      | Type                    | Description                    |
|---------------|-------------------------|--------------------------------|
| fileName      | String                  | Source file name               |
| version       | String                  | KiCad format version           |
| generator     | String                  | Generating application         |
| paper         | String                  | Page size (e.g., "A4")         |
| elements      | List\<SchematicElement\> | All schematic elements      |
| sheets        | List\<SchematicSheet\>   | Hierarchical sheets         |
| junctions     | List\<Junction\>         | Wire junctions              |
| wires         | List\<Wire\>            | Wire segments               |
| texts         | List\<SchematicText\>    | Text annotations            |
| symbolBodies  | Map\<String, List\<RectDim\>\> | Parsed body rectangles from lib_symbols |

### PCB
Represents a parsed KiCad PCB file.

| Property       | Type                  | Description                    |
|----------------|-----------------------|--------------------------------|
| fileName       | String                | Source file name               |
| version        | String                | KiCad format version           |
| generator      | String                | Generating application         |
| thickness      | double                | Board thickness in mm          |
| paper          | String                | Page size                      |
| layers         | List\<PCBLayer\>        | PCB layer definitions       |
| footprints     | List\<PCBFootprint\>    | Component footprints        |
| tracks         | List\<PCBTrack\>        | Copper traces               |
| vias           | List\<PCBVia\>          | Vias (through-holes)        |
| graphicalLines | List\<PCBGraphicalLine\> | Graphical lines             |
| graphicalTexts | List\<PCBGraphicalText\>  | Graphical texts             |

### PCBElement Types

| Type          | Fields                                    | Description               |
|---------------|-------------------------------------------|---------------------------|
| PCBLayer      | id, name, type, defaultColor, visible     | Layer definition          |
| PCBFootprint  | reference, value, layer, uuid, x, y, rotation, pads, lines, texts | Component footprint |
| PCBPad        | number, x, y, sizeX, sizeY, drill, type, shape, layers, net | SMD/TH pad       |
| PCBTrack      | x1, y1, x2, y2, width, layer, net, uuid   | Copper trace             |
| PCBVia        | x, y, diameter, drill, layers, net        | Through-hole via         |
| PCBGraphicalLine | x1, y1, x2, y2, width, layer, uuid     | Graphical line           |
| PCBGraphicalText | text, x, y, size, rotation, layer, uuid | Graphical text           |

## Parsers

### SExprParser
Simple S-expression parser for KiCad's Lisp-like format.

- `parseAll()` — Parses entire content into nested lists
- `findFirst(list, type)` — Finds first sublist with given type
- `findAll(list, type)` — Finds all sublists with given type
- `getStringValue(list, key)` — Gets string value by key
- `parseFile(path)` — Static utility to parse a file

### SchematicParser
- `parse(content, {fileName})` — Parses .kicad_sch content into Schematic model
- `generateBom(schematic)` — Generates Bill of Materials from schematic

### PCBParser
- `parse(content, {fileName})` — Parses .kicad_pcb content into PCB model

## State Management

### AppState (ChangeNotifier)
Central state controller using the Provider pattern.

**Properties:**
- `schematic` — Current Schematic or null
- `pcb` — Current PCB or null
- `currentView` — 'schematic', 'pcb', or 'bom'
- `currentFileName` — Currently loaded file name
- `rootFileName` — Root schematic file name
- `selectedElementId` — UUID of selected element
- `selectedElementProperties` — Map of property name → value for selected element
- `showHierarchy` / `showLayers` — Panel visibility flags
- `showComponentNames` / `showComponentValues` — SCH text toggles (default false)
- `showPcbRefs` — PCB reference text toggle
- `pcbSide` — 'top' or 'bottom' layer view
- `pcbFlipped` — 180° board rotation flag
- `showNotes` / `chatMode` — Notes panel state
- `notes` — List of note strings
- `pendingRef` — Component reference pending auto-insert in chat mode
- `notesVersion` / `layersVersion` — Version counters for selective rebuilds

**Methods:**
- `loadSchematic(content, {fileName, isRoot})` — Load and parse a schematic
- `loadPCB(content, {fileName})` — Load and parse a PCB
- `setView(view)` — Switch between schematic/pcb/bom views
- `selectElement(id)` — Highlight an element (auto-inserts ref in chat mode)
- `consumePendingRef()` — Consume and clear pending reference
- `toggleHierarchy()` / `toggleLayers()` — Toggle side panels
- `toggleComponentNames()` / `toggleComponentValues()` — Toggle SCH text
- `togglePcbRefs()` — Toggle PCB reference visibility
- `togglePcbSide()` — Toggle between top/bottom view
- `togglePcbFlipped()` — Toggle 180° rotation
- `toggleLayer(layerId)` — Toggle PCB layer visibility
- `showAllLayers()` / `hideAllLayers()` / `showBasicLayers()` — Layer presets
- `navigateToSheet(fileName)` — Navigate to a sub-sheet
- `navigateToRoot()` — Return to root schematic
- `toggleNotes()` — Open/close notes panel
- `toggleChatMode()` — Toggle chat mode
- `addNote(text)` / `clearNotes()` — Manage notes
- `shareNotes()` — Export notes via share sheet
- `getSelectedElementRef()` — Get formatted reference string for selected element
- `updateSchematicTransform(offset, scale)` / `updatePCBTransform(offset, scale)` — View transforms

## Widgets

| Widget           | Description                                      |
|------------------|--------------------------------------------------|
| AppToolbar       | Responsive toolbar (icons portrait, labels landscape) with view/panel/PCB toggles |
| HierarchyPanel   | Tree view of hierarchical sheets, click to navigate |
| LayerPanel       | Layer list with visibility toggles and Basic/All/None presets |
| NotesPanel       | Notes/Chat panel with auto-ref insert, clear, and share |
| PropertiesPanel  | Floating card with selected component properties |
| SchematicView    | Interactive canvas with SchematicPainter (symbols, wires, sheets) |
| PCBView          | Interactive canvas with PCBPainter (tracks, pads, vias, side opacity) |

## Views

### SchematicView / SchematicPainter
- Renders wires, junctions, hierarchical sheets, labels, text, and component symbols
- Component bodies from actual `lib_symbols` rectangle dimensions
- Fallback shapes for resistors, capacitors, diodes, transistors, power symbols
- Selection highlighting with dimming of non-selected elements

### PCBView / PCBPainter
- Multi-layer rendering with per-layer color (v7 ID-aware)
- Side-based opacity: top layers 100% / bottom 40% (and vice versa)
- 180° flip via `RotatedBox`
- Toggleable component references
- Selection dimming
