---
name: kicad-preview
description: Guía completa del proyecto KiCad Preview (Flutter). Usar para tareas de desarrollo, parsing de KiCad (S-expressions), build/deploy Android, convenciones de código, versionado y git en esta app. Cargar cuando el usuario pida modificar, depurar, compilar o entender el visualizador de esquemáticos/PCB.
---

# KiCad Preview — Skill del Proyecto

Visualizador profesional de esquemáticos (`.kicad_sch`) y PCB (`.kicad_pcb`) de KiCad, escrito en Flutter. Interfaz minimalista estilo KiCad con capas, navegación jerárquica, BOM, notas/chat y selección de elementos.

## Stack

- Flutter 3.44+ / Dart 3.12+
- `provider` + `ChangeNotifier` para estado
- `CustomPaint` + `InteractiveViewer` para renderizado
- Parser propio de S-expressions (formato Lisp-like de KiCad v7+)
- Paquetes clave: `provider`, `file_picker`, `path_provider`, `share_plus`

## Estructura (mantener según RULES.md E.)

```
lib/
├── main.dart                  # Entry point
├── controllers/app_state.dart # AppState (ChangeNotifier)
├── models/                    # schematic.dart, pcb.dart, *element.dart
├── parsers/                   # sexpr_parser.dart, schematic_parser.dart, pcb_parser.dart
├── views/                     # splash_screen, main_view, schematic_view, pcb_view, bom_view
├── widgets/                   # toolbar, hierarchy_panel, layer_panel, notes_panel, properties_panel
└── utils/
```

Rama actual de trabajo: `learn-docs`.

## Parser de S-expressions (lib/parsers/sexpr_parser.dart)

KiCad usa formato `(type (key value) ...)`. Métodos útiles:

- `parseString(content)` → `List<dynamic>` (árbol)
- `parseAll()` / `parseFile(path)` → parseo completo
- `findFirst(list, type)` / `findAll(list, type)` → buscar sublists
- `getStringValue(list, key)` → valor string por key
- `getXY(list)` → `(double, double)?` de `(xy x y)` o `(at x y)`
- `parseAt(list)` → `(double, double, double)?` de `(at x y rot)`

Siempre envolver el parseo de archivos KiCad en try-catch robusto.

### Modelos

- `Schematic` → fileName, version, generator, paper, elements, sheets, junctions, wires, texts, symbolBodies (Map<String, List<RectDim>> desde lib_symbols)
- `SchematicElement` → type (enum), uuid, points, strokeWidth, text, properties
- `BomItem` → reference, value, footprint, datasheet, qty
- `PCB` → fileName, version, generator, thickness, layers, footprints, tracks, vias, graphicalLines, graphicalTexts
- `PCBLayer` → id, name, type, defaultColor/color, visible
- `PCBFootprint` → reference, value, layer, uuid, x, y, rotation, pads, lines, texts
- `PCBPad` → number, x, y, sizeX, sizeY, drill, type, shape, layers, net
- `PCBTrack` → x1, y1, x2, y2, width, layer, net, uuid
- `PCBVia` → x, y, diameter, drill, layers, net

### Colores de capas KiCad (PCBLayer.kicadLayerColors)

- 0: F.Cu → Red
- 2: B.Cu → Blue
- 5: F.SilkS → Yellow
- 7: B.SilkS → Cyan
- 25: Edge.Cuts → Orange

`PCBPainter._getLayerColor()` tiene un switch propio (v7+) consultado antes del fallback a `kicadLayerColors`.

### Escalado

- Schematic: coordenadas * 4 → píxeles
- PCB: coordenadas * 10 → píxeles

## State Management (AppState, ChangeNotifier)

Llamar `notifyListeners()` tras modificar estado. Para evitar rebuilds en pan/zoom se usan version counters con `context.select`:

| Counter | Se incrementa cuando | Usado por |
|---------|----------------------|-----------|
| `_notesVersion` | notas añadidas/limpiadas/cargadas, chat toggle, pending ref | NotesPanel |
| `_layersVersion` | capa toggle, preset, PCB cargada | LayerPanel |

Principales propiedades: `schematic`, `pcb`, `currentView` (schematic/pcb/bom), `selectedElementId`, `selectedElementProperties`, `showHierarchy/showLayers`, `showComponentNames/showComponentValues` (default false), `showPcbRefs`, `pcbSide` (top/bottom), `pcbFlipped`, `showNotes`, `chatMode`, `notes`, `pendingRef`, `notesVersion`, `layersVersion`.

Principales métodos: `loadSchematic`, `loadPCB`, `setView`, `selectElement` (auto-inserta ref en chat), `consumePendingRef`, `toggleHierarchy/Layers/ComponentNames/ComponentValues/PcbRefs/PcbSide/PcbFlipped`, `toggleLayer`, `showAllLayers/hideAllLayers/showBasicLayers`, `navigateToSheet/Root`, `toggleNotes`, `toggleChatMode`, `addNote/clearNotes/shareNotes`, `updateSchematicTransform/updatePCBTransform`.

## Gotchas frecuentes

- `withOpacity()` está deprecado → usar `color.withValues(alpha: x)`.
- `dart:io` NO disponible en web → no usar `File` directo; usar `file_picker` con `withData: true` y `utf8.decode(file.bytes!)`.
- Verificar `mounted` antes de `setState`/`ScaffoldMessenger` en async.
- Liberar controllers en `dispose()` (AnimationController, TransformationController, StreamSubscription).
- No usar `Container` con `color` y `decoration` simultáneamente.
- B.Cu tracks se renderizaban negros (invisibles) por mismatch de layer ID en v7 → usar colores ID-aware.
- Renderizado: `RepaintBoundary` + `CustomPaint`, `shouldRepaint` para saltar paints, `const` donde sea posible.

## Código (reglas obligatorias, RULES.md B.)

1. Acceso a archivos con try-catch + feedback (SnackBar/dialog).
2. Parseo S-expressions con try-catch robusto.
3. Verificar `mounted` antes de `setState` en async.
4. Liberar recursos en `dispose`.
5. `flush: true` en `writeAsString`.
6. Sin `Container` con `color` + `decoration`.
7. Verificar `exists()` antes de leer.
8. `notifyListeners()` tras cambiar estado.
9. `key` en cada item de `ListView.builder`.
10. `const` donde sea posible.

## Versionado (RULES.md A.)

- Formato `v1.X.Y`: X = minor (cada 10), Y = patch (0-9).
- `VERSION` (raíz) contiene solo número sin 'v' (ej: `1.1.0`).
- Tag debe coincidir con `VERSION`.
- `README.md` línea "Current version:" debe ser idéntica a `VERSION`.
- Versión actual: **1.1.0**.
- `docs/RULES.md` es INMUTABLE — no borrar/editar/renombrar.

## Build & Deploy

```bash
flutter pub get
flutter run              # reemplaza app instalada, conserva permisos
flutter build apk --release   # build/app/outputs/flutter-apk/app-release.apk
flutter run --release    # instalar en dispositivo
flutter analyze
flutter test
```

Si falla la instalación: reintentar hasta 5 veces con intervalos de 5 min. Verificar con `flutter devices` / `adb devices -l`.

## Git

- Conventional commits: `feat:`, `fix:`, `docs:`, `chore:`, `refactor:`, `test:`.
- Actualizar `VERSION` y commit antes de cada tag.
- No eliminar tags publicados; si hay error, crear nuevo tag.
