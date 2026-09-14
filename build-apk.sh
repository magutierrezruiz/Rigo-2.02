#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
cd "$ROOT"

SDK_ROOT="${ANDROID_SDK_ROOT:-/usr/local/share/android-sdk}"
API="${ANDROID_API:-35}"
BUILD_TOOLS_VERSION="${ANDROID_BUILD_TOOLS:-35.0.0}"
BT="$SDK_ROOT/build-tools/$BUILD_TOOLS_VERSION"
ANDROID_JAR="$SDK_ROOT/platforms/android-$API/android.jar"

AAPT2="$BT/aapt2"
D8="$BT/d8"
ZIPALIGN="$BT/zipalign"
APKSIGNER="$BT/apksigner"

for f in "$AAPT2" "$D8" "$ZIPALIGN" "$APKSIGNER" "$ANDROID_JAR"; do
  if [ ! -e "$f" ]; then
    echo "ERROR: No se encontró $f"
    exit 2
  fi
done

WORK="$ROOT/.manual-build"
OUT="$ROOT/app/build/outputs/apk/debug"
rm -rf "$WORK"
mkdir -p "$WORK/compiled-res" "$WORK/classes" "$WORK/dex" "$WORK/generated" "$OUT"

echo "== 1/6 Compilar recursos con aapt2 =="
"$AAPT2" compile --dir "$ROOT/app/src/main/res" -o "$WORK/compiled-res"

mapfile -t FLATS < <(find "$WORK/compiled-res" -type f -name '*.flat' | sort)
if [ "${#FLATS[@]}" -eq 0 ]; then
  echo "ERROR: aapt2 no generó recursos .flat"
  exit 3
fi

echo "== 2/6 Enlazar recursos y AndroidManifest =="
"$AAPT2" link \
  -o "$WORK/app-resources.apk" \
  -I "$ANDROID_JAR" \
  --manifest "$ROOT/app/src/main/AndroidManifest.xml" \
  --java "$WORK/generated" \
  --min-sdk-version 21 \
  --target-sdk-version "$API" \
  --version-code 2 \
  --version-name 2.0 \
  "${FLATS[@]}"

echo "== 3/6 Compilar Java =="
mapfile -t JAVA_FILES < <(find "$ROOT/app/src/main/java" "$WORK/generated" -type f -name '*.java' | sort)
if [ "${#JAVA_FILES[@]}" -eq 0 ]; then
  echo "ERROR: no se encontraron fuentes Java"
  exit 4
fi
javac \
  -encoding UTF-8 \
  -source 8 \
  -target 8 \
  -classpath "$ANDROID_JAR" \
  -d "$WORK/classes" \
  "${JAVA_FILES[@]}"

echo "== 4/6 Convertir bytecode a DEX =="
mapfile -t CLASS_FILES < <(find "$WORK/classes" -type f -name '*.class' | sort)
"$D8" \
  --lib "$ANDROID_JAR" \
  --min-api 21 \
  --output "$WORK/dex" \
  "${CLASS_FILES[@]}"

if [ ! -f "$WORK/dex/classes.dex" ]; then
  echo "ERROR: d8 no generó classes.dex"
  exit 5
fi

echo "== 5/6 Insertar DEX y alinear APK =="
cp "$WORK/app-resources.apk" "$WORK/app-with-dex.apk"
(
  cd "$WORK/dex"
  zip -q -u "$WORK/app-with-dex.apk" classes.dex
)
"$ZIPALIGN" -f 4 "$WORK/app-with-dex.apk" "$WORK/app-aligned.apk"

echo "== 6/6 Firmar APK de depuración =="
KEYSTORE="$WORK/debug.keystore"
keytool -genkeypair \
  -keystore "$KEYSTORE" \
  -storepass android \
  -alias androiddebugkey \
  -keypass android \
  -dname "CN=Android Debug,O=Android,C=US" \
  -keyalg RSA \
  -keysize 2048 \
  -validity 10000 \
  -noprompt >/dev/null 2>&1

FINAL_APK="$OUT/app-debug.apk"
"$APKSIGNER" sign \
  --ks "$KEYSTORE" \
  --ks-pass pass:android \
  --key-pass pass:android \
  --out "$FINAL_APK" \
  "$WORK/app-aligned.apk"

"$APKSIGNER" verify --verbose "$FINAL_APK"

echo ""
echo "APK CREADO CORRECTAMENTE:"
echo "$FINAL_APK"
ls -lh "$FINAL_APK"
