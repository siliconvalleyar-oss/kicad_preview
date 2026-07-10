# Changelog

## [1.1.2] - 2026-07-09
### Fixed
- Schematic symbol bodies now sized from real geometry: `SExprParser.findFirst`/`findAll` are NOT recursive, so collect rectangles/pins by walking nested alias symbols manually; body bbox uses pin bases (inner) so pins stick out
- Schematic pins now drawn; `no_connect` (connectivity) markers parsed and drawn as "X"
- PCB curved tracks `(arc ...)` parsed via quadratic Bezier (circumcenter was unstable for near-straight arcs -> invisible board); UV coords now bounded
- Through-hole pads: circular `(size d)` single-value parsed; circular pads drawn as real circles; thru-hole pads (`*.Cu`) rendered on both F.Cu and B.Cu like KiCad
- Added "Center PCB" button (centerView on visible layers only)

## [1.1.1] - 2026-07-09
### Fixed
- PCB tracks not rendered: parser only matched legacy `(track ...)`; now also parses KiCad v7+ `(segment ...)` and reads `tstamp` as UUID
- Internal copper layers (In1.Cu, In2.Cu) now use correct colors in `_getLayerColor`

## [1.1.0] - 2026-07-05
### Added
- Layer panel presets: Show Basic, All, None
- Notes / Chat panel with auto-insert of component references
- Properties panel for selected components
- Selection dimming: non-selected elements reduce to 20% opacity
- Chat mode auto-inserts ref on toggle when component is selected
- Clear notes button in chat panel
- Responsive toolbar: icons only in portrait, full labels in landscape
- PCB side toggle (Top/Bottom) with cross-fade layer opacity
- PCB flip board 180° rotation
- PCB reference text toggle (Refs button)
- `showPcbRefs`, `pcbSide`, `pcbFlipped` state management

### Fixed
- B.Cu tracks rendering as black (invisible) due to v7 layer ID mismatch
- Notes panel rebuilding on every pan/zoom (version counter optimization)
- Hierarchy panel rebuilding on every pan/zoom (context.select optimization)
- Chat button border color causing visual artifact (neutral purple instead of white)
- Demo project name corrected to `project_pi`

### Changed
- Default `showComponentNames` and `showComponentValues` to `false`
- PCB reference/footprint text opacity reduced to 40%
- Notes panel uses selective rebuild via `notesVersion` counter

## [1.0.0] - 2026-07-04
### Added
- Initial release of KiCad Preview
- Schematic viewer with wire, junction, sheet, label, and text rendering
- PCB viewer with multi-layer visualization
- Layer visibility control panel
- Hierarchical sheet navigation tree
- Bill of Materials extraction and CSV export
- Splash screen with animated logo
- File picker support for `.kicad_sch` and `.kicad_pcb` files
- Auto-loading of demo project (project_pi)
- Dark theme inspired by KiCad
- Zoom and pan gestures on canvas
- Element selection and highlighting
