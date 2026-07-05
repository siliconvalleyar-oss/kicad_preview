# KiCad Preview — Build & Deploy Skill

## Compilación y Despliegue (de RULES.md C.)

### Android
```bash
# Release APK
flutter build apk --release
# El APK estará en: build/app/outputs/flutter-apk/app-release.apk

# Instalar en dispositivo conectado (reemplaza app existente)
flutter run --release
```

### Si falla la instalación
Reintentar hasta 5 veces con intervalos de 5 minutos.

### Verificar conexión
```bash
flutter devices
```

### Check compilación sin errores
```bash
flutter analyze
flutter test
```
