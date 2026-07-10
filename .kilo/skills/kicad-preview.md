---
name: kicad-preview
description: Guía completa del proyecto KiCad Preview (Flutter). Usar para tareas de desarrollo, parsing de KiCad (S-expressions), build/deploy Android, convenciones de código, versionado y git en esta app. Cargar cuando el usuario pida modificar, depurar, compilar o entender el visualizador de esquemáticos/PCB.
---

# KiCad Preview — Skill del Proyecto

Visualizador profesional de esquemáticos (`.kicad_sch`) y PCB (`.kicad_pcb`) de KiCad, escrito en Flutter. Interfaz minimalista estilo KiCad con capas, navegación jerárquica, BOM, notas/chat y selección de elementos.

## ⚠️ Gotchas de parsing (CRÍTICOS, ya causaron bugs)

1. **`SExprParser.findFirst` / `findAll` NO SON RECURSIVOS** — solo inspeccionan los hijos DIRECTOS de la lista que les pasás. Por eso:
   - En `lib_symbols` de KiCad v7, el `rectangle` y el `pin` de un símbolo están ANIDADOS dentro del símbolo hijo alias (p.ej. `Conn_01x01_Pin_1_1` dentro de `Connector:Conn_01x01_Pin`). Hay que recorrer el árbol manualmente (función `_collectSymGeometry` que se llama a sí misma para cada sublista).
   - Lo mismo aplica para `pad`, `footprint`, etc. si estuvieran anidados.
2. **Precendencia de `??`**: `double.tryParse(x) ?? 0` infiere `double`, pero en un ternario `cond ? double.tryParse(x) ?? 0 : 0` el `0` es `int` → el resultado es `num` y da error al asignar a `double`. Usar `0.0`.
3. **Capas de KiCad v7 usan IDs NUEVOS** (`F.Cu=0, B.Cu=31, In1.Cu=1, In2.Cu=2, F.SilkS=37, Edge.Cuts=44`...). El mapa legacy `kicadLayerColors` usa IDs viejos → no coincide. `PCBPainter._getLayerColor()` tiene un `switch` por NOMBRE (F.Cu, B.Cu, F/B.SilkS, F/B.Mask, Edge.Cuts, F/B.Fab, F/B.CrtYd, In1.Cu, In2.Cu) que tiene prioridad sobre el fallback.
4. **`withOpacity()` está deprecado** → usar `color.withValues(alpha: x)`.
5. **`dart:io` NO disponible en web** → no usar `File` directo; usar `file_picker` con `withData: true` y `utf8.decode(file.bytes!)`.
6. Verificar `mounted` antes de `setState`/`ScaffoldMessenger` en async.
7. Liberar controllers en `dispose()` (AnimationController, TransformationController, StreamSubscription).

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

KiCad usa formto `(type (key value) ...)`. Métodos útiles:

- `parseString(content)` → `List<dynamic>` (árbol)
- `parseAll()` / `parseFile(path)` → parseo completo
- `findFirst(list, type)` / `findAll(list, type)` → buscar sublists (⚠️ **NO recursivos**, solo hijos directos)
- `getStringValue(list, key)` → valor string por key
- `getXY(list)` → `(double, double)?` de `(xy x y)` o `(at x y)`
- `parseAt(list)` → `(double, double, double)?` de `(at x y rot)`

⚠️ Siempre envolver el parseo de archivos KiCad en try-catch robusto.

### Modelos

- `Schematic` → fileName, version, generator, paper, elements, sheets, junctions, wires, texts, **symbolBodies** (`Map<String, List<RectDim>>` desde lib_symbols, clave = nombre completo con prefijo p.ej. `Connector:Conn_01x01_Pin`), **symbolPins** (`Map<String, List<SchematicPin>>`)
- `SchematicElement` → type (enum), uuid, points, strokeWidth, text, properties, **symbolPins** (pines del símbolo instancia)
- `SchematicPin` → x, y, angle, length, number, name (coordenadas en marco local del símbolo; `at` = punta EXTERIOR donde conecta el cable, el pin se extiende `length` hacia adentro en dirección `angle`: 0=derecha, 90=arriba, 180=izquierda, 270=abajo)
- `BomItem` → reference, value, footprint, datasheet, quantity
- `PCB` → fileName, version, generator, thickness, layers, footprints, tracks, vias, graphicalLines, graphicalTexts
- `PCBLayer` → id, name, type, defaultColor/color, visible
- `PCBFootprint` → reference, value, layer, uuid, x, y, rotation, pads, lines, texts
- `PCBPad` → number, x, y, sizeX, sizeY, **drill**, type (`smd`/`thru_hole`), shape (`rect`/`circle`/`roundrect`), layers (**puede usar comodín `"*.Cu"` = todas las capas cobre**), net
- `PCBTrack` → x1, y1, x2, y2, width, layer, net, uuid
- `PCBVia` → x, y, diameter, drill, layers, net

### Pistas del PCB (lib/parsers/pcb_parser.dart)

KiCad v7+ guarda las pistas de cobre como:
- `(segment (start x y) (end x y) (width w) (layer "F.Cu") (net 1))` → rectas (LEGACY: `(track ...)`)
- `(arc (start x y) (mid x y) (end x y) (width w) (layer "F.Cu") (net 1) (tstamp uuid))` → **curvas**

⚠️ **NUNCA usar circunferencia (circumcenter) para los `arc`**: para arcos casi rectos el radio se hace enorme → coordenadas monstruosas → `scale` infinitesimal → PCB invisible. Aproximar con **Bézier cuadrática** a través de start/mid/end (punto de control `B = 2*M - (S+E)/2`). Siempre acotado al convex hull → sin NaN/Inf, sin coordenadas enormes. El uuid de `arc` viene en `(tstamp ...)`, no `(uuid ...)`.

### Cuerpos de símbolo (esquemático)

- La instancia usa `lib_id` **CON prefijo** (`Connector:Conn_01x01_Pin`) → coincide con el nombre del símbolo en `lib_symbols`.
- El `rectangle` y el `pin` están **anidados** en el símbolo hijo alias → hay que recorrer recursivamente (ver gotcha #1).
- El **bbox del cuerpo** se calcula desde las **bases de los pines** (extremo interior = `at + length*dir(angle)`), NUNCA desde la punta `at` (extremo exterior donde conecta el cable). Así los pines sobresalen del cuerpo como en el diseño.
- **Excluir `power:`** de `symbolBodies` para conservar su render dedicado (GND/flecha).
- En el pintor: pin dibujado desde la base hasta la punta `at`; marcador de conexión (círculo) en `at`.

### Pads through-hole (PCB)

- KiCad usa `(size 1.5)` de **valor único** para pads circulares (no `(size 1.5 0.8)`). El parser debe aceptar `length >= 2`, no `>= 3`.
- Pads circulares (`shape 'circle'`) → dibujar como **círculo real** (`drawCircle`), no `roundRect`.
- Pads through-hole (`type 'thru_hole'` o capas con comodín `"*.Cu"`) existen en TODAS las capas cobre → dibujar en **ambas** F.Cu y B.Cu (como en KiCad) para que conecten pistas de ambos lados.

### Símbolos de conectividad

- **GND / power:** `lib_id` empieza con `power:` → `_drawPowerSymbol` (flecha GND o círculo).
- **`no_connect`:** parserlo como `SchematicElementType.noConnect` y dibujarlo como marca **"X"** (dos líneas cruzadas).

### Colores de capas KiCad

`PCBPainter._getLayerColor()` (switch por nombre, v7+): F.Cu=Rojo, B.Cu=Azul, In1.Cu=Verde, In2.Cu=Morado, F/B.SilkS, F/B.Mask, Edge.Cuts=Naranja, F/B.Fab, F/B.CrtYd. Fallback: `kicadLayerColors[id]` (legacy) → si es negro, gris `0xFF555555`.

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

Principales métodos: `loadSchematic`, `loadPCB`, `setView`, `selectElement` (auto-inserta ref en chat), `consumePendingRef`, `toggleHierarchy/Layers/ComponentNames/ComponentValues/PcbRefs/PcbSide/PcbFlipped`, `toggleLayer`, `showAllLayers/hideAllLayers/showBasicLayers`, `navigateToSheet/Root`, `toggleNotes`, `toggleChatMode`, `addNote/clearNotes/shareNotes`, `updateSchematicTransform/updatePCBTransform`, **`centerView` (PCBViewState, público)** → recentra en capas visibles.

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
- `VERSION` (raíz) contiene solo número sin 'v' (ej: `1.1.2`).
- Tag debe coincidir con `VERSION`.
- `README.md` línea "Current version:" debe ser idéntica a `VERSION`.
- Versión actual: **1.1.2**.
- `docs/RULES.md` es INMUTABLE — no borrar/editar/renombrar.

## Build & Deploy

```bash
flutter pub get
flutter run              # reemplaza app instalada y conserva permisos
flutter build apk --release   # build/app/outputs/flutter-apk/app-release.apk
flutter run --release    # instalar en dispositivo
flutter analyze
flutter test
```

Si falla la instalación: reintentar hasta 5 veces con intervalos de 5 min. Verificar con `flutter devices` / `adb devices -l`.
Instalar en móvil por red: `adb -s <ip>:<port> install -r build/app/outputs/flutter-apk/app-release.apk`.

## Git

- Conventional commits: `feat:`, `fix:`, `docs:`, `chore:`, `refactor:`, `test:`.
- Actualizar `VERSION` y hacer commit antes de cada tag.
- No eliminar tags publicados; si hay error, crear nuevo tag.
