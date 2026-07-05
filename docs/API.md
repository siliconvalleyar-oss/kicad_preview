# API Documentation — KiCad Preview

## Core Models

### Schematic
Represents a parsed KiCad schematic file.

| Property    | Type                  | Description                    |
|-------------|-----------------------|--------------------------------|
| fileName    | String                | Source file name               |
| version     | String                | KiCad format version           |
| generator   | String                | Generating application         |
| paper       | String                | Page size (e.g., "A4")         |
| elements    | List\<SchematicElement\> | All schematic elements      |
| sheets      | List\<SchematicSheet\>   | Hierarchical sheets         |
| junctions   | List\<Junction\>         | Wire junctions              |
| wires       | List\<Wire\>            | Wire segments               |
| texts       | List\<SchematicText\>    | Text annotations            |

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

**Properties:** schematic, pcb, currentView, selectedElementId, showHierarchy, showLayers, schematicScale, pcbScale

**Methods:**
- `loadSchematic(content, {fileName})` — Load and parse a schematic
- `loadPCB(content, {fileName})` — Load and parse a PCB
- `setView(view)` — Switch between schematic/pcb/bom views
- `selectElement(id)` — Highlight an element
- `toggleLayer(layerId)` — Toggle PCB layer visibility
- `navigateToSheet(fileName)` — Navigate to a sub-sheet
