# KiCad Preview — Parser & Models Skill

## S-Expression Parser
El parser está en `lib/parsers/sexpr_parser.dart`. KiCad usa formato S-expression (Lisp-like):

```
(kicad_sch
  (version 20260306)
  (wire (pts (xy 1 2) (xy 3 4)) ...)
)
```

### Métodos útiles de SExprParser
- `parseString(content)` → `List<dynamic>` (árbol parseado)
- `findFirst(list, type)` → encuentra primer sublist con type
- `findAll(list, type)` → encuentra todos
- `getStringValue(list, key)` → valor string por key
- `getXY(list)` → `(double, double)?` de `(xy x y)` o `(at x y)`
- `parseAt(list)` → `(double, double, double)?` de `(at x y rot)`

## Modelos

### Schematic
- `Schematic` → fileName, version, generator, paper, elements, sheets, junctions, wires, texts
- `SchematicElement` → type (enum), uuid, points, strokeWidth, text, properties
- `BomItem` → reference, value, footprint, datasheet, qty

### PCB
- `PCB` → fileName, version, generator, thickness, layers, footprints, tracks, vias, graphicalLines
- `PCBLayer` → id, name, type, color, visible
- `PCBFootprint` → reference, value, layer, x, y, rotation, pads, lines, texts
- `PCBTrack` → x1, y1, x2, y2, width, layer, net
- `PCBVia` → x, y, diameter, drill, layers, net

### Colores de capas KiCad (PCBLayer.kicadLayerColors)
- 0: F.Cu → Red
- 2: B.Cu → Blue
- 5: F.SilkS → Yellow
- 7: B.SilkS → Cyan
- 25: Edge.Cuts → Orange

### Convención de escalado
- Schematic: coordenadas * 4 para píxeles
- PCB: coordenadas * 10 para píxeles
