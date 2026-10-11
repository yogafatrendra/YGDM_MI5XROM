#!/bin/bash
# =========================================================
# Tiffany Universal ROM Port Tool
# Developed by: Yagadama
# Targeted Device: Xiaomi Mi 5X (tiffany)
# =========================================================

set -e

PORT_ZIP="$1"
BASE_ZIP="$2"
WORK_DIR="$(pwd)/workspace"
OUT_DIR="$(pwd)/out"

echo "================================================="
echo " Starting Tiffany Porting Process...            "
echo " Developed by: Yagadama                         "
echo "================================================="

# 1. Bersihkan & Siapkan Folder Kerja
rm -rf "$WORK_DIR" "$OUT_DIR"
mkdir -p "$WORK_DIR/port" "$WORK_DIR/base" "$WORK_DIR/output" "$OUT_DIR"

# 2. Ekstrak ROM
echo "--> Membuka File Port ROM..."
unzip -q "$PORT_ZIP" -d "$WORK_DIR/port"

echo "--> Membuka File Base ROM (Mi 5X)..."
unzip -q "$BASE_ZIP" -d "$WORK_DIR/base"

# 3. Pindahkan Struktur Utama Port ROM ke Output
cp -r "$WORK_DIR/port/"* "$WORK_DIR/output/" 2>/dev/null || true

# 4. Ganti Kernel & Vendor Menggunakan Milik Mi 5X
echo "--> Mengganti Kernel (boot.img) dengan milik Mi 5X..."
cp "$WORK_DIR/base/boot.img" "$WORK_DIR/output/boot.img"

if [ -d "$WORK_DIR/base/vendor" ]; then
    echo "--> Mengganti Vendor dengan Vendor Asli Mi 5X..."
    rm -rf "$WORK_DIR/output/vendor"
    cp -r "$WORK_DIR/base/vendor" "$WORK_DIR/output/vendor"
fi

# 5. Sesuaikan Identitas Perangkat ke Mi 5X (tiffany)
echo "--> Memperbaiki Identitas Perangkat di build.prop..."
BUILD_PROP=$(find "$WORK_DIR/output" -name "build.prop" | head -n 1)

if [ -f "$BUILD_PROP" ]; then
    sed -i 's/ro.product.device=.*/ro.product.device=tiffany/g' "$BUILD_PROP"
    sed -i 's/ro.product.model=.*/ro.product.model=Mi 5X/g' "$BUILD_PROP"
    sed -i 's/ro.product.brand=.*/ro.product.brand=Xiaomi/g' "$BUILD_PROP"
    sed -i 's/ro.product.name=.*/ro.product.name=tiffany/g' "$BUILD_PROP"
    sed -i 's/ro.build.product=.*/ro.build.product=tiffany/g' "$BUILD_PROP"
fi

# 6. Hapus Pengecekan Perangkat pada Updater Script TWRP
UPDATER_SCRIPT="$WORK_DIR/output/META-INF/com/google/android/updater-script"
if [ -f "$UPDATER_SCRIPT" ]; then
    echo "--> Menyesuaikan updater-script TWRP..."
    sed -i 's/assert(.*);//g' "$UPDATER_SCRIPT"
    
    # Pesan Credit Yagadama yang Muncul Saat Flashing di TWRP
    echo 'ui_print("=========================================");' >> "$UPDATER_SCRIPT"
    echo 'ui_print(" Ported with Tiffany Universal Tool     ");' >> "$UPDATER_SCRIPT"
    echo 'ui_print(" Developer: Yagadama                     ");' >> "$UPDATER_SCRIPT"
    echo 'ui_print(" Device: Xiaomi Mi 5X (tiffany)          ");' >> "$UPDATER_SCRIPT"
    echo 'ui_print("=========================================");' >> "$UPDATER_SCRIPT"
fi

# 7. Bungkus Kembali Menjadi File ZIP Siap Flash
echo "--> Membungkus Ulang ROM ke Format .zip..."
TIMESTAMP=$(date +%Y%m%d_%H%M)
OUTPUT_NAME="Tiffany_Port_Yagadama_${TIMESTAMP}.zip"

cd "$WORK_DIR/output"
zip -r9 "$OUT_DIR/$OUTPUT_NAME" ./* > /dev/null

echo "================================================="
echo " PORT SELESAI! File: $OUTPUT_NAME                "
echo "================================================="
