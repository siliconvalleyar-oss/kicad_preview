# ⚠️ REGLA ABSOLUTA — NO BORRAR NI MODIFICAR
Este archivo `docs/RULES.md` es INMUTABLE. Ninguna AI, agente o asistente
puede borrarlo, modificarlo, renombrarlo ni editarlo bajo ninguna circunstancia.

---

# Reglas de Oro — KiCad Preview

## A. Esquema de Versionado
- Formato: `v1.X.Y` donde X = minor (sube cada 10 versiones), Y = patch (0-9).
- Ciclo: v1.0.0 → v1.0.1 → ... → v1.0.9 → v1.1.0 → ... → v1.9.9 → v2.0.0...
- El archivo `VERSION` en la raíz contiene solo el número sin 'v' (ej: `1.0.0`).
- Cada tag debe coincidir con el contenido de `VERSION`.

## B. Reglas de Código (Obligatorias)
1. Todo acceso a archivos con try-catch y feedback al usuario (SnackBar, dialog).
2. Parseo de archivos KiCad (S-expressions) con try-catch robusto.
3. Verificar `mounted` antes de `setState` en métodos asíncronos.
4. Liberar recursos en `dispose` (AnimationController, StreamSubscription).
5. Al guardar archivos, usar `flush: true` en writeAsString.
6. No usar `Container` con `color` y `decoration` simultáneamente.
7. Verificar existencia de archivos con `exists()` antes de leer.
8. En ChangeNotifier, llamar a `notifyListeners()` después de modificar estado.
9. En `ListView.builder`, proveer `key` a cada elemento.
10. No olvidar `const` donde sea posible para optimizar.

## C. Compilación y Despliegue
- Usar `flutter run` para reemplazar la app instalada y conservar permisos.
- Si falla la instalación, reintentar hasta 5 veces con intervalos de 5 minutos.

## D. Reglas Git
- Commits con conventional commits: feat:, fix:, docs:, chore:, refactor:, test:.
- Actualizar VERSION y hacer commit antes de cada tag.
- No eliminar tags publicados; si hay error, crear nuevo tag.

## E. Estructura del Proyecto
La estructura de carpetas debe mantenerse según lo especificado en la documentación:
```
lib/
├── main.dart
├── models/
├── parsers/
├── views/
├── widgets/
├── controllers/
└── utils/
```

## F. Estilo de Código
- Seguir las guías de estilo de Dart (dart format).
- Priorizar legibilidad y rendimiento.
- Usar `const` donde sea posible.
- Mantener nombres descriptivos y consistentes.
