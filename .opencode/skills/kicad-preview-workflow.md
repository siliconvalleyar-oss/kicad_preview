# KiCad Preview — Workflow Skill

Este skill captura el flujo de trabajo para la app **KiCad Preview**, un visualizador de esquemáticos y PCB de KiCad en Flutter.

## Stack
- Flutter 3.44+ / Dart 3.12+
- Provider + ChangeNotifier (state management)
- CustomPaint + InteractiveViewer (renderizado)
- S-expression parser propio

## Estructura clave
```
lib/
├── main.dart
├── controllers/app_state.dart
├── models/           # schematic.dart, pcb.dart, *element.dart
├── parsers/          # sexpr_parser.dart, schematic_parser.dart, pcb_parser.dart
├── views/            # splash_screen, main_view, schematic_view, pcb_view, bom_view
└── widgets/          # toolbar, hierarchy_panel, layer_panel
```

## Al trabajar en este proyecto

### Issues comunes
- **`withOpacity()` deprecated**: Usar `color.withValues(alpha: x)` en lugar de `color.withOpacity(x)`
- **`dart:io` no disponible en web**: No usar `File` directamente, usar `file_picker` con `withData: true` y `utf8.decode(file.bytes!)`
- **S-expressions**: Los archivos KiCad usan formato Lisp-like. El parser está en `sexpr_parser.dart`
- **Verificar `mounted`**: Siempre verificar `mounted` antes de `setState` o ScaffoldMessenger en async
- **Liberar controllers**: Llamar `dispose()` en `AnimationController`, `TransformationController`, `StreamSubscription`

### Build & Run
```bash
flutter pub get
flutter run           # corre en dispositivo conectado
flutter build apk     # build APK release
```

### Testing
```bash
flutter test          # corre todos los tests
```

### Git
- Usar conventional commits: `feat:`, `fix:`, `docs:`, `chore:`, `refactor:`, `test:`
- Version en `VERSION` (sin 'v') y tag `v<version>`

### Reglas inmutables
- `docs/RULES.md` NO debe modificarse
- No eliminar tags publicados
- Actualizar `VERSION` antes de cada tag
