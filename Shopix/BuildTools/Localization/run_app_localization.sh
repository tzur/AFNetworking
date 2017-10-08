#!/bin/bash

# Creates updated localization files for iOS project.

PROJECT_DIR=$1
TARGET_NAME=$2
OUT_DIR=$3

if [[ $# -ne 3 ]]; then
  echo "Usage: run_app_localization.sh [project_dir] [target_name] [out_dir]"
  exit 1;
fi

mkdir -p "$OUT_DIR"/Base.lproj
find "$PROJECT_DIR/$TARGET_NAME" -name \*.m -or -name \*.mm -print0 | \
  xargs -0 genstrings -s _LDefault -o "$OUT_DIR/Base.lproj"
iconv -f UTF-16 -t UTF-8 "$OUT_DIR/Base.lproj/Localizable.strings" > \
  "$OUT_DIR/Base.lproj/Localizable.strings.new"
mv "$OUT_DIR/Base.lproj/Localizable.strings.new" "$OUT_DIR/Base.lproj/Localizable.strings"

python "$PROJECT_DIR/../BuildTools/Localization/generate_app_localization.py" \
  "$PROJECT_DIR" "$OUT_DIR" "$OUT_DIR"
