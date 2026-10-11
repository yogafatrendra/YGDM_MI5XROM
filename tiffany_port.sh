#!/bin/bash
# =========================================================
# Tiffany Universal & GSI ROM Port Tool
# Developed by: Yagadama
# Targeted Device: Xiaomi Mi 5X (tiffany)
# =========================================================

set -e

PORT_ZIP="$1"
BASE_ZIP="$2"
WORK_DIR="$(pwd)/workspace"
OUT_DIR="$(pwd)/out"

echo "================================================="
echo " Starting Tiffany GSI & ROM Porting Process...  "
echo " Developed by: Yagadama                         "
echo "================================================="

# 1. Bersihkan & Siapkan Folder Kerja
rm -rf "$WORK_DIR" "$OUT_DIR"
mkdir -p "$WORK_DIR/port" "$WORK_DIR/base" "$WORK_DIR/output/system" "$OUT_DIR"

# 2. Ambil Nama File Asli Port ROM / GSI (Tanpa Path & Tanpa Ekstensi)
RAW_NAME=$(basename "$PORT_ZIP")
# Menghapus ekstensi .zip, .img.xz, atau .img dari nama file
CLEAN_NAME=$(echo "$RAW_NAME" | sed -E 's/\.(zip|img\.xz|img|xz)$//g')

echo "--> Detected Port ROM Name: $CLEAN_NAME"

# 3. Ekstrak Base ROM (Mi 5X Treble)
echo "--> Membuka File Base ROM (Mi 5X)..."
unzip -q "$BASE_ZIP" -d "$WORK_DIR/base"

# 4. Penanganan File Port ROM / GSI
echo "--> Memproses Port ROM / GSI..."
if [[ "$PORT_ZIP" == *.xz ]]; then
    echo "--> Mendeteksi format terkompres .xz (GSI), mengekstrak..."
    unxz -c "$PORT_ZIP" > "$WORK_DIR/system.img"
elif [[ "$PORT_ZIP" == *.img ]]; then
    echo "--> Mendeteksi format raw .img (GSI)..."
    cp "$PORT_ZIP" "$WORK_DIR/system.img"
else
    echo "--> Membuka file Port ROM .zip biasa..."
    unzip -q "$PORT_ZIP" -d "$WORK_DIR/port"
fi

# 5. Penggabungan Struktur Sistem
if [ -f "$WORK_DIR/system.img" ]; then
    echo "--> Memasang (Mount) system.img GSI ke folder output..."
    mkdir -p "$WORK_DIR/mnt_system"
    7z x "$WORK_DIR/system.img" -o"$WORK_DIR/output/system" > /dev/null || true
else
    echo "--> Menggunakan struktur sistem dari Port ZIP biasa..."
    cp -r "$WORK_DIR/port/"* "$WORK_DIR/output/" 2>/dev/null || true
fi

# 6. Mengambil Kernel (boot.img) & Vendor Asli Mi 5X dari Base ROM
echo "--> Mengambil Kernel (boot.img) milik Mi 5X..."
cp "$WORK_DIR/base/boot.img" "$WORK_DIR/output/boot.img"

if [ -d "$WORK_DIR/base/vendor" ]; then
    echo "--> Mengambil Vendor Treble asli Mi 5X..."
    rm -rf "$WORK_DIR/output/vendor"
    cp -r "$WORK_DIR/base/vendor" "$WORK_DIR/output/vendor"
fi

# 7. Perbaikan Identitas build.prop
echo "--> Memperbaiki Identitas Perangkat ke tiffany (Mi 5X)..."
BUILD_PROP=$(find "$WORK_DIR/output" -name "build.prop" | head -n 1)

if [ -f "$BUILD_PROP" ]; then
    sed -i 's/ro.product.device=.*/ro.product.device=tiffany/g' "$BUILD_PROP"
    sed -i 's/ro.product.model=.*/ro.product.model=Mi 5X/g' "$BUILD_PROP"
    sed -i 's/ro.product.brand=.*/ro.product.brand=Xiaomi/g' "$BUILD_PROP"
    sed -i 's/ro.product.name=.*/ro.product.name=tiffany/g' "$BUILD_PROP"
    sed -i 's/ro.build.product=.*/ro.build.product=tiffany/g' "$BUILD_PROP"
fi

# 8. Penyesuaian Updater Script TWRP
UPDATER_SCRIPT="$WORK_DIR/output/META-INF/com/google/android/updater-script"
if [ ! -f "$UPDATER_SCRIPT" ] && [ -d "$WORK_DIR/base/META-INF" ]; then
    echo "--> Menggunakan template installer TWRP dari Base ROM..."
    cp -r "$WORK_DIR/base/META-INF" "$WORK_DIR/output/"
fi

if [ -f "$UPDATER_SCRIPT" ]; then
    echo "--> Menyesuaikan updater-script TWRP..."
    sed -i 's/assert(.*);//g' "$UPDATER_SCRIPT"
    
    echo 'ui_print("=========================================");' >> "$UPDATER_SCRIPT"
    echo 'ui_print(" Ported with Tiffany GSI Auto Tool       ");' >> "$UPDATER_SCRIPT"
    echo 'ui_print(" Developer: Yagadama                     ");' >> "$UPDATER_SCRIPT"
    echo 'ui_print(" Device: Xiaomi Mi 5X (tiffany)          ");' >> "$UPDATER_SCRIPT"
    echo 'ui_print("=========================================");' >> "$UPDATER_SCRIPT"
fi

# 9. Format Nama File Output Menjadi: [Nama_GSI]_tiffany_Yagadama.zip
OUTPUT_NAME="${CLEAN_NAME}_tiffany_Yagadama.zip"

echo "--> Membungkus Ulang ROM ke Format .zip: $OUTPUT_NAME..."
cd "$WORK_DIR/output"
zip -r9 "$OUT_DIR/$OUTPUT_NAME" ./* > /dev/null

echo "================================================="
echo " PORTING GSI SELESAI!                             "
echo " File Hasil: $OUTPUT_NAME                         "
echo "================================================="
