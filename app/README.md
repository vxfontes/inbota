# Inbota App (Flutter)

App Flutter do Inbota. Esta pasta contem apenas o app (o backend fica em `../backend`).

## Requisitos
- Flutter 3.35.x
- Dart (via Flutter)

## Rodar local
```bash
cd app
flutter pub get
flutter run
```

## Configuracao
- A base URL da API fica em `lib/shared/config` (ajuste para `http://localhost:8080` ou IP local).
- Todas as rotas protegidas usam `Authorization: Bearer <token>`.

## Qualidade
```bash
cd app
dart format .
dart analyze
```

## Gerar imagens

1. Abra o SVG no Preview.
2. File > Export... e salve como PNG 1024x1024 em `app/assets/app_icon.png`.

Depois rode:

```bash
flutter pub run flutter_launcher_icons:main -f flutter_launcher_icons.yaml
flutter pub run flutter_native_splash:create
```
