# AlgebrAventura 2.0 — FIX5

Esta versión compila el APK directamente con las herramientas oficiales del Android SDK (`aapt2`, `javac`, `d8`, `zipalign` y `apksigner`).

**No usa Gradle ni Android Gradle Plugin durante la compilación en Codemagic.**

## Contenido del juego

- 13 retos.
- 20 ejercicios por reto.
- 260 ejercicios en total.
- Selección aleatoria de un ejercicio por reto en cada partida.
- Opciones A/B/C/D mezcladas aleatoriamente.
- 3 vidas.
- 100 puntos por respuesta correcta.
- Reto 13: cubo de un binomio `(a ± b)^3`.

## Compilar en Codemagic

1. Crea un repositorio nuevo en GitHub.
2. Sube **el contenido de esta carpeta a la raíz** del repositorio.
3. Conecta el repositorio en Codemagic.
4. Selecciona el workflow **AlgebrAventura 2.0 FIX5 - sin Gradle**.
5. Ejecuta el build.
6. Descarga `app-debug.apk` desde Artifacts.

El APK se genera en:

`app/build/outputs/apk/debug/app-debug.apk`
