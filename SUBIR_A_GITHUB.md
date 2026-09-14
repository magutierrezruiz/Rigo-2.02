# Subir a GitHub

En la raíz del repositorio deben verse directamente, entre otros:

- `codemagic.yaml`
- `build-apk.sh`
- `app/`
- `README.md`

No subas una carpeta contenedora adicional.

En Codemagic el workflow correcto es:

**AlgebrAventura 2.0 FIX5 - sin Gradle**

Si aparece cualquier workflow que diga FIX4 o que tenga un paso llamado "Instalar Gradle", el repositorio no está usando esta versión.
