# La Piramide

App móvil Flutter para el juego La Pirámide, preparada para Android e iOS en orientación horizontal.

## Modalidades de juego

- **Un móvil compartido:** el flujo original: los jugadores se pasan el teléfono.
- **Cada jugador con su móvil:** una persona crea una sala temporal y comparte el código de seis caracteres; los demás entran con ese código y la partida se sincroniza sin correo, contraseña ni cuenta.

Las salas solo guardan el apodo de juego y el estado temporal de la partida. Se eliminan automáticamente tras 24 horas.

## Estructura

- `lib/main.dart`: contenedor Flutter a pantalla completa con WebView local.
- `assets/web/index.html`: app del juego extraida del adjunto, sin la capa de emulador.
- `assets/web/support.js`: runtime local del HTML.
- `assets/web/vendor/`: React, ReactDOM, Babel y fuentes empaquetadas para funcionar sin conexion.
- `server/room-api.js`: servicio de salas temporales para la modalidad multijugador.
- `drizzle/0000_multiplayer_rooms.sql`: esquema de almacenamiento temporal de salas.
- `assets/icons/app_icon.png`: icono original adjunto.
- `assets/icons/app_icon_ios.png`: icono sin alfa para el catalogo iOS.

## Comandos utiles

```sh
flutter analyze
flutter test
flutter run
flutter build apk --debug
LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8 flutter build ios --simulator
```

Antes de publicar en Google Play hace falta configurar la firma release de Android. Antes de publicar en App Store hace falta configurar el bundle id/equipo de Apple definitivo.
